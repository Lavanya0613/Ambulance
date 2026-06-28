import { ApiProperty } from '@nestjs/swagger';

export class DashboardResponseDto {
  @ApiProperty()
  todaysRequests: number;

  @ApiProperty()
  pending: number;

  @ApiProperty()
  assigned: number;

  @ApiProperty()
  enroute: number;

  @ApiProperty()
  completed: number;

  @ApiProperty()
  cancelled: number;

  @ApiProperty()
  driversAvailable: number;

  @ApiProperty()
  driversBusy: number;

  @ApiProperty()
  queueSize: number;

  @ApiProperty()
  averageEta: number;

  @ApiProperty()
  averageTripTime: number;
}
