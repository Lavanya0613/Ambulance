import { Injectable, Inject } from '@nestjs/common';
import { Queue } from 'bullmq';
import { QUEUE_PROVIDERS, QUEUE_NAMES } from '../../infrastructure/queues/queue.constants';
import { QueueHealthResponseDto, QueueMetricsDto } from './dto/queue-health-response.dto';

@Injectable()
export class QueueMonitorService {
  constructor(
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE) private readonly bookingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.TRACKING_QUEUE) private readonly trackingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.DLQ_QUEUE) private readonly dlqQueue: Queue,
  ) {}

  async getQueueHealth(): Promise<QueueHealthResponseDto> {
    const queues = [
      { instance: this.bookingQueue, name: QUEUE_NAMES.BOOKING },
      { instance: this.trackingQueue, name: QUEUE_NAMES.TRACKING },
      { instance: this.dlqQueue, name: QUEUE_NAMES.DLQ },
    ];

    const metricsPromises = queues.map(async (q) => {
      const [counts, completedJobs, failedJobs] = await Promise.all([
        q.instance.getJobCounts('active', 'waiting', 'completed', 'failed', 'delayed'),
        q.instance.getJobs(['completed'], 0, 50, true),
        q.instance.getJobs(['failed'], 0, 50, true)
      ]);

      let totalProcessingTime = 0;
      let validCompletedCount = 0;
      let totalRetries = 0;

      // Calculate processing times and retries from completed jobs
      for (const job of completedJobs) {
        if (job.finishedOn && job.processedOn) {
          totalProcessingTime += (job.finishedOn - job.processedOn);
          validCompletedCount++;
        }
        if (job.attemptsMade) {
          totalRetries += job.attemptsMade;
        }
      }

      // Add retries from failed jobs
      for (const job of failedJobs) {
        if (job.attemptsMade) {
          totalRetries += job.attemptsMade;
        }
      }

      const avgProcessingTimeMs = validCompletedCount > 0 
        ? Math.floor(totalProcessingTime / validCompletedCount) 
        : 0;

      const metrics: QueueMetricsDto = {
        queueName: q.name,
        active: counts.active || 0,
        waiting: counts.waiting || 0,
        completed: counts.completed || 0,
        failed: counts.failed || 0,
        delayed: counts.delayed || 0,
        avgProcessingTimeMs,
        totalRetries,
      };

      return metrics;
    });

    const results = await Promise.all(metricsPromises);

    return { queues: results };
  }
}
