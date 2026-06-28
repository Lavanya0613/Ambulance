import { Injectable, Inject } from '@nestjs/common';
import { DataSource, In, Not, Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { Queue } from 'bullmq';
import { AmbulanceRequest, RequestStatus } from '../ambulance/entities/ambulance-request.entity';

import { QUEUE_PROVIDERS } from '../../infrastructure/queues/queue.constants';

@Injectable()
export class DashboardService {
  constructor(
    @InjectRepository(AmbulanceRequest) private readonly ambulanceRepo: Repository<AmbulanceRequest>,

    private readonly dataSource: DataSource,
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE) private readonly bookingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.TRACKING_QUEUE) private readonly trackingQueue: Queue,
  ) {}

  async getActiveRequests() {
    const activeStatuses = [
      RequestStatus.REQUEST_CREATED,
      RequestStatus.SEARCHING_DRIVER,
      RequestStatus.VENDOR_ACCEPTED,
      RequestStatus.DRIVER_ASSIGNED,
      RequestStatus.EN_ROUTE,
      RequestStatus.ARRIVED,
      RequestStatus.PATIENT_ONBOARD,
      RequestStatus.DESTINATION_REACHED,
    ];

    const requests = await this.ambulanceRepo.find({
      where: { status: In(activeStatuses) },
      order: { updatedAt: 'DESC' },
    });

    return requests.map((r) => ({
      requestId: r.id,
      requestNumber: r.requestNumber,
      status: r.status,
      priority: r.priority || 'normal',
      patientName: r.patientName,
      pickupAddress: r.pickupAddress,
      dropAddress: r.dropAddress,
      driver: r.vendorDriverRef ? {
        vendorDriverRef: r.vendorDriverRef,
        name: r.vendorDriverName,
        phoneE164: r.vendorDriverPhone,
        vehicleNumber: r.vendorVehicleNumber,
        ambulanceType: r.vendorAmbulanceType,
      } : null,
      etaSeconds: r.etaSeconds,
      updatedAt: r.updatedAt,
    }));
  }

  async getSystemHealth() {
    let dbStatus = 'disconnected';
    try {
      await this.dataSource.query('SELECT 1');
      dbStatus = 'connected';
    } catch (e) {
      dbStatus = 'error';
    }

    return {
      uptimeSeconds: process.uptime(),
      memoryUsage: process.memoryUsage(),
      database: dbStatus,
      timestamp: new Date(),
    };
  }

  async getQueueStatus() {
    const [bookingCounts, trackingCounts] = await Promise.all([
      this.bookingQueue.getJobCounts(),
      this.trackingQueue.getJobCounts(),
    ]);

    return {
      waiting: bookingCounts.waiting + trackingCounts.waiting,
      active: bookingCounts.active + trackingCounts.active,
      completed: bookingCounts.completed + trackingCounts.completed,
      failed: bookingCounts.failed + trackingCounts.failed,
      delayed: bookingCounts.delayed + trackingCounts.delayed,
      paused: bookingCounts.paused + trackingCounts.paused,
      metrics: {
        bookingQueue: bookingCounts,
        trackingQueue: trackingCounts,
      },
    };
  }



  async getStatistics() {
    const totalBookings = await this.ambulanceRepo.count();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todayBookings = await this.ambulanceRepo.createQueryBuilder('req')
      .where('req.createdAt >= :today', { today })
      .getCount();

    const completedBookings = await this.ambulanceRepo.count({ where: { status: RequestStatus.COMPLETED } });
    const cancelledBookings = await this.ambulanceRepo.count({ where: { status: RequestStatus.CANCELLED } });

    const completionRate = totalBookings > 0 ? (completedBookings / totalBookings) * 100 : 0;
    const cancellationRate = totalBookings > 0 ? (cancelledBookings / totalBookings) * 100 : 0;

    const avgEtaResult = await this.ambulanceRepo.createQueryBuilder('req')
      .select('AVG(req.etaSeconds)', 'avgEta')
      .where('req.etaSeconds IS NOT NULL')
      .getRawOne();

    const averageEta = avgEtaResult?.avgEta ? Math.round(parseFloat(avgEtaResult.avgEta)) : null;

    return {
      totalBookings,
      todayBookings,
      completedBookings,
      cancelledBookings,
      completionRate: Math.round(completionRate * 100) / 100,
      cancellationRate: Math.round(cancellationRate * 100) / 100,
      averageEtaSeconds: averageEta,
    };
  }
}
