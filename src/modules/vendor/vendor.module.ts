import { Module } from '@nestjs/common';
import { VendorManager } from './vendor-manager.service';
import { MockVendorAdapter } from './mock-vendor.adapter';

@Module({
  providers: [VendorManager, MockVendorAdapter],
  exports: [VendorManager],
})
export class VendorModule {}
