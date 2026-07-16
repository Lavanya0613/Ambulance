import { Module } from '@nestjs/common';
import { VendorManager } from './vendor-manager.service';
import { MockVendorAdapter } from './mock-vendor.adapter';
import { RedHealthAdapter } from './red-health.adapter';

@Module({
  providers: [VendorManager, MockVendorAdapter, RedHealthAdapter],
  exports: [VendorManager],
})
export class VendorModule {}
