import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'dead_letter_jobs' })
export class DeadLetterJob {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  jobId: string;

  @Column()
  queueName: string;

  @Column('jsonb')
  payload: any;

  @Column('text')
  error: string;

  @Column('int')
  retryCount: number;

  @CreateDateColumn()
  failedAt: Date;
}
