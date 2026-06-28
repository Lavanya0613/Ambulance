import { Module, forwardRef, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { WebsocketModule } from '../../gateway/websocket.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AmbulanceController } from './ambulance.controller';
import { AmbulanceService } from './ambulance.service';
import { AmbulanceRequest } from './entities/ambulance-request.entity';
import { TrackingPosition } from './entities/tracking-position.entity';
import { AmbulanceRepository } from './repositories/ambulance.repository';
import { TrackingRepository } from './repositories/tracking.repository';
import { EtaService } from './eta.service';
import { GeocodingService } from './geocoding.service';
import { JwtModule } from '@nestjs/jwt';
import { JwtMiddleware } from '../../common/middleware/jwt.middleware';
import { QueuesModule } from '../../infrastructure/queues/queues.module';
import { VendorModule } from '../vendor/vendor.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AmbulanceRequest, TrackingPosition]),
    forwardRef(() => QueuesModule),
    VendorModule,
    WebsocketModule,
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
  ],
  controllers: [AmbulanceController],
  providers: [AmbulanceService, AmbulanceRepository, TrackingRepository, EtaService, GeocodingService],
  exports: [AmbulanceService, AmbulanceRepository, TrackingRepository, EtaService, GeocodingService],
})
export class AmbulanceModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(JwtMiddleware).forRoutes(AmbulanceController);
  }
}
