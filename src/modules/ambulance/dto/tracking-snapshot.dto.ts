import { ApiProperty } from '@nestjs/swagger';

class DriverDto {
  @ApiProperty()
  vendorDriverRef: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  phoneE164: string;

  @ApiProperty()
  vehicleNumber: string;

  @ApiProperty()
  ambulanceType: string;
}

class PositionDto {
  @ApiProperty()
  vendorEventId: string;

  @ApiProperty({ format: 'double' })
  lat: number;

  @ApiProperty({ format: 'double' })
  lng: number;

  @ApiProperty({ required: false })
  speedKmph?: number;

  @ApiProperty({ required: false })
  headingDeg?: number;

  @ApiProperty({ format: 'date-time' })
  capturedAt: Date;
}

export class TrackingSnapshotDto {
  @ApiProperty({ format: 'uuid' })
  requestId: string;

  @ApiProperty()
  status: string;

  @ApiProperty({ type: DriverDto, required: false })
  driver?: DriverDto | null;

  @ApiProperty({ required: false })
  etaSeconds?: number | null;

  @ApiProperty({ type: PositionDto, required: false })
  lastLocation?: PositionDto | null;

  @ApiProperty({ format: 'date-time' })
  updatedAt: Date;

  // Pickup / drop coordinates for map rendering
  @ApiProperty({ format: 'double' })
  pickupLat: number;

  @ApiProperty({ format: 'double' })
  pickupLng: number;

  @ApiProperty({ format: 'double' })
  dropLat: number;

  @ApiProperty({ format: 'double' })
  dropLng: number;

  @ApiProperty()
  patientName: string;

  @ApiProperty()
  requestNumber: string;
}
