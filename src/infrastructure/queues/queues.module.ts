import { Module, forwardRef, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { queueProviders } from './queues.providers';
import { QUEUE_PROVIDERS } from './queue.constants';
import { VendorModule } from '../../modules/vendor/vendor.module';
import { AmbulanceModule } from '../../modules/ambulance/ambulance.module';
import { WebsocketModule } from '../../gateway/websocket.module';
import { DeadLetterJob } from './entities/dlq.entity';
import { DlqService } from './dlq.service';
import { QueuesController } from './queues.controller';
import { JwtModule } from '@nestjs/jwt';
import { JwtMiddleware } from '../../common/middleware/jwt.middleware';

@Module({
  imports: [
    VendorModule,
    WebsocketModule,
    forwardRef(() => AmbulanceModule),
    TypeOrmModule.forFeature([DeadLetterJob]),
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
  ],
  controllers: [QueuesController],
  providers: [...queueProviders, DlqService],
  exports: [
    QUEUE_PROVIDERS.BOOKING_QUEUE,
    QUEUE_PROVIDERS.TRACKING_QUEUE,
    QUEUE_PROVIDERS.DLQ_QUEUE,
    DlqService,
  ],
})
export class QueuesModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(JwtMiddleware).forRoutes(QueuesController);
  }
}
