import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TrackingPosition } from '../entities/tracking-position.entity';

@Injectable()
export class TrackingRepository {
  constructor(
    @InjectRepository(TrackingPosition)
    private readonly repo: Repository<TrackingPosition>,
  ) {}

  async addPosition(position: Partial<TrackingPosition>) {
    const p = this.repo.create(position);
    return this.repo.save(p);
  }

  async findLatestByRequest(requestId: string) {
    return this.repo.findOne({ where: { request: { id: requestId } }, order: { capturedAt: 'DESC' } });
  }

  async findSince(requestId: string, since?: Date) {
    const qb = this.repo.createQueryBuilder('p').where('p.requestId = :requestId', { requestId });
    if (since) qb.andWhere('p.capturedAt > :since', { since });
    qb.orderBy('p.capturedAt', 'ASC');
    return qb.getMany();
  }
}
