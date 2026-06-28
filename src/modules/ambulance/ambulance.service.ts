import { Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { Repository, DataSource, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { RequestAmbulanceDto } from './dto/request-ambulance.dto';
import { RequestAmbulanceResponseDto } from './dto/request-ambulance-response.dto';
import { CancelAmbulanceDto } from './dto/cancel-ambulance.dto';
import { AmbulanceRequest, RequestStatus } from './entities/ambulance-request.entity';
import { TrackingPosition } from './entities/tracking-position.entity';

import { AssignDriverDto } from './dto/assign-driver.dto';
import { TrackingSnapshotDto } from './dto/tracking-snapshot.dto';
import { ListRequestsDto } from './dto/list-requests.dto';
import { QUEUE_PROVIDERS } from '../../infrastructure/queues/queue.constants';
import { CreateBookingRequest } from '../vendor/ambulance-vendor.interface';
import { VendorManager } from '../vendor/vendor-manager.service';
import { AuditService } from '../audit/audit.service';
import { GeocodingService } from './geocoding.service';
import { WebsocketGateway } from '../../gateway/websocket.gateway';

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
    private readonly auditService: AuditService,
    private readonly dataSource: DataSource,
    private readonly geocodingService: GeocodingService,
    private readonly websocketGateway: WebsocketGateway,
  ) {}

  async createRequest(dto: RequestAmbulanceDto, patientId: string): Promise<RequestAmbulanceResponseDto> {
    if (dto.idempotencyKey) {
      const existing = await this.requestRepo.findOne({ where: { idempotencyKey: dto.idempotencyKey, patientId } });
      if (existing) {
        return {
          requestId: existing.id,
          requestNumber: existing.requestNumber,
          status: existing.status,
          createdAt: existing.createdAt,
          assignedVendor: existing.assignedVendorId || null,
          message: 'Returned existing request based on idempotency key',
        };
      }
    }

    const requestId = uuidv4();
    const requestNumber = `AR-${Date.now()}`;
    let pickupAddress = dto.pickup.address;
    if (!pickupAddress || pickupAddress.trim() === '' || pickupAddress.toLowerCase() === 'current location' || pickupAddress.toLowerCase() === 'locate me') {
      pickupAddress = await this.geocodingService.reverseGeocode(dto.pickup.lat, dto.pickup.lng) || pickupAddress;
    }

    let dropAddress = dto.drop.address;
    if (!dropAddress || dropAddress.trim() === '' || dropAddress.toLowerCase() === 'current location' || dropAddress.toLowerCase() === 'locate me') {
      dropAddress = await this.geocodingService.reverseGeocode(dto.drop.lat, dto.drop.lng) || dropAddress;
    }

    const request = this.requestRepo.create({
      id: requestId,
      requestNumber,
      status: RequestStatus.REQUEST_CREATED,
      pickupAddress,
      pickupLat: dto.pickup.lat,
      pickupLng: dto.pickup.lng,
      dropAddress,
      dropLat: dto.drop.lat,
      dropLng: dto.drop.lng,
      patientName: dto.patient.name,
      patientPhone: dto.patient.phoneE164,
      priority: dto.priority || 'normal',
      notes: dto.notes,
      idempotencyKey: dto.idempotencyKey,
      patientId,
    });

    await this.requestRepo.save(request);
    await this.auditService.logAction(
      'Booking Created',
      patientId,
      request.id,
      'AmbulanceRequest',
      undefined,
      request.status
    );

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

    // Broadcast new request to dispatchers natively
    this.websocketGateway.emitNewRequest(request);

    return response;
  }

  async listRequests(patientId: string, role: string, queryDto: ListRequestsDto = {}) {
    const { page = 1, limit = 10, sortBy = 'createdAt', sortOrder = 'DESC', status, fromDate, toDate } = queryDto;
    
    const where: any = {};
    if (role === 'patient') {
      where.patientId = patientId;
    }
    if (status) {
      where.status = status;
    }
    if (fromDate && toDate) {
      where.createdAt = Between(new Date(fromDate), new Date(toDate));
    } else if (fromDate) {
      where.createdAt = MoreThanOrEqual(new Date(fromDate));
    } else if (toDate) {
      where.createdAt = LessThanOrEqual(new Date(toDate));
    }

    const skip = (page - 1) * limit;

    const [requests, total] = await this.requestRepo.findAndCount({
      where,
      order: { [sortBy]: sortOrder },
      skip,
      take: limit,
    });

    const data = requests.map((r) => ({
      requestId: r.id,
      requestNumber: r.requestNumber,
      status: r.status,
      priority: r.priority || 'normal',
      patientName: r.patientName,
      patientPhone: r.patientPhone,
      pickupAddress: r.pickupAddress,
      pickupLat: r.pickupLat,
      pickupLng: r.pickupLng,
      dropAddress: r.dropAddress,
      dropLat: r.dropLat,
      dropLng: r.dropLng,
      assignedVendorId: r.assignedVendorId || null,
      driver: r.vendorDriverRef ? {
        vendorDriverRef: r.vendorDriverRef,
        name: r.vendorDriverName,
        phoneE164: r.vendorDriverPhone,
        vehicleNumber: r.vendorVehicleNumber,
        ambulanceType: r.vendorAmbulanceType,
      } : null,
      etaSeconds: r.etaSeconds || null,
      cancelReason: r.cancelReason || null,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    }));

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      }
    };
  }

  async cancelRequest(requestId: string, dto: CancelAmbulanceDto, patientId: string, role: string) {
    const where: any = { id: requestId };
    if (role === 'patient') {
      where.patientId = patientId;
    }
    const request = await this.requestRepo.findOne({ where });
    if (!request) return null;
    const prevStatus = request.status;
    request.status = RequestStatus.CANCELLED;
    request.cancelReason = dto.reasonCode;
    request.updatedAt = new Date();
    await this.requestRepo.save(request);
    await this.auditService.logAction(
      'Trip Cancelled',
      patientId || role,
      request.id,
      'AmbulanceRequest',
      prevStatus,
      request.status
    );

    if (request.assignedVendorId && request.vendorBookingRef) {
      try {
        await this.vendorManager.cancelVendorBooking(request.assignedVendorId, request.vendorBookingRef);
      } catch (err) {
        // Log but do not fail
      }
    }

    // Broadcast cancellation to dispatchers and patient room
    this.websocketGateway.emitStatusUpdated(request.id, request.status);

    return {
      requestId: request.id,
      cancelledAt: request.updatedAt,
      status: request.status,
      message: 'Cancelled',
    };
  }

  async getTrackingSnapshot(requestId: string, patientId: string, role: string): Promise<TrackingSnapshotDto | null> {
    const where: any = { id: requestId };
    if (role === 'patient') {
      // Temporarily bypassed auth check
      // where.patientId = patientId;
    }
    const request = await this.requestRepo.findOne({ where });
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
      pickupAddress: request.pickupAddress || '',
      pickupLat: request.pickupLat,
      pickupLng: request.pickupLng,
      dropAddress: request.dropAddress || '',
      dropLat: request.dropLat,
      dropLng: request.dropLng,
      driver: request.vendorDriverRef ? {
        vendorDriverRef: request.vendorDriverRef,
        name: request.vendorDriverName,
        phoneE164: request.vendorDriverPhone,
        vehicleNumber: request.vendorVehicleNumber,
        ambulanceType: request.vendorAmbulanceType,
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

  async getAuditHistory(requestId: string, patientId: string, role: string) {
    // Audit logic moved to AuditModule, this endpoint might need updates if required
    return [];
  }


}
