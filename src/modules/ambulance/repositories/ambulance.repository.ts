import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AmbulanceRequest, RequestStatus } from '../entities/ambulance-request.entity';

@Injectable()
export class AmbulanceRepository {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly repo: Repository<AmbulanceRequest>,
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
    await this.repo.update({ id }, { status });
    return this.findById(id);
  }

  async updateEta(id: string, etaSeconds: number | null) {
    await this.repo.update({ id }, { etaSeconds: etaSeconds ?? undefined });
    return this.findById(id);
  }

  async assignVendor(id: string, vendorId: string, vendorBookingRef: string, driver: any, etaSeconds?: number) {
    await this.repo.update({ id }, { assignedVendorId: vendorId, vendorBookingRef, assignedDriver: driver, etaSeconds });
    return this.findById(id);
  }
}
