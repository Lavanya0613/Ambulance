import { Provider, Logger } from '@nestjs/common';
import { Queue, Worker, Job } from 'bullmq';
import { QUEUE_NAMES, QUEUE_PROVIDERS } from './queue.constants';
import { VendorManager } from '../../modules/vendor/vendor-manager.service';
import { AmbulanceRepository } from '../../modules/ambulance/repositories/ambulance.repository';
import { TrackingRepository } from '../../modules/ambulance/repositories/tracking.repository';

import { WebsocketGateway } from '../../gateway/websocket.gateway';
import { RequestStatus } from '../../modules/ambulance/entities/ambulance-request.entity';
import { haversineDistanceKm } from '../../common/utils/geo.util';
import { EtaService } from '../../modules/ambulance/eta.service';
import { AuditService } from '../../modules/audit/audit.service';
import { DlqService } from './dlq.service';

const logger = new Logger('QueueProviders');

const redisConnection = () => {
  const url = process.env.REDIS_URL;
  if (url) return { connection: { url } };
  return { connection: { host: process.env.REDIS_HOST || '127.0.0.1', port: +(process.env.REDIS_PORT || 6379) } };
};


export const queueProviders: Provider[] = [
  // Queue and scheduler providers
  {
    provide: QUEUE_PROVIDERS.BOOKING_QUEUE,
    useFactory: async () => {
      return new Queue(QUEUE_NAMES.BOOKING, redisConnection() as any);
    },
  },
  {
    provide: QUEUE_PROVIDERS.TRACKING_QUEUE,
    useFactory: async () => {
      return new Queue(QUEUE_NAMES.TRACKING, redisConnection() as any);
    },
  },

  {
    provide: QUEUE_PROVIDERS.DLQ_QUEUE,
    useFactory: async () => {
      return new Queue(QUEUE_NAMES.DLQ, redisConnection() as any);
    },
  },

  // Booking Worker
  {
    provide: QUEUE_PROVIDERS.BOOKING_WORKER,
    useFactory: (vendorManager: VendorManager, ambulanceRepo: AmbulanceRepository, websocketGateway: WebsocketGateway, trackingQueue: Queue, dlqService: DlqService) => {
      const opts = redisConnection() as any;
      const worker = new Worker(
        QUEUE_NAMES.BOOKING,
        async (job: Job) => {
          try {
            const payload = job.data as any;
            const booking = await ambulanceRepo.findById(payload.requestId);
            if (!booking) throw new Error(`Request not found: ${payload.requestId}`);

            const preferred = payload.preferredVendorId;
            const adapter = await vendorManager.dispatchToVendor(payload, preferred);
            const vendorId = preferred && vendorManager.getAdapter(preferred) ? preferred : vendorManager.listAdapters()[0];

            await ambulanceRepo.assignVendor(payload.requestId, vendorId, adapter.vendorBookingRef, adapter.driver, adapter.etaSeconds ?? undefined);
            await ambulanceRepo.updateStatus(payload.requestId, adapter.status as RequestStatus);

            websocketGateway.emitAmbulanceAssigned(payload.requestId, {
              requestId: payload.requestId,
              vendorId,
              vendorBookingRef: adapter.vendorBookingRef,
              driver: adapter.driver,
              etaSeconds: adapter.etaSeconds ?? null,
            });
            if (adapter.etaSeconds != null) {
              websocketGateway.emitEtaUpdated(payload.requestId, adapter.etaSeconds);
            }

            await trackingQueue.add(
              'poll-tracking',
              {
                requestId: payload.requestId,
                vendorId,
                vendorBookingRef: adapter.vendorBookingRef,
              },
              {
                delay: 1000,
                attempts: 3,
                backoff: { type: 'exponential', delay: 500 },
                removeOnComplete: true,
                removeOnFail: false,
              },
            );
            return adapter;
          } catch (err: any) {
            logger.error(`Booking worker failed for job ${job.id}: ${err.message}`, err.stack);
            throw err; // Let BullMQ retry handle it
          }
        },
        opts,
      );

      worker.on('failed', async (job, err) => {
        if (!job) return;
        const attempts = job.opts.attempts || 0;
        if (job.attemptsMade >= attempts) {
          logger.warn(`Job ${job.id} exhausted retries, moving to DLQ`);
          await dlqService.storeFailedJob(QUEUE_NAMES.BOOKING, job.id!, job.data, err.message, job.attemptsMade);
        }
      });

      worker.on('active', (job) => {
        logger.log(`[Queue] Booking job ${job.id} started`);
      });

      worker.on('completed', (job) => {
        const duration = job.finishedOn && job.processedOn ? job.finishedOn - job.processedOn : 0;
        logger.log(`[Queue] Booking job ${job.id} completed in ${duration}ms`);
      });

      return worker;
    },
    inject: [VendorManager, AmbulanceRepository, WebsocketGateway, QUEUE_PROVIDERS.TRACKING_QUEUE, DlqService],
  },

  // Tracking Worker
  {
    provide: QUEUE_PROVIDERS.TRACKING_WORKER,
    useFactory: (vendorManager: VendorManager, trackingRepo: TrackingRepository, ambulanceRepo: AmbulanceRepository, websocketGateway: WebsocketGateway, etaService: EtaService, auditService: AuditService, trackingQueue: Queue, dlqService: DlqService) => {
      const opts = redisConnection() as any;
      const worker = new Worker(
        QUEUE_NAMES.TRACKING,
        async (job: Job) => {
          try {
            const payload = job.data as any;
            
            // Poll vendor adapter for latest GPS points since last poll
            const positions = await vendorManager.pollPositions(payload.vendorId, payload.vendorBookingRef, payload.since ? new Date(payload.since) : undefined);
            
            let latestPos = null;
            for (const position of positions) {
              await trackingRepo.addPosition({
                vendorEventId: position.vendorEventId,
                lat: position.lat,
                lng: position.lng,
                speedKmph: position.speedKmph,
                headingDeg: position.headingDeg,
                capturedAt: position.capturedAt,
                request: { id: payload.requestId } as any,
              });
              websocketGateway.emitLocationUpdated(payload.requestId, position);
              latestPos = position;
            }

            if (positions.length > 0) {
              await auditService.logAction(
                'Tracking Updated',
                'system',
                payload.requestId,
                'AmbulanceRequest',
                undefined,
                `Received ${positions.length} new positions`
              );
            }

            const booking = await vendorManager.getVendorBooking(payload.vendorId, payload.vendorBookingRef);
            const oldRequest = await ambulanceRepo.findById(payload.requestId);
            
            let currentStatus = oldRequest?.status;

            // Intercept vendor status updates
            if (booking?.status && oldRequest && oldRequest.status !== booking.status) {
              await ambulanceRepo.updateStatus(payload.requestId, booking.status as RequestStatus);
              websocketGateway.emitStatusUpdated(payload.requestId, booking.status);
              currentStatus = booking.status as RequestStatus;
            }

            // Dynamic ETA Calculation Math
            if (latestPos && oldRequest && currentStatus) {
              let targetLat, targetLng;
              if (currentStatus === RequestStatus.VENDOR_ACCEPTED || currentStatus === RequestStatus.DRIVER_ASSIGNED || currentStatus === RequestStatus.EN_ROUTE || currentStatus === RequestStatus.SEARCHING_DRIVER) {
                targetLat = oldRequest.pickupLat;
                targetLng = oldRequest.pickupLng;
              } else if (currentStatus === RequestStatus.PATIENT_ONBOARD || currentStatus === RequestStatus.ARRIVED) {
                targetLat = oldRequest.dropLat;
                targetLng = oldRequest.dropLng;
              }

              if (targetLat != null && targetLng != null) {
                const { etaSeconds, hasArrived } = etaService.calculateEta(latestPos.lat, latestPos.lng, targetLat, targetLng, latestPos.speedKmph);
                
                if (hasArrived) {
                  let newStatus = currentStatus;
                  if (currentStatus === RequestStatus.VENDOR_ACCEPTED || currentStatus === RequestStatus.DRIVER_ASSIGNED || currentStatus === RequestStatus.EN_ROUTE || currentStatus === RequestStatus.SEARCHING_DRIVER) {
                    newStatus = RequestStatus.ARRIVED;
                  } else if (currentStatus === RequestStatus.PATIENT_ONBOARD || currentStatus === RequestStatus.ARRIVED) {
                    newStatus = RequestStatus.DESTINATION_REACHED;
                  }
                  
                  if (newStatus !== currentStatus) {
                    await ambulanceRepo.updateStatus(payload.requestId, newStatus);
                    
                    if (newStatus === RequestStatus.ARRIVED || newStatus === RequestStatus.DESTINATION_REACHED) {
                      await auditService.logAction(
                        newStatus === RequestStatus.ARRIVED ? 'Trip Started' : 'Trip Reached Destination',
                        'system',
                        payload.requestId,
                        'AmbulanceRequest',
                        currentStatus,
                        newStatus
                      );
                    }

                    websocketGateway.emitStatusUpdated(payload.requestId, newStatus);
                    currentStatus = newStatus;
                  }
                }
                
                await ambulanceRepo.updateEta(payload.requestId, etaSeconds);
                websocketGateway.emitEtaUpdated(payload.requestId, etaSeconds);
              }
            } else if (booking?.etaSeconds != null && !latestPos) {
              await ambulanceRepo.updateEta(payload.requestId, booking.etaSeconds);
              websocketGateway.emitEtaUpdated(payload.requestId, booking.etaSeconds);
            }

            const isTerminal = ['COMPLETED', 'CANCELLED', 'FAILED'].includes(booking?.status);
            if (isTerminal) {
              if (booking?.status === 'COMPLETED') {
                await auditService.logAction(
                  'Trip Completed',
                  'system',
                  payload.requestId,
                  'AmbulanceRequest'
                );
                websocketGateway.emitRideCompleted(payload.requestId, {
                  requestId: payload.requestId,
                  vendorBookingRef: payload.vendorBookingRef,
                  status: booking.status,
                });
              }
              return { completed: true, received: positions.length };
            }

            // Recursive polling loop - re-add job to queue
            const nextSince = positions.length > 0
              ? positions.at(-1)?.capturedAt?.toISOString()
              : payload.since;

            await trackingQueue.add(
              'poll-tracking',
              {
                requestId: payload.requestId,
                vendorId: payload.vendorId,
                vendorBookingRef: payload.vendorBookingRef,
                since: nextSince,
              },
              {
                delay: 1500,
                attempts: 3,
                backoff: { type: 'exponential', delay: 500 },
                removeOnComplete: true,
                removeOnFail: false,
              },
            );

            return { completed: false, received: positions.length };
          } catch (err: any) {
            logger.error(`Tracking worker failed for job ${job.id}: ${err.message}`, err.stack);
            throw err;
          }
        },
        opts,
      );

      worker.on('failed', async (job, err) => {
        if (!job) return;
        const attempts = job.opts.attempts || 0;
        if (job.attemptsMade >= attempts) {
          logger.warn(`Tracking job ${job.id} exhausted retries, moving to DLQ`);
          await dlqService.storeFailedJob(QUEUE_NAMES.TRACKING, job.id!, job.data, err.message, job.attemptsMade);
        }
      });

      worker.on('active', (job) => {
        logger.log(`[Queue] Tracking job ${job.id} started`);
      });

      worker.on('completed', (job) => {
        const duration = job.finishedOn && job.processedOn ? job.finishedOn - job.processedOn : 0;
        logger.log(`[Queue] Tracking job ${job.id} completed in ${duration}ms`);
      });

      return worker;
    },
    inject: [VendorManager, TrackingRepository, AmbulanceRepository, WebsocketGateway, EtaService, AuditService, QUEUE_PROVIDERS.TRACKING_QUEUE, DlqService],
  },
];
