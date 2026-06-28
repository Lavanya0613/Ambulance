import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { DashboardController } from './dashboard.controller';
import { DashboardService } from './dashboard.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AmbulanceModule } from '../ambulance/ambulance.module';
import { QueuesModule } from '../../infrastructure/queues/queues.module';
import { JwtMiddleware } from '../../common/middleware/jwt.middleware';
import { AmbulanceRequest } from '../ambulance/entities/ambulance-request.entity';


@Module({
  imports: [
    TypeOrmModule.forFeature([AmbulanceRequest]),
    AmbulanceModule,
    QueuesModule,
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
  ],
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(JwtMiddleware).forRoutes(DashboardController);
  }
}
