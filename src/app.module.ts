import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { LoggerModule } from './common/logger/logger.module';
import { typeOrmConfig } from './config/typeorm.config';
import { AmbulanceModule } from './modules/ambulance/ambulance.module';
import { VendorModule } from './modules/vendor/vendor.module';
import { QueuesModule } from './infrastructure/queues/queues.module';
import { WebsocketModule } from './gateway/websocket.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { DispatcherModule } from './modules/dispatcher/dispatcher.module';
import { AuditModule } from './modules/audit/audit.module';
import { AdminModule } from './modules/admin/admin.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 20 }]),
    LoggerModule,
    TypeOrmModule.forRoot(typeOrmConfig()),
    AmbulanceModule,
    VendorModule,
    QueuesModule,
    WebsocketModule,
    DashboardModule,
    DispatcherModule,
    AuditModule,
    AdminModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
