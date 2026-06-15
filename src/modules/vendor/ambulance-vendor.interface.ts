export interface CreateBookingRequest {
  requestId: string;
  idempotencyKey?: string;
  pickup: { lat: number; lng: number; addressLine?: string };
  drop: { lat: number; lng: number; addressLine?: string };
  priority?: 'normal' | 'high' | 'critical';
  patient: { name: string; phoneE164: string };
  notes?: string;
}

export interface CreateBookingResponse {
  vendorBookingRef: string;
  accepted: boolean;
  status: string;
  driver?: {
    vendorDriverRef: string;
    name: string;
    phoneE164?: string;
    vehicleNumber?: string;
    ambulanceType?: string;
  } | null;
  etaSeconds?: number | null;
}

export interface CancelBookingResponse {
  vendorBookingRef: string;
  cancelAccepted: boolean;
  status: string;
}

export interface Position {
  vendorEventId: string;
  lat: number;
  lng: number;
  speedKmph?: number;
  headingDeg?: number;
  capturedAt: Date;
}

export interface VendorBooking {
  vendorBookingRef: string;
  requestId: string;
  status: string;
  driver?: any;
  etaSeconds?: number | null;
}

export interface AmbulanceVendor {
  readonly id: string;
  createBooking(req: CreateBookingRequest): Promise<CreateBookingResponse>;
  getBooking(vendorBookingRef: string): Promise<VendorBooking | null>;
  cancelBooking(vendorBookingRef: string, reason?: string): Promise<CancelBookingResponse>;
  pollPositions(vendorBookingRef: string, since?: Date): Promise<Position[]>;
  supportsPush?: boolean;
}
