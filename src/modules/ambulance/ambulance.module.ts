import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AmbulanceController } from './ambulance.controller';
import { AmbulanceService } from './ambulance.service';
import { AmbulanceRequest } from './entities/ambulance-request.entity';
import { TrackingPosition } from './entities/tracking-position.entity';
import { AmbulanceRepository } from './repositories/ambulance.repository';
import { TrackingRepository } from './repositories/tracking.repository';
import { QueuesModule } from '../../infrastructure/queues/queues.module';
import { VendorModule } from '../vendor/vendor.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([AmbulanceRequest, TrackingPosition]),
    forwardRef(() => QueuesModule),
    VendorModule,
  ],
  controllers: [AmbulanceController],
  providers: [AmbulanceService, AmbulanceRepository, TrackingRepository],
  exports: [AmbulanceService, AmbulanceRepository, TrackingRepository],
})
export class AmbulanceModule {}
