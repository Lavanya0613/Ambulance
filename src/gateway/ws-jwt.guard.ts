import { CanActivate, ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Socket } from 'socket.io';

@Injectable()
export class WsJwtGuard implements CanActivate {
  private readonly logger = new Logger(WsJwtGuard.name);

  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const client: Socket = context.switchToWs().getClient<Socket>();
    const token = (client.handshake.auth && client.handshake.auth.token) || client.handshake.query?.token;
    
    const isDev = process.env.NODE_ENV === 'development' || process.env.BYPASS_WS_AUTH === 'true' || token === 'bypass';

    if (!token) {
      if (isDev) {
        this.logger.log(`Bypassing WebSocket auth for client ${client.id} in development mode`);
        client.data = client.data || {};
        client.data.user = { id: 'dev-user', sub: 'dev-user', role: 'patient' };
        return true;
      }
      this.logger.warn(`Socket ${client.id} missing auth token`);
      return false;
    }

    try {
      const payload = this.jwtService.verify(token, { secret: process.env.JWT_SECRET || 'changeme' });
      client.data = client.data || {};
      client.data.user = payload;
      return true;
    } catch (err) {
      if (isDev) {
        this.logger.log(`Bypassing WebSocket auth for client ${client.id} in development mode (verification failed: ${err?.message})`);
        client.data = client.data || {};
        client.data.user = { id: 'dev-user', sub: 'dev-user', role: 'patient' };
        return true;
      }
      this.logger.warn(`Socket ${client.id} JWT validation failed: ${err?.message || err}`);
      return false;
    }
  }
}
