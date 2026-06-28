import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'system_audit_logs' })
export class SystemAuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  action: string;

  @Column({ name: 'user_id', nullable: true })
  userId?: string;

  @Column({ name: 'entity_id', nullable: true })
  entityId?: string;

  @Column({ name: 'entity_type', nullable: true })
  entityType?: string;

  @Column({ name: 'old_value', nullable: true, type: 'text' })
  oldValue?: string;

  @Column({ name: 'new_value', nullable: true, type: 'text' })
  newValue?: string;

  @Column({ name: 'ip_address', nullable: true })
  ipAddress?: string;

  @Column({ nullable: true, type: 'text' })
  description?: string;

  @CreateDateColumn({ name: 'timestamp' })
  timestamp: Date;
}
