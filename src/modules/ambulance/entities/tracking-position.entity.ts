import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { AmbulanceRequest } from './ambulance-request.entity';

@Entity({ name: 'tracking_positions' })
export class TrackingPosition {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  vendorEventId: string;

  @Column('double precision')
  lat: number;

  @Column('double precision')
  lng: number;

  @Column({ type: 'double precision', nullable: true })
  speedKmph?: number;

  @Column({ type: 'double precision', nullable: true })
  headingDeg?: number;

  @Column({ type: 'timestamptz' })
  capturedAt: Date;

  @ManyToOne(() => AmbulanceRequest, (r) => (r as any).positions, { onDelete: 'CASCADE' })
  request: AmbulanceRequest;
}
