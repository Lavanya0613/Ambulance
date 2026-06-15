import { Module, forwardRef } from '@nestjs/common';
import { queueProviders } from './queues.providers';
import { VendorModule } from '../../modules/vendor/vendor.module';
import { AmbulanceModule } from '../../modules/ambulance/ambulance.module';
import { WebsocketModule } from '../../gateway/websocket.module';

@Module({
  imports: [
    VendorModule,
    WebsocketModule,
    forwardRef(() => AmbulanceModule),
  ],
  providers: [...queueProviders],
  exports: [...queueProviders],
})
export class QueuesModule {}
