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

    const vendorDriverRef = `DRV-${Math.floor(Math.random() * 9000) + 1000}`;
    const driver = {
      vendorDriverRef,
      name: 'Ravi Kumar',
      phoneE164: '+919999998888',
      vehicleNumber: `MO-01-${Math.floor(Math.random() * 9000) + 1000}`,
      ambulanceType: 'ALS',
      ambulanceNumber: `AMB-${Math.floor(Math.random() * 900) + 100}`,
      photoUrl: `https://i.pravatar.cc/150?u=${vendorDriverRef}`,
    };

    const booking: VendorBooking = {
      vendorBookingRef,
      requestId: req.requestId,
      status: 'SEARCHING_DRIVER',
      driver,
      etaSeconds: 600,
    };

    this.bookings.set(vendorBookingRef, booking);
    this.positions.set(vendorBookingRef, []);
    if (req.idempotencyKey) this.idempotency.set(req.idempotencyKey, vendorBookingRef);

    this.startSimulation(req, vendorBookingRef);

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

  private startSimulation(req: CreateBookingRequest, vendorBookingRef: string) {
    const TICK_MS = 2000;
    const SPEED_KMPH_TO_PICKUP = 60; // Make it fast for simulation
    const SPEED_KMPH_TO_DROP = 40;

    const getDistanceFromLatLonInKm = (lat1: number, lon1: number, lat2: number, lon2: number) => {
      const R = 6371; // Radius of the earth in km
      const dLat = (lat2 - lat1) * (Math.PI / 180);
      const dLon = (lon2 - lon1) * (Math.PI / 180);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    const getHeading = (lat1: number, lon1: number, lat2: number, lon2: number) => {
      const dLon = (lon2 - lon1) * (Math.PI / 180);
      const y = Math.sin(dLon) * Math.cos(lat2 * (Math.PI / 180));
      const x =
        Math.cos(lat1 * (Math.PI / 180)) * Math.sin(lat2 * (Math.PI / 180)) -
        Math.sin(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * Math.cos(dLon);
      let brng = Math.atan2(y, x) * (180 / Math.PI);
      return (brng + 360) % 360;
    };

    // Start exactly at pickup coordinates
    let currentLat = req.pickup.lat;
    let currentLng = req.pickup.lng;

    let phase = 'WAIT_ACCEPT';
    let phaseTicks = 0;

    const intervalId = setInterval(() => {
      const booking = this.bookings.get(vendorBookingRef);
      if (!booking || booking.status === 'CANCELLED' || phase === 'COMPLETED') {
        clearInterval(intervalId);
        return;
      }

      let targetLat = req.pickup.lat;
      let targetLng = req.pickup.lng;
      let speedKmph = SPEED_KMPH_TO_PICKUP;

      if (phase === 'TO_DROP') {
        targetLat = req.drop.lat;
        targetLng = req.drop.lng;
        speedKmph = SPEED_KMPH_TO_DROP;
      }

      let newStatus = booking.status;
      let currentSpeed = speedKmph;
      let heading = getHeading(currentLat, currentLng, targetLat, targetLng);

      phaseTicks++;

      if (phase === 'WAIT_ACCEPT') {
        currentSpeed = 0;
        if (phaseTicks >= 2) {
          newStatus = 'VENDOR_ACCEPTED';
          phase = 'WAIT_ASSIGN';
          phaseTicks = 0;
        }
      } else if (phase === 'WAIT_ASSIGN') {
        currentSpeed = 0;
        if (phaseTicks >= 2) {
          newStatus = 'DRIVER_ASSIGNED';
          phase = 'TO_PICKUP';
          phaseTicks = 0;
        }
      } else if (phase === 'TO_PICKUP' || phase === 'TO_DROP') {
        const distKm = getDistanceFromLatLonInKm(currentLat, currentLng, targetLat, targetLng);
        const distToMoveKm = (speedKmph / 3600) * (TICK_MS / 1000);

        if (distKm <= distToMoveKm) {
          currentLat = targetLat;
          currentLng = targetLng;
          currentSpeed = 0;
          if (phase === 'TO_PICKUP') {
            newStatus = 'ARRIVED';
            phase = 'AT_PICKUP';
            phaseTicks = 0;
          } else if (phase === 'TO_DROP') {
            newStatus = 'DESTINATION_REACHED';
            phase = 'AT_DROP';
            phaseTicks = 0;
          }
        } else {
          const ratio = distToMoveKm / distKm;
          currentLat += (targetLat - currentLat) * ratio;
          currentLng += (targetLng - currentLng) * ratio;
          newStatus = phase === 'TO_PICKUP' ? 'EN_ROUTE' : 'PATIENT_ONBOARD';
        }
      } else if (phase === 'AT_PICKUP') {
        newStatus = 'ARRIVED';
        currentSpeed = 0;
        if (phaseTicks >= 3) {
          newStatus = 'PATIENT_ONBOARD';
          phase = 'TO_DROP';
          phaseTicks = 0;
        }
      } else if (phase === 'AT_DROP') {
        newStatus = 'DESTINATION_REACHED';
        currentSpeed = 0;
        if (phaseTicks >= 3) {
          newStatus = 'COMPLETED';
          phase = 'COMPLETED';
          phaseTicks = 0;
        }
      }

      let etaSeconds = 0;
      if (phase === 'TO_PICKUP') {
        etaSeconds = Math.floor(
          (getDistanceFromLatLonInKm(currentLat, currentLng, req.pickup.lat, req.pickup.lng) / speedKmph) * 3600,
        );
      } else if (phase === 'TO_DROP' || phase === 'AT_PICKUP') {
        etaSeconds = Math.floor(
          (getDistanceFromLatLonInKm(currentLat, currentLng, req.drop.lat, req.drop.lng) / SPEED_KMPH_TO_DROP) * 3600,
        );
      }

      booking.status = newStatus;
      booking.etaSeconds = etaSeconds;
      this.bookings.set(vendorBookingRef, booking);

      const position: Position = {
        vendorEventId: uuidv4(),
        lat: currentLat,
        lng: currentLng,
        speedKmph: currentSpeed,
        headingDeg: Math.round(heading),
        capturedAt: new Date(),
      };
      const positions = this.positions.get(vendorBookingRef) ?? [];
      positions.push(position);
      this.positions.set(vendorBookingRef, positions);

      if (phase === 'COMPLETED') {
        clearInterval(intervalId);
      }
    }, TICK_MS);
  }
}
