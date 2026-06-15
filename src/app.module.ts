import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LoggerModule } from './common/logger/logger.module';
import { typeOrmConfig } from './config/typeorm.config';
import { AmbulanceModule } from './modules/ambulance/ambulance.module';
import { VendorModule } from './modules/vendor/vendor.module';
import { QueuesModule } from './infrastructure/queues/queues.module';
import { WebsocketModule } from './gateway/websocket.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    LoggerModule,
    TypeOrmModule.forRoot(typeOrmConfig()),
    AmbulanceModule,
    VendorModule,
    QueuesModule,
    WebsocketModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
