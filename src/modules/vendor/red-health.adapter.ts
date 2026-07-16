import { Injectable, Logger, NotImplementedException, OnModuleInit } from '@nestjs/common';
import {
  AmbulanceVendor,
  CreateBookingRequest,
  CreateBookingResponse,
  VendorBooking,
  CancelBookingResponse,
  Position,
} from './ambulance-vendor.interface';
import { VendorManager } from './vendor-manager.service';

@Injectable()
export class RedHealthAdapter implements AmbulanceVendor, OnModuleInit {
  readonly id = 'red-health';
  readonly supportsPush = true; // Set based on future RedHealth webhook capabilities
  private readonly logger = new Logger(RedHealthAdapter.name);

  constructor(private readonly vendorManager: VendorManager) {}

  onModuleInit() {
    // Register with vendor manager so it can route requests when this becomes active
    try {
      this.vendorManager.registerAdapter(this);
      this.logger.log('Registered RedHealthAdapter with VendorManager');
    } catch (err: any) {
      this.logger.warn('VendorManager registration deferred or failed for RedHealthAdapter', err?.message || err);
    }
  }

  async createBooking(req: CreateBookingRequest): Promise<CreateBookingResponse> {
    this.logger.debug(`createBooking called for RedHealth with requestId: ${req.requestId}`);
    throw new NotImplementedException('RedHealth API createBooking integration is pending');
  }

  async getBooking(vendorBookingRef: string): Promise<VendorBooking | null> {
    this.logger.debug(`getBooking called for RedHealth ref: ${vendorBookingRef}`);
    throw new NotImplementedException('RedHealth API getBooking integration is pending');
  }

  async cancelBooking(vendorBookingRef: string): Promise<CancelBookingResponse> {
    this.logger.debug(`cancelBooking called for RedHealth ref: ${vendorBookingRef}`);
    throw new NotImplementedException('RedHealth API cancelBooking integration is pending');
  }

  async pollPositions(vendorBookingRef: string, since?: Date): Promise<Position[]> {
    this.logger.debug(`pollPositions called for RedHealth ref: ${vendorBookingRef}`);
    throw new NotImplementedException('RedHealth API pollPositions integration is pending');
  }
}
