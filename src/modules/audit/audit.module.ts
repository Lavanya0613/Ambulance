import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SystemAuditLog } from './entities/system-audit-log.entity';
import { AuditService } from './audit.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([SystemAuditLog])],
  providers: [AuditService],
  exports: [AuditService],
})
export class AuditModule {}
