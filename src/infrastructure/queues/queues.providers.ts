import { Provider } from '@nestjs/common';
import { Queue, Worker, Job } from 'bullmq';
import { QUEUE_NAMES, QUEUE_PROVIDERS } from './queue.constants';
import { VendorManager } from '../../modules/vendor/vendor-manager.service';
import { AmbulanceRepository } from '../../modules/ambulance/repositories/ambulance.repository';
import { TrackingRepository } from '../../modules/ambulance/repositories/tracking.repository';
import { WebsocketGateway } from '../../gateway/websocket.gateway';
import { RequestStatus } from '../../modules/ambulance/entities/ambulance-request.entity';

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
    provide: QUEUE_PROVIDERS.RETRY_QUEUE,
    useFactory: async () => {
      return new Queue(QUEUE_NAMES.RETRY, redisConnection() as any);
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
    useFactory: (vendorManager: VendorManager, ambulanceRepo: AmbulanceRepository, websocketGateway: WebsocketGateway) => {
      const opts = redisConnection() as any;
      const worker = new Worker(
        QUEUE_NAMES.BOOKING,
        async (job: Job) => {
          const payload = job.data as any;
          const booking = await ambulanceRepo.findById(payload.requestId);
          if (!booking) throw new Error(`Request not found: ${payload.requestId}`);

          const preferred = payload.preferredVendorId;
          const adapter = await vendorManager.dispatchToVendor(payload, preferred);
          const vendorId = preferred && vendorManager.getAdapter(preferred) ? preferred : vendorManager.listAdapters()[0];

          await ambulanceRepo.assignVendor(payload.requestId, vendorId, adapter.vendorBookingRef, adapter.driver, adapter.etaSeconds ?? undefined);
          await ambulanceRepo.updateStatus(payload.requestId, RequestStatus.ASSIGNED);

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

          await addTrackingJob(payload.requestId, vendorId, adapter.vendorBookingRef, 1000);

          return adapter;
        },
        opts,
      );

      // Move jobs to DLQ after attempts exhausted
      worker.on('failed', async (job, err) => {
        const attempts = job.opts.attempts || 0;
        if (job.attemptsMade >= attempts) {
          // move to dead-letter queue
          const dlq = new Queue(QUEUE_NAMES.DLQ, redisConnection() as any);
          await dlq.add('dlq', job.data, { removeOnComplete: true });
        }
      });

      return worker;
    },
    inject: [VendorManager, AmbulanceRepository, WebsocketGateway],
  },

  // Tracking Worker
  {
    provide: QUEUE_PROVIDERS.TRACKING_WORKER,
    useFactory: (vendorManager: VendorManager, trackingRepo: TrackingRepository, ambulanceRepo: AmbulanceRepository, websocketGateway: WebsocketGateway) => {
      const opts = redisConnection() as any;
      const worker = new Worker(
        QUEUE_NAMES.TRACKING,
        async (job: Job) => {
          const payload = job.data as any;
          const positions = await vendorManager.pollPositions(payload.vendorId, payload.vendorBookingRef, payload.since ? new Date(payload.since) : undefined);
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
          }

          const booking = await vendorManager.getVendorBooking(payload.vendorId, payload.vendorBookingRef);
          if (booking?.status) {
            const oldRequest = await ambulanceRepo.findById(payload.requestId);
            if (oldRequest && oldRequest.status !== booking.status) {
              await ambulanceRepo.updateStatus(payload.requestId, booking.status as RequestStatus);
              websocketGateway.emitStatusUpdated(payload.requestId, booking.status);
            }
          }

          if (booking?.etaSeconds != null) {
            await ambulanceRepo.updateEta(payload.requestId, booking.etaSeconds);
            websocketGateway.emitEtaUpdated(payload.requestId, booking.etaSeconds);
          }

          const isTerminal = ['COMPLETED', 'CANCELLED', 'FAILED'].includes(booking?.status);
          if (isTerminal) {
            if (booking?.status === 'COMPLETED') {
              websocketGateway.emitRideCompleted(payload.requestId, {
                requestId: payload.requestId,
                vendorBookingRef: payload.vendorBookingRef,
                status: booking.status,
              });
            }
            return { completed: true, received: positions.length };
          }

          const nextSince = positions.length > 0
            ? positions.at(-1)?.capturedAt?.toISOString()
            : payload.since;

          await addTrackingJob(payload.requestId, payload.vendorId, payload.vendorBookingRef, 1500, nextSince);

          return { completed: false, received: positions.length };
        },
        opts,
      );

      return worker;
    },
    inject: [VendorManager, TrackingRepository, AmbulanceRepository, WebsocketGateway],
  },

  // Retry Worker - handles re-dispatching transient failures
  {
    provide: QUEUE_PROVIDERS.RETRY_WORKER,
    useFactory: (vendorManager: VendorManager, ambulanceRepo: AmbulanceRepository) => {
      const opts = redisConnection() as any;
      const worker = new Worker(
        QUEUE_NAMES.RETRY,
        async (job: Job) => {
          const payload = job.data as any; // { requestId, attemptMeta }
          const adapters = vendorManager.listAdapters();
          const adapterId = payload.preferredVendorId && vendorManager.getAdapter(payload.preferredVendorId) ? payload.preferredVendorId : adapters.length ? adapters[0] : null;
          if (!adapterId) throw new Error('No vendor adapter available');
          const adapter = vendorManager.getAdapter(adapterId);
          const res = await adapter.createBooking(payload);
          await ambulanceRepo.assignVendor(payload.requestId, adapter.id, res.vendorBookingRef, res.driver, res.etaSeconds);
          return res;
        },
        opts,
      );

      worker.on('failed', async (job, err) => {
        const attempts = job.opts.attempts || 0;
        if (job.attemptsMade >= attempts) {
          const dlq = new Queue(QUEUE_NAMES.DLQ, redisConnection() as any);
          await dlq.add('dlq', job.data, { removeOnComplete: true });
        }
      });

      return worker;
    },
    inject: [VendorManager, AmbulanceRepository],
  },
];

async function addTrackingJob(
  requestId: string,
  vendorId: string,
  vendorBookingRef: string,
  delayMs: number,
  since?: string,
) {
  const queue = new Queue(QUEUE_NAMES.TRACKING, redisConnection() as any);
  await queue.add(
    'poll-tracking',
    {
      requestId,
      vendorId,
      vendorBookingRef,
      since,
    },
    {
      delay: delayMs,
      attempts: 3,
      backoff: { type: 'exponential', delay: 500 },
      removeOnComplete: true,
      removeOnFail: false,
    },
  );
}
