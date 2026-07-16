import { DataSource } from 'typeorm';
import { typeOrmConfig } from '../config/typeorm.config';

async function run() {
  const ds = new DataSource(typeOrmConfig() as any);
  await ds.initialize();
  const res = await ds.query('SELECT id FROM ambulance_requests ORDER BY "createdAt" DESC LIMIT 1');
  console.log('LATEST_ID:', res[0]?.id);
  await ds.destroy();
}
run();
