import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Brackets } from 'typeorm';
import { AmbulanceRequest, RequestStatus } from '../ambulance/entities/ambulance-request.entity';
import { TrackingPosition } from '../ambulance/entities/tracking-position.entity';
import { SystemAuditLog } from '../audit/entities/system-audit-log.entity';
import { Inject } from '@nestjs/common';
import { Queue } from 'bullmq';
import { QUEUE_PROVIDERS } from '../../infrastructure/queues/queue.constants';
import { DlqService } from '../../infrastructure/queues/dlq.service';
import { WebsocketGateway } from '../../gateway/websocket.gateway';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly requestRepo: Repository<AmbulanceRequest>,
    @InjectRepository(SystemAuditLog)
    private readonly auditRepo: Repository<SystemAuditLog>,
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE) private readonly bookingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.TRACKING_QUEUE) private readonly trackingQueue: Queue,
    private readonly dlqService: DlqService,
    private readonly wsGateway: WebsocketGateway,
  ) {}

  async getDashboard() {
    const metrics = await this.requestRepo.createQueryBuilder('req')
      .select('COUNT(req.id)', 'totalRequests')
      .addSelect(`SUM(CASE WHEN req.status IN (:...pendingStatuses) THEN 1 ELSE 0 END)`, 'pendingRequests')
      .addSelect(`SUM(CASE WHEN req.status IN (:...assignedStatuses) THEN 1 ELSE 0 END)`, 'assignedRequests')
      .addSelect(`SUM(CASE WHEN req.status IN (:...inProgressStatuses) THEN 1 ELSE 0 END)`, 'inProgressRequests')
      .addSelect(`SUM(CASE WHEN req.status IN (:...completedStatuses) THEN 1 ELSE 0 END)`, 'completedRequests')
      .addSelect(`SUM(CASE WHEN req.status IN (:...cancelledStatuses) THEN 1 ELSE 0 END)`, 'cancelledRequests')
      .setParameters({
        pendingStatuses: [RequestStatus.REQUEST_CREATED, RequestStatus.SEARCHING_DRIVER],
        assignedStatuses: [RequestStatus.VENDOR_ACCEPTED, RequestStatus.DRIVER_ASSIGNED],
        inProgressStatuses: [RequestStatus.EN_ROUTE, RequestStatus.ARRIVED, RequestStatus.PATIENT_ONBOARD],
        completedStatuses: [RequestStatus.DESTINATION_REACHED, RequestStatus.COMPLETED],
        cancelledStatuses: [RequestStatus.CANCELLED, RequestStatus.FAILED],
      })
      .getRawOne();

    return {
      totalRequests: parseInt(metrics?.totalRequests || '0', 10),
      pendingRequests: parseInt(metrics?.pendingRequests || '0', 10),
      assignedRequests: parseInt(metrics?.assignedRequests || '0', 10),
      inProgressRequests: parseInt(metrics?.inProgressRequests || '0', 10),
      completedRequests: parseInt(metrics?.completedRequests || '0', 10),
      cancelledRequests: parseInt(metrics?.cancelledRequests || '0', 10),
    };
  }

  async getRequests(query: any) {
    const { page = 1, limit = 10, status, date, search } = query;
    const skip = (page - 1) * limit;

    const qb = this.requestRepo.createQueryBuilder('req')
      .orderBy('req.createdAt', 'DESC')
      .skip(skip)
      .take(limit);

    if (status) {
      qb.andWhere('req.status = :status', { status });
    }

    if (date) {
      const targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);
      const nextDate = new Date(targetDate);
      nextDate.setDate(nextDate.getDate() + 1);
      
      qb.andWhere('req.createdAt >= :startDate AND req.createdAt < :endDate', {
        startDate: targetDate,
        endDate: nextDate,
      });
    }

    if (search) {
      qb.andWhere(new Brackets(qb => {
        qb.where('req.patientName ILIKE :search', { search: `%${search}%` })
          .orWhere('req.requestNumber ILIKE :search', { search: `%${search}%` });
      }));
    }

    const [items, total] = await qb.getManyAndCount();

    return {
      data: items,
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      }
    };
  }

  async getRequestDetails(id: string) {
    const request = await this.requestRepo.findOne({
      where: { id },
      relations: ['positions'],
      order: {
        positions: {
          capturedAt: 'ASC',
        }
      }
    });

    if (!request) {
      throw new NotFoundException(`Request with ID ${id} not found`);
    }

    return {
      id: request.id,
      requestNumber: request.requestNumber,
      status: request.status,
      patient: {
        id: request.patientId,
        name: request.patientName,
        phone: request.patientPhone,
        notes: request.notes,
        priority: request.priority,
      },
      pickup: {
        address: request.pickupAddress,
        lat: request.pickupLat,
        lng: request.pickupLng,
      },
      destination: {
        address: request.dropAddress,
        lat: request.dropLat,
        lng: request.dropLng,
      },
      driver: request.vendorDriverRef ? {
        ref: request.vendorDriverRef,
        name: request.vendorDriverName,
        phone: request.vendorDriverPhone,
      } : null,
      vehicle: request.vendorVehicleNumber ? {
        number: request.vendorVehicleNumber,
        type: request.vendorAmbulanceType,
      } : null,
      etaSeconds: request.etaSeconds,
      cancelReason: request.cancelReason,
      vendor: {
        assignedVendorId: request.assignedVendorId,
        vendorBookingRef: request.vendorBookingRef,
      },
      timeline: {
        createdAt: request.createdAt,
        updatedAt: request.updatedAt,
      },
      trackingHistory: request.positions?.map(pos => ({
        lat: pos.lat,
        lng: pos.lng,
        speedKmph: pos.speedKmph,
        headingDeg: pos.headingDeg,
        capturedAt: pos.capturedAt,
      })) || [],
    };
  }

  async getAuditLogs(query: any) {
    const { page = 1, limit = 20, action, request, date } = query;
    const skip = (page - 1) * limit;

    const qb = this.auditRepo.createQueryBuilder('log')
      .orderBy('log.timestamp', 'DESC')
      .skip(skip)
      .take(limit);

    if (action) {
      qb.andWhere('log.action ILIKE :action', { action: `%${action}%` });
    }

    if (request) {
      qb.andWhere('log.entityId = :request', { request });
    }

    if (date) {
      const targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);
      const nextDate = new Date(targetDate);
      nextDate.setDate(nextDate.getDate() + 1);
      
      qb.andWhere('log.timestamp >= :startDate AND log.timestamp < :endDate', {
        startDate: targetDate,
        endDate: nextDate,
      });
    }

    const [items, total] = await qb.getManyAndCount();

    return {
      data: items,
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit),
      }
    };
  }

  async getSystemStatus() {
    let database = 'down';
    try {
      await this.requestRepo.query('SELECT 1');
      database = 'up';
    } catch (e) { }

    let redis = 'down';
    let bookingCounts, trackingCounts, dlqCount = 0;
    let bookingWorkers = [], trackingWorkers = [];

    try {
      [bookingCounts, trackingCounts, dlqCount, bookingWorkers, trackingWorkers] = await Promise.all([
        this.bookingQueue.getJobCounts(),
        this.trackingQueue.getJobCounts(),
        this.dlqService.getDlqCount(),
        this.bookingQueue.getWorkers(),
        this.trackingQueue.getWorkers(),
      ]);
      redis = 'up';
    } catch (e) { 
      bookingCounts = { waiting: 0, active: 0, completed: 0, failed: 0, delayed: 0, paused: 0 };
      trackingCounts = { waiting: 0, active: 0, completed: 0, failed: 0, delayed: 0, paused: 0 };
    }

    const connectedClients = this.wsGateway.getConnectedClientsCount();

    const activeJobs = (bookingCounts.active || 0) + (trackingCounts.active || 0);
    const waitingJobs = (bookingCounts.waiting || 0) + (trackingCounts.waiting || 0);
    const delayedJobs = (bookingCounts.delayed || 0) + (trackingCounts.delayed || 0);
    const failedJobs = (bookingCounts.failed || 0) + (trackingCounts.failed || 0) + dlqCount;

    return {
      backend: 'up',
      database,
      redis,
      websocket: {
        connectedClients,
        status: connectedClients >= 0 ? 'up' : 'down'
      },
      queues: {
        status: redis,
        activeJobs,
        waitingJobs,
        delayedJobs,
        failedJobs,
        retryJobs: (bookingCounts.delayed || 0) + (trackingCounts.delayed || 0) // Treat delayed as retry for simplicity in monitor
      },
      workers: {
        count: bookingWorkers.length + trackingWorkers.length,
        bookingWorkers: bookingWorkers.length,
        trackingWorkers: trackingWorkers.length,
      }
    };
  }

  async getAnalytics() {
    // Requests per Day (Last 7 Days)
    const requestsPerDay = await this.requestRepo.query(`
      SELECT DATE("createdAt") as date, COUNT(*) as count 
      FROM ambulance_requests 
      WHERE "createdAt" >= current_date - interval '7 days'
      GROUP BY DATE("createdAt") 
      ORDER BY DATE("createdAt") ASC
    `);

    // Requests per Status
    const requestsPerStatus = await this.requestRepo.query(`
      SELECT status, COUNT(*) as count 
      FROM ambulance_requests 
      GROUP BY status
    `);

    // Average ETA
    const avgEtaResult = await this.requestRepo.query(`
      SELECT AVG("etaSeconds") as avg_eta 
      FROM ambulance_requests 
      WHERE "etaSeconds" IS NOT NULL
    `);
    const averageEtaSeconds = avgEtaResult[0]?.avg_eta ? Math.round(avgEtaResult[0].avg_eta) : 0;

    // Average Completion Time
    const avgCompletionResult = await this.requestRepo.query(`
      SELECT AVG(EXTRACT(EPOCH FROM ("updatedAt" - "createdAt"))) as avg_completion 
      FROM ambulance_requests 
      WHERE status = 'COMPLETED'
    `);
    const averageCompletionTimeSeconds = avgCompletionResult[0]?.avg_completion ? Math.round(avgCompletionResult[0].avg_completion) : 0;

    // Top Pickup Areas
    const topPickupAreas = await this.requestRepo.query(`
      SELECT "pickupAddress" as area, COUNT(*) as count 
      FROM ambulance_requests 
      WHERE "pickupAddress" IS NOT NULL
      GROUP BY "pickupAddress" 
      ORDER BY COUNT(*) DESC 
      LIMIT 5
    `);

    // Cancellation Rate
    const cancelRateResult = await this.requestRepo.query(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'CANCELLED' OR status = 'FAILED' THEN 1 ELSE 0 END) as cancelled
      FROM ambulance_requests
    `);
    const total = Number(cancelRateResult[0]?.total || 0);
    const cancelled = Number(cancelRateResult[0]?.cancelled || 0);
    const cancellationRate = total > 0 ? Number(((cancelled / total) * 100).toFixed(2)) : 0;

    // Mock Vendor Performance
    const vendorPerformance = [
      { vendorId: 'v1', name: 'Alpha Med', completed: 145, cancelled: 12, avgEta: 450 },
      { vendorId: 'v2', name: 'City Rescue', completed: 98, cancelled: 4, avgEta: 380 },
      { vendorId: 'v3', name: 'Rapid Aid', completed: 210, cancelled: 22, avgEta: 520 },
      { vendorId: 'v4', name: 'Nightingale', completed: 65, cancelled: 1, avgEta: 310 },
    ];

    return {
      requestsPerDay: requestsPerDay.map((r: any) => ({ date: r.date, count: Number(r.count) })),
      requestsPerStatus: requestsPerStatus.map((r: any) => ({ status: r.status, count: Number(r.count) })),
      averageEtaSeconds,
      averageCompletionTimeSeconds,
      topPickupAreas: topPickupAreas.map((r: any) => ({ area: r.area, count: Number(r.count) })),
      cancellationRate,
      vendorPerformance,
    };
  }
}
