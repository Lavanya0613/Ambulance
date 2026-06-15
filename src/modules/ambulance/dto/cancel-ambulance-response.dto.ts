import { ApiProperty } from '@nestjs/swagger';

export class CancelAmbulanceResponseDto {
  @ApiProperty({ format: 'uuid' })
  requestId: string;

  @ApiProperty({ format: 'date-time' })
  cancelledAt: Date;

  @ApiProperty()
  status: string;

  @ApiProperty({ required: false })
  message?: string;
}
