import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebsocketModule } from '../../gateway/websocket.module';
import { DispatcherController } from './dispatcher.controller';
import { DispatcherService } from './dispatcher.service';
import { DispatcherDashboardService } from './dispatcher-dashboard.service';
import { QueueMonitorService } from './queue-monitor.service';
import { AmbulanceModule } from '../ambulance/ambulance.module';
import { QueuesModule } from '../../infrastructure/queues/queues.module';
import { JwtMiddleware } from '../../common/middleware/jwt.middleware';
import { AmbulanceRequest } from '../ambulance/entities/ambulance-request.entity';


@Module({
  imports: [
    TypeOrmModule.forFeature([AmbulanceRequest]),
    AmbulanceModule,
    QueuesModule,
    WebsocketModule,
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
  ],
  controllers: [DispatcherController],
  providers: [DispatcherService, DispatcherDashboardService, QueueMonitorService],
})
export class DispatcherModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // Auth endpoints are public (login, refresh, seed) — exclude them from JWT middleware
    consumer.apply(JwtMiddleware).forRoutes(DispatcherController);
  }
}
