import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AmbulanceRequest, RequestStatus } from '../entities/ambulance-request.entity';
import { AuditService } from '../../audit/audit.service';

@Injectable()
export class AmbulanceRepository {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly repo: Repository<AmbulanceRequest>,
    private readonly auditService: AuditService,
  ) {}

  async create(request: Partial<AmbulanceRequest>) {
    const entity = this.repo.create(request);
    return this.repo.save(entity);
  }

  async findById(id: string) {
    return this.repo.findOne({ where: { id } });
  }

  async findByIdempotencyKey(key: string) {
    return this.repo.findOne({ where: { idempotencyKey: key } });
  }

  async updateStatus(id: string, status: RequestStatus) {
    const existing = await this.findById(id);
    if (existing && existing.status !== status) {
      const prevStatus = existing.status;
      await this.repo.update({ id }, { status });
      await this.auditService.logAction(
        'Status Updated',
        'system',
        id,
        'AmbulanceRequest',
        prevStatus,
        status
      );
    } else if (!existing) {
      await this.repo.update({ id }, { status });
    }
    return this.findById(id);
  }

  async updateEta(id: string, etaSeconds: number | null) {
    await this.repo.update({ id }, { etaSeconds: etaSeconds ?? undefined });
    return this.findById(id);
  }

  async assignVendor(id: string, vendorId: string, vendorBookingRef: string, driver: any, etaSeconds?: number) {
    const request = await this.findById(id);
    if (!request) return null;
    request.assignedVendorId = vendorId;
    request.vendorBookingRef = vendorBookingRef;
    if (driver) {
      request.vendorDriverRef = driver.vendorDriverRef;
      request.vendorDriverName = driver.name;
      request.vendorDriverPhone = driver.phoneE164;
      request.vendorVehicleNumber = driver.vehicleNumber;
      request.vendorAmbulanceType = driver.ambulanceType;
    }
    request.etaSeconds = etaSeconds ?? null;
    const result = await this.repo.save(request);
    await this.auditService.logAction(id, 'Driver Assigned', undefined, driver?.vendorDriverRef);
    return result;
  }
}
