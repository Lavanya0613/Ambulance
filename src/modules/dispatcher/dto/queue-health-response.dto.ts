import { ApiProperty } from '@nestjs/swagger';

export class QueueMetricsDto {
  @ApiProperty()
  queueName: string;

  @ApiProperty()
  active: number;

  @ApiProperty()
  waiting: number;

  @ApiProperty()
  completed: number;

  @ApiProperty()
  failed: number;

  @ApiProperty()
  delayed: number;

  @ApiProperty()
  avgProcessingTimeMs: number;

  @ApiProperty()
  totalRetries: number;
}

export class QueueHealthResponseDto {
  @ApiProperty({ type: [QueueMetricsDto] })
  queues: QueueMetricsDto[];
}
