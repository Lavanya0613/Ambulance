import { Column, CreateDateColumn, Entity, OneToMany, PrimaryColumn, UpdateDateColumn } from 'typeorm';

export enum RequestStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  ASSIGNED = 'ASSIGNED',
  EN_ROUTE = 'EN_ROUTE',
  ARRIVED = 'ARRIVED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
  FAILED = 'FAILED',
}

@Entity({ name: 'ambulance_requests' })
export class AmbulanceRequest {
  @PrimaryColumn('uuid')
  id: string;

  @Column({ unique: true })
  requestNumber: string;

  @Column({ type: 'enum', enum: RequestStatus, default: RequestStatus.PENDING })
  status: RequestStatus;

  @Column('double precision')
  pickupLat: number;

  @Column('double precision')
  pickupLng: number;

  @Column('double precision')
  dropLat: number;

  @Column('double precision')
  dropLng: number;

  @Column()
  patientName: string;

  @Column()
  patientPhone: string;

  @Column({ nullable: true })
  notes?: string;

  @Column({ nullable: true })
  priority?: string;

  @Column({ nullable: true })
  idempotencyKey?: string;

  @Column({ nullable: true })
  assignedVendorId?: string;

  @Column({ nullable: true })
  vendorBookingRef?: string;

  @Column('jsonb', { nullable: true })
  assignedDriver?: any;

  @Column({ type: 'integer', nullable: true })
  etaSeconds?: number;

  @Column({ nullable: true })
  cancelReason?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @OneToMany(() => (require('./tracking-position.entity').TrackingPosition), (p: any) => p.request)
  positions: any[];
}
