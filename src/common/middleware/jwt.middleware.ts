import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class JwtMiddleware implements NestMiddleware {
  constructor(private readonly jwtService: JwtService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // TEMPORARY BYPASS: Assign a mock user if no auth header is present
      // @ts-ignore
      req.user = { sub: 'mock-patient-id', role: 'patient' };
      return next();
    }

    const token = authHeader.split(' ')[1];
    try {
      const payload = this.jwtService.verify(token, { secret: process.env.JWT_SECRET || 'changeme' });
      // @ts-ignore
      req.user = payload;
      next();
    } catch (err) {
      // TEMPORARY BYPASS: Assign a mock user if token is invalid or expired
      // @ts-ignore
      req.user = { sub: 'mock-patient-id', role: 'patient' };
      return next();
    }
  }
}
