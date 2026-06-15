import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { RequestAmbulanceDto } from './dto/request-ambulance.dto';
import { RequestAmbulanceResponseDto } from './dto/request-ambulance-response.dto';
import { CancelAmbulanceDto } from './dto/cancel-ambulance.dto';
import { AmbulanceRequest, RequestStatus } from './entities/ambulance-request.entity';
import { TrackingPosition } from './entities/tracking-position.entity';
import { TrackingSnapshotDto } from './dto/tracking-snapshot.dto';
import { QUEUE_PROVIDERS } from '../../infrastructure/queues/queue.constants';
import { CreateBookingRequest } from '../vendor/ambulance-vendor.interface';
import { VendorManager } from '../vendor/vendor-manager.service';

@Injectable()
export class AmbulanceService {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly requestRepo: Repository<AmbulanceRequest>,
    @InjectRepository(TrackingPosition)
    private readonly positionRepo: Repository<TrackingPosition>,
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE)
    private readonly bookingQueue: Queue,
    private readonly vendorManager: VendorManager,
  ) {}

  async createRequest(dto: RequestAmbulanceDto): Promise<RequestAmbulanceResponseDto> {
    const requestId = uuidv4();
    const requestNumber = `AR-${Date.now()}`;
    const request = this.requestRepo.create({
      id: requestId,
      requestNumber,
      status: RequestStatus.PENDING,
      pickupLat: dto.pickup.lat,
      pickupLng: dto.pickup.lng,
      dropLat: dto.drop.lat,
      dropLng: dto.drop.lng,
      patientName: dto.patient.name,
      patientPhone: dto.patient.phoneE164,
      priority: dto.priority || 'normal',
      notes: dto.notes,
      idempotencyKey: dto.idempotencyKey,
    });

    await this.requestRepo.save(request);

    const bookingPayload: CreateBookingRequest = {
      requestId: request.id,
      idempotencyKey: dto.idempotencyKey,
      pickup: dto.pickup,
      drop: dto.drop,
      priority: dto.priority,
      patient: {
        name: dto.patient.name,
        phoneE164: dto.patient.phoneE164,
      },
      notes: dto.notes,
    };

    await this.bookingQueue.add('create-booking', bookingPayload, {
      jobId: request.id,
      attempts: 5,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
      removeOnComplete: true,
      removeOnFail: false,
    });

    const response: RequestAmbulanceResponseDto = {
      requestId: request.id,
      requestNumber: request.requestNumber,
      status: request.status,
      createdAt: request.createdAt,
      assignedVendor: null,
      message: 'Request stored and queued for vendor booking',
    };

    return response;
  }

  async cancelRequest(requestId: string, dto: CancelAmbulanceDto) {
    const request = await this.requestRepo.findOne({ where: { id: requestId } });
    if (!request) return null;
    request.status = RequestStatus.CANCELLED;
    request.cancelReason = dto.reasonCode;
    request.updatedAt = new Date();
    await this.requestRepo.save(request);

    if (request.assignedVendorId && request.vendorBookingRef) {
      try {
        await this.vendorManager.cancelVendorBooking(request.assignedVendorId, request.vendorBookingRef);
      } catch (err) {
        // Log but do not fail
      }
    }

    return {
      requestId: request.id,
      cancelledAt: request.updatedAt,
      status: request.status,
      message: 'Cancelled',
    };
  }

  async getTrackingSnapshot(requestId: string): Promise<TrackingSnapshotDto | null> {
    const request = await this.requestRepo.findOne({ where: { id: requestId } });
    if (!request) return null;

    const lastPosition = await this.positionRepo.findOne({
      where: { request: { id: requestId } },
      order: { capturedAt: 'DESC' },
    });

    const snapshot: TrackingSnapshotDto = {
      requestId: request.id,
      requestNumber: request.requestNumber,
      status: request.status,
      patientName: request.patientName,
      pickupLat: request.pickupLat,
      pickupLng: request.pickupLng,
      dropLat: request.dropLat,
      dropLng: request.dropLng,
      driver: request.assignedDriver ? {
        vendorDriverRef: request.assignedDriver.vendorDriverRef,
        name: request.assignedDriver.name,
        phoneE164: request.assignedDriver.phoneE164,
        vehicleNumber: request.assignedDriver.vehicleNumber,
        ambulanceType: request.assignedDriver.ambulanceType,
      } : null,
      etaSeconds: request.etaSeconds ?? null,
      lastLocation: lastPosition ? {
        vendorEventId: lastPosition.vendorEventId,
        lat: lastPosition.lat,
        lng: lastPosition.lng,
        speedKmph: lastPosition.speedKmph,
        headingDeg: lastPosition.headingDeg,
        capturedAt: lastPosition.capturedAt,
      } : null,
      updatedAt: request.updatedAt,
    };

    return snapshot;
  }
}
