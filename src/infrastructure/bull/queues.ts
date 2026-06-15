import { Queue } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis(process.env.REDIS_URL || 'redis://localhost:6379');

export const dispatchCommandQueue = new Queue('dispatch.command', { connection });
export const vendorCreateBookingQueue = new Queue('vendor.call.create_booking', { connection });
export const vendorCancelQueue = new Queue('vendor.call.cancel_booking', { connection });
export const vendorDLQ = new Queue('vendor.dlq', { connection });

export default connection;
