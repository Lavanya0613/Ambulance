import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';
import { QueryFailedError } from 'typeorm';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    
    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let errorType = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const responseBody: any = exception.getResponse();
      
      if (typeof responseBody === 'object' && responseBody !== null) {
        message = responseBody.message || exception.message;
        errorType = responseBody.error || exception.name;
      } else {
        message = responseBody || exception.message;
        errorType = exception.name;
      }
    } else if (exception instanceof QueryFailedError) {
      status = HttpStatus.BAD_REQUEST; // Or 409 depending on logic
      message = exception.message;
      errorType = 'Database Error';
    } else if (exception instanceof Error) {
      message = exception.message;
      errorType = exception.name;
    }

    const requestId = request.headers['x-request-id'] || 'UNKNOWN';

    const errorResponse = {
      statusCode: status,
      message,
      error: errorType,
      timestamp: new Date().toISOString(),
      path: request.url,
      requestId,
    };

    if (status === HttpStatus.INTERNAL_SERVER_ERROR) {
      this.logger.error(`[REQ: ${requestId}] Unhandled Exception: ${(exception as Error).message}`, (exception as Error).stack);
    } else {
      this.logger.warn(`[REQ: ${requestId}] Client Error: ${JSON.stringify(errorResponse.message)}`);
    }

    response.status(status).json(errorResponse);
  }
}
