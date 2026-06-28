import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { v4 as uuidv4 } from 'uuid';
import { Request, Response } from 'express';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const ctx = context.switchToHttp();
    const request = ctx.getRequest<Request>();
    const response = ctx.getResponse<Response>();

    const requestId = request.headers['x-request-id'] || uuidv4();
    request.headers['x-request-id'] = requestId;
    response.setHeader('x-request-id', requestId);

    const { method, originalUrl, ip } = request;
    const userAgent = request.get('user-agent') || '';
    
    const now = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const delay = Date.now() - now;
          this.logger.log(`[REQ: ${requestId}] ${method} ${originalUrl} ${response.statusCode} - ${delay}ms - ${ip} ${userAgent}`);
        },
        error: (error) => {
          const delay = Date.now() - now;
          const status = error?.status || 500;
          this.logger.error(`[REQ: ${requestId}] ${method} ${originalUrl} ${status} - ${delay}ms - ${ip} ${userAgent} - ERROR: ${error.message}`);
        }
      }),
    );
  }
}
