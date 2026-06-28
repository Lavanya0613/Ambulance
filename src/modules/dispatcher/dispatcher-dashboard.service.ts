import { Injectable, Inject } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Queue } from 'bullmq';
import { AmbulanceRequest, RequestStatus } from '../ambulance/entities/ambulance-request.entity';

import { QUEUE_PROVIDERS } from '../../infrastructure/queues/queue.constants';
import { DashboardResponseDto } from './dto/dashboard-response.dto';

@Injectable()
export class DispatcherDashboardService {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly requestRepo: Repository<AmbulanceRequest>,

    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE)
    private readonly bookingQueue: Queue,
  ) {}

  async getDashboardSummary(): Promise<DashboardResponseDto> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Run aggregations concurrently
    const [requestsAgg, queueSize] = await Promise.all([
      // 1. Optimized Request Aggregation
      this.requestRepo.createQueryBuilder('req')
        .select(`SUM(CASE WHEN req.createdAt >= :today THEN 1 ELSE 0 END)`, 'todaysRequests')
        .addSelect(`SUM(CASE WHEN req.status IN (:...pendingStatuses) THEN 1 ELSE 0 END)`, 'pending')
        .addSelect(`SUM(CASE WHEN req.status IN (:...assignedStatuses) THEN 1 ELSE 0 END)`, 'assigned')
        .addSelect(`SUM(CASE WHEN req.status IN (:...enrouteStatuses) THEN 1 ELSE 0 END)`, 'enroute')
        .addSelect(`SUM(CASE WHEN req.status = :completedStatus THEN 1 ELSE 0 END)`, 'completed')
        .addSelect(`SUM(CASE WHEN req.status IN (:...cancelledStatuses) THEN 1 ELSE 0 END)`, 'cancelled')
        .addSelect(`AVG(req.etaSeconds)`, 'averageEta')
        // For average trip time, we roughly assume difference between updatedAt and createdAt for completed trips
        .addSelect(`AVG(CASE WHEN req.status = :completedStatus THEN EXTRACT(EPOCH FROM (req.updatedAt - req.createdAt)) ELSE NULL END)`, 'averageTripTime')
        .setParameters({
          today,
          pendingStatuses: [RequestStatus.REQUEST_CREATED, RequestStatus.SEARCHING_DRIVER],
          assignedStatuses: [RequestStatus.VENDOR_ACCEPTED, RequestStatus.DRIVER_ASSIGNED],
          enrouteStatuses: [RequestStatus.EN_ROUTE, RequestStatus.ARRIVED, RequestStatus.PATIENT_ONBOARD, RequestStatus.DESTINATION_REACHED],
          completedStatus: RequestStatus.COMPLETED,
          cancelledStatuses: [RequestStatus.CANCELLED, RequestStatus.FAILED],
        })
        .getRawOne(),

      // 2. Queue Sizing
      this.bookingQueue.count(),
    ]);

    return {
      todaysRequests: parseInt(requestsAgg?.todaysRequests || '0', 10),
      pending: parseInt(requestsAgg?.pending || '0', 10),
      assigned: parseInt(requestsAgg?.assigned || '0', 10),
      enroute: parseInt(requestsAgg?.enroute || '0', 10),
      completed: parseInt(requestsAgg?.completed || '0', 10),
      cancelled: parseInt(requestsAgg?.cancelled || '0', 10),
      driversAvailable: 0,
      driversBusy: 0,
      queueSize: queueSize,
      averageEta: Math.floor(parseFloat(requestsAgg?.averageEta || '0')),
      averageTripTime: Math.floor(parseFloat(requestsAgg?.averageTripTime || '0')),
    };
  }
}
