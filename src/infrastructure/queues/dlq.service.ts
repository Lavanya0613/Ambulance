import { Injectable, Inject, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Queue } from 'bullmq';
import { DeadLetterJob } from './entities/dlq.entity';
import { QUEUE_PROVIDERS, QUEUE_NAMES } from './queue.constants';
import { WebsocketGateway } from '../../gateway/websocket.gateway';

@Injectable()
export class DlqService {
  constructor(
    @InjectRepository(DeadLetterJob)
    private readonly repo: Repository<DeadLetterJob>,
    @Inject(QUEUE_PROVIDERS.BOOKING_QUEUE)
    private readonly bookingQueue: Queue,
    @Inject(QUEUE_PROVIDERS.TRACKING_QUEUE)
    private readonly trackingQueue: Queue,
    private readonly wsGateway: WebsocketGateway,
  ) {}

  async storeFailedJob(
    queueName: string,
    jobId: string,
    payload: any,
    error: string,
    retryCount: number,
  ): Promise<DeadLetterJob> {
    const job = this.repo.create({
      queueName,
      jobId,
      payload,
      error,
      retryCount,
    });
    const saved = await this.repo.save(job);
    
    // Emit notification to dispatcher
    this.wsGateway.server.to('dispatcher-room').emit('queue_failure', {
      id: saved.id,
      queueName,
      jobId,
      error,
    });

    return saved;
  }

  async getFailedJobs(): Promise<DeadLetterJob[]> {
    return this.repo.find({
      order: { failedAt: 'DESC' },
    });
  }

  async getDlqCount(): Promise<number> {
    return this.repo.count();
  }

  async retryJob(id: string): Promise<{ success: boolean; message: string }> {
    const dlqJob = await this.repo.findOne({ where: { id } });
    if (!dlqJob) {
      throw new NotFoundException(`DLQ job with id ${id} not found`);
    }

    if (dlqJob.queueName === QUEUE_NAMES.BOOKING) {
      await this.bookingQueue.add('create-booking', dlqJob.payload, {
        jobId: dlqJob.jobId + '-retry', // Avoid BullMQ deduplication logic on exact same ID if it still exists in failed sets
        attempts: 5,
        backoff: { type: 'exponential', delay: 1000 },
        removeOnComplete: true,
        removeOnFail: false,
      });
    } else if (dlqJob.queueName === QUEUE_NAMES.TRACKING) {
      await this.trackingQueue.add('poll-tracking', dlqJob.payload, {
        jobId: dlqJob.jobId + '-retry',
        delay: 1500,
        attempts: 3,
        backoff: { type: 'exponential', delay: 500 },
        removeOnComplete: true,
        removeOnFail: false,
      });
    } else {
      throw new Error(`Unknown queue name: ${dlqJob.queueName}`);
    }

    await this.repo.remove(dlqJob);
    return { success: true, message: `Job ${id} re-queued to ${dlqJob.queueName}` };
  }
}
