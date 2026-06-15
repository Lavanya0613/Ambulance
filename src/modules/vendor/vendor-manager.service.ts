import { Injectable, Logger } from '@nestjs/common';
import { AmbulanceVendor, CreateBookingRequest, CreateBookingResponse, Position, VendorBooking, CancelBookingResponse } from './ambulance-vendor.interface';

@Injectable()
export class VendorManager {
  private readonly logger = new Logger(VendorManager.name);
  private adapters = new Map<string, AmbulanceVendor>();

  registerAdapter(adapter: AmbulanceVendor) {
    if (!adapter || !adapter.id) throw new Error('Adapter must have an id');
    this.adapters.set(adapter.id, adapter);
    this.logger.log(`Registered vendor adapter: ${adapter.id}`);
  }

  listAdapters(): string[] {
    return Array.from(this.adapters.keys());
  }

  getAdapter(vendorId: string): AmbulanceVendor | undefined {
    return this.adapters.get(vendorId);
  }

  // simple selection: pick adapter by id if provided, otherwise pick first registered
  private selectAdapter(preferredVendorId?: string): AmbulanceVendor | undefined {
    if (preferredVendorId) return this.adapters.get(preferredVendorId);
    const first = this.adapters.values().next();
    return first.done ? undefined : first.value;
  }

  async dispatchToVendor(req: CreateBookingRequest, preferredVendorId?: string): Promise<CreateBookingResponse> {
    const adapter = this.selectAdapter(preferredVendorId);
    if (!adapter) throw new Error('No vendor adapters available');
    return adapter.createBooking(req);
  }

  async cancelVendorBooking(vendorId: string, vendorBookingRef: string): Promise<CancelBookingResponse> {
    const adapter = this.getAdapter(vendorId);
    if (!adapter) throw new Error(`Vendor adapter not found: ${vendorId}`);
    return adapter.cancelBooking(vendorBookingRef);
  }

  async pollPositions(vendorId: string, vendorBookingRef: string, since?: Date): Promise<Position[]> {
    const adapter = this.getAdapter(vendorId);
    if (!adapter) throw new Error(`Vendor adapter not found: ${vendorId}`);
    return adapter.pollPositions(vendorBookingRef, since);
  }

  async getVendorBooking(vendorId: string, vendorBookingRef: string): Promise<VendorBooking | null> {
    const adapter = this.getAdapter(vendorId);
    if (!adapter) throw new Error(`Vendor adapter not found: ${vendorId}`);
    return adapter.getBooking(vendorBookingRef);
  }
}
