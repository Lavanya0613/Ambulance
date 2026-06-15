import { ApiProperty } from '@nestjs/swagger';

export class RequestAmbulanceResponseDto {
  @ApiProperty({ format: 'uuid' })
  requestId: string;

  @ApiProperty()
  requestNumber: string;

  @ApiProperty()
  status: string;

  @ApiProperty({ format: 'date-time' })
  createdAt: Date;

  @ApiProperty({ required: false })
  assignedVendor?: any;

  @ApiProperty({ required: false })
  message?: string;
}
