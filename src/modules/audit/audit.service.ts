import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager } from 'typeorm';
import { SystemAuditLog } from './entities/system-audit-log.entity';

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(
    @InjectRepository(SystemAuditLog)
    private readonly repo: Repository<SystemAuditLog>,
  ) {}

  async logAction(
    action: string,
    userId?: string,
    entityId?: string,
    entityType?: string,
    oldValue?: string,
    newValue?: string,
    ipAddress?: string,
    description?: string,
    manager?: EntityManager,
  ): Promise<SystemAuditLog> {
    const logEntry = this.repo.create({
      action,
      userId,
      entityId,
      entityType,
      oldValue,
      newValue,
      ipAddress,
      description,
    });

    this.logger.log(`[AUDIT] Action: ${action} | User: ${userId} | Entity: ${entityType}(${entityId})`);

    if (manager) {
      return manager.save(logEntry);
    }
    return this.repo.save(logEntry);
  }

  async getLogs(entityId: string): Promise<SystemAuditLog[]> {
    return this.repo.find({
      where: { entityId },
      order: { timestamp: 'ASC' },
    });
  }
}
