import { Column, CreateDateColumn, Entity, OneToMany, PrimaryColumn, UpdateDateColumn } from 'typeorm';

export enum RequestStatus {
  REQUEST_CREATED = 'REQUEST_CREATED',
  SEARCHING_DRIVER = 'SEARCHING_DRIVER',
  VENDOR_ACCEPTED = 'VENDOR_ACCEPTED',
  DRIVER_ASSIGNED = 'DRIVER_ASSIGNED',
  EN_ROUTE = 'EN_ROUTE',
  ARRIVED = 'ARRIVED',
  PATIENT_ONBOARD = 'PATIENT_ONBOARD',
  DESTINATION_REACHED = 'DESTINATION_REACHED',
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

  @Column({ type: 'enum', enum: RequestStatus, default: RequestStatus.REQUEST_CREATED })
  status: RequestStatus;

  @Column({ nullable: true })
  pickupAddress?: string;

  @Column('double precision')
  pickupLat: number;

  @Column('double precision')
  pickupLng: number;

  @Column({ nullable: true })
  dropAddress?: string;

  @Column('double precision')
  dropLat: number;

  @Column('double precision')
  dropLng: number;

  @Column({ nullable: true })
  patientId?: string;

  @Column()
  patientName: string;

  @Column()
  patientPhone: string;

  @Column({ nullable: true })
  notes?: string;

  @Column({ nullable: true })
  priority?: string;

  @Column({ nullable: true, unique: true })
  idempotencyKey?: string;

  @Column({ nullable: true })
  assignedVendorId?: string;

  @Column({ nullable: true })
  vendorBookingRef?: string;

  @Column({ nullable: true })
  vendorDriverRef?: string;

  @Column({ nullable: true })
  vendorDriverName?: string;

  @Column({ nullable: true })
  vendorDriverPhone?: string;

  @Column({ nullable: true })
  vendorVehicleNumber?: string;

  @Column({ nullable: true })
  vendorAmbulanceType?: string;

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
