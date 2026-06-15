import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class LoggerService {
  private readonly logger = new Logger('CallHealth');

  log(message: string, meta?: any) {
    this.logger.log(message, JSON.stringify(meta || {}));
  }
  error(message: string, trace?: string, meta?: any) {
    this.logger.error(message, JSON.stringify(meta || {}), trace);
  }
  warn(message: string, meta?: any) {
    this.logger.warn(message, JSON.stringify(meta || {}));
  }
  debug(message: string, meta?: any) {
    this.logger.debug(message, JSON.stringify(meta || {}));
  }
}
