import { Controller, Get, Post, Param, Inject, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { Queue } from 'bullmq';
import { DlqService } from './dlq.service';
import { QUEUE_PROVIDERS } from './queue.constants';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Queues')
@ApiBearerAuth()
@UseGuards(RolesGuard)
@Controller('queues')
export class QueuesController {
  constructor(
    private readonly dlqService: DlqService,
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE) private readonly bookingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.TRACKING_QUEUE) private readonly trackingQueue: Queue,
  ) {}

  @Get('status')
  @Roles('admin')
  @ApiOperation({ summary: 'Get overall queue processing metrics' })
  @ApiResponse({ status: 200, description: 'Queue statistics and metrics' })
  async getQueueStatus() {
    const [bookingCounts, trackingCounts, deadLetter] = await Promise.all([
      this.bookingQueue.getJobCounts(),
      this.trackingQueue.getJobCounts(),
      this.dlqService.getDlqCount(),
    ]);

    return {
      waiting: bookingCounts.waiting + trackingCounts.waiting,
      active: bookingCounts.active + trackingCounts.active,
      completed: bookingCounts.completed + trackingCounts.completed,
      failed: bookingCounts.failed + trackingCounts.failed,
      delayed: bookingCounts.delayed + trackingCounts.delayed,
      paused: bookingCounts.paused + trackingCounts.paused,
      deadLetter,
      metrics: {
        bookingQueue: bookingCounts,
        trackingQueue: trackingCounts,
      }
    };
  }

  @Get('dlq')
  @Roles('admin')
  @ApiOperation({ summary: 'Get all jobs in the Dead Letter Queue' })
  @ApiResponse({ status: 200, description: 'List of dead letter jobs' })
  async getDlqJobs() {
    return this.dlqService.getFailedJobs();
  }

  @Post('dlq/:id/retry')
  @Roles('admin')
  @ApiOperation({ summary: 'Retry a specific job from the DLQ' })
  @ApiResponse({ status: 200, description: 'Job successfully re-queued' })
  async retryDlqJob(@Param('id') id: string) {
    return this.dlqService.retryJob(id);
  }
}
