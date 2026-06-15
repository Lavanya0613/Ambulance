import { MigrationInterface, QueryRunner } from 'typeorm';

export class InitSchema1660000000000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS users (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email varchar(255) NOT NULL UNIQUE,
        password_hash varchar(512) NOT NULL,
        full_name varchar(255),
        roles text,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS ambulance_requests (
        id uuid PRIMARY KEY,
        request_number varchar(255) NOT NULL UNIQUE,
        status varchar(32) NOT NULL,
        pickup_lat double precision NOT NULL,
        pickup_lng double precision NOT NULL,
        drop_lat double precision NOT NULL,
        drop_lng double precision NOT NULL,
        patient_name varchar(255) NOT NULL,
        patient_phone varchar(64) NOT NULL,
        notes text,
        priority varchar(32),
        idempotency_key varchar(255),
        assigned_vendor_id varchar(255),
        vendor_booking_ref varchar(255),
        assigned_driver jsonb,
        eta_seconds integer,
        cancel_reason varchar(255),
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_ambulance_requests_status ON ambulance_requests (status);
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS tracking_positions (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        vendor_event_id varchar(255) NOT NULL UNIQUE,
        lat double precision NOT NULL,
        lng double precision NOT NULL,
        speed_kmph double precision,
        heading_deg double precision,
        captured_at timestamptz NOT NULL,
        request_id uuid REFERENCES ambulance_requests(id) ON DELETE CASCADE
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_tracking_positions_request_id ON tracking_positions (request_id);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS tracking_positions;`);
    await queryRunner.query(`DROP TABLE IF EXISTS ambulance_requests;`);
    await queryRunner.query(`DROP TABLE IF EXISTS users;`);
  }
}
