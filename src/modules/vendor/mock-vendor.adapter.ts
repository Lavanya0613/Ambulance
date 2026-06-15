import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
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
export class MockVendorAdapter implements AmbulanceVendor, OnModuleInit {
  readonly id = 'mock';
  readonly supportsPush = true;
  private readonly logger = new Logger(MockVendorAdapter.name);

  // in-memory state for bookings and positions
  private bookings = new Map<string, VendorBooking>();
  private positions = new Map<string, Position[]>();
  private idempotency = new Map<string, string>();

  constructor(private readonly vendorManager: VendorManager) {}

  onModuleInit() {
    // register with vendor manager so it can route requests
    try {
      this.vendorManager.registerAdapter(this);
      this.logger.log('Registered MockVendorAdapter with VendorManager');
    } catch (err) {
      this.logger.warn('VendorManager registration deferred or failed', err?.message || err);
    }
  }

  async createBooking(req: CreateBookingRequest): Promise<CreateBookingResponse> {
    // idempotency: if key seen, return same booking
    if (req.idempotencyKey && this.idempotency.has(req.idempotencyKey)) {
      const existingRef = this.idempotency.get(req.idempotencyKey);
      const existing = this.bookings.get(existingRef);
      return {
        vendorBookingRef: existing.vendorBookingRef,
        accepted: existing.status !== 'FAILED',
        status: existing.status,
        driver: existing.driver || null,
        etaSeconds: existing.etaSeconds || null,
      };
    }

    const vendorBookingRef = `MOCK-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    const driver = {
      vendorDriverRef: `DRV-${Math.floor(Math.random() * 9000) + 1000}`,
      name: 'Ravi Kumar',
      phoneE164: '+919999998888',
      vehicleNumber: `MO-01-${Math.floor(Math.random() * 9000) + 1000}`,
      ambulanceType: 'als',
    };

    const booking: VendorBooking = {
      vendorBookingRef,
      requestId: req.requestId,
      status: 'ASSIGNED',
      driver,
      etaSeconds: 600,
    };

    this.bookings.set(vendorBookingRef, booking);
    this.positions.set(vendorBookingRef, []);
    if (req.idempotencyKey) this.idempotency.set(req.idempotencyKey, vendorBookingRef);

    this.scheduleLifecycle(req, vendorBookingRef);

    return {
      vendorBookingRef,
      accepted: true,
      status: booking.status,
      driver: booking.driver,
      etaSeconds: booking.etaSeconds,
    };
  }

  async getBooking(vendorBookingRef: string): Promise<VendorBooking | null> {
    return this.bookings.get(vendorBookingRef) || null;
  }

  async cancelBooking(vendorBookingRef: string): Promise<CancelBookingResponse> {
    const booking = this.bookings.get(vendorBookingRef);
    if (!booking) {
      return { vendorBookingRef, cancelAccepted: false, status: 'NOT_FOUND' };
    }
    booking.status = 'CANCELLED';
    this.bookings.set(vendorBookingRef, booking);
    return { vendorBookingRef, cancelAccepted: true, status: booking.status };
  }

  async pollPositions(vendorBookingRef: string, since?: Date): Promise<Position[]> {
    const all = this.positions.get(vendorBookingRef) || [];
    if (!since) return all.slice();
    return all.filter((p) => p.capturedAt > since);
  }

  private scheduleLifecycle(req: CreateBookingRequest, vendorBookingRef: string) {
    const checkpoints = [
      {
        delayMs: 1000,
        status: 'EN_ROUTE',
        latOffset: 0.001,
        lngOffset: 0.001,
        etaSeconds: 480,
      },
      {
        delayMs: 3000,
        status: 'ARRIVED',
        latOffset: 0.0005,
        lngOffset: 0.0005,
        etaSeconds: 240,
      },
      {
        delayMs: 5000,
        status: 'IN_PROGRESS',
        latOffset: 0.0002,
        lngOffset: 0.0002,
        etaSeconds: 120,
      },
      {
        delayMs: 8000,
        status: 'COMPLETED',
        latOffset: 0,
        lngOffset: 0,
        etaSeconds: 0,
      },
    ];

    checkpoints.forEach((checkpoint) => {
      setTimeout(() => {
        const current = this.bookings.get(vendorBookingRef);
        if (!current) return;
        if (current.status === 'CANCELLED') return;

        current.status = checkpoint.status;
        current.etaSeconds = checkpoint.etaSeconds;
        current.driver = current.driver;
        this.bookings.set(vendorBookingRef, current);

        const position: Position = {
          vendorEventId: uuidv4(),
          lat: req.pickup.lat + checkpoint.latOffset,
          lng: req.pickup.lng + checkpoint.lngOffset,
          speedKmph: checkpoint.status === 'COMPLETED' ? 0 : 25,
          headingDeg: 180,
          capturedAt: new Date(),
        };
        const positions = this.positions.get(vendorBookingRef) ?? [];
        positions.push(position);
        this.positions.set(vendorBookingRef, positions);
      }, checkpoint.delayMs);
    });
  }
}
