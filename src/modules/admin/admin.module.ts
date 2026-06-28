import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AmbulanceRequest } from '../ambulance/entities/ambulance-request.entity';
import { SystemAuditLog } from '../audit/entities/system-audit-log.entity';
import { TrackingPosition } from '../ambulance/entities/tracking-position.entity';
import { JwtModule } from '@nestjs/jwt';
import { JwtMiddleware } from '../../common/middleware/jwt.middleware';
import { QueuesModule } from '../../infrastructure/queues/queues.module';
import { WebsocketModule } from '../../gateway/websocket.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AmbulanceRequest, TrackingPosition, SystemAuditLog]),
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
    QueuesModule,
    WebsocketModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(JwtMiddleware).forRoutes(AdminController);
  }
}
