import { UseGuards, Logger } from '@nestjs/common';
import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WsJwtGuard } from './ws-jwt.guard';
import { AmbulanceRequest } from '../modules/ambulance/entities/ambulance-request.entity';

@UseGuards(WsJwtGuard)
@WebSocketGateway({
  namespace: '/ws',
  cors: { origin: '*' },
  pingInterval: 25000,
  pingTimeout: 60000,
  transports: ['websocket', 'polling'],
})
export class WebsocketGateway implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(WebsocketGateway.name);

  private readonly connectedClients = new Map<string, string>();

  constructor(
    private readonly jwtService: JwtService,
    @InjectRepository(AmbulanceRequest)
    private readonly repo: Repository<AmbulanceRequest>,
  ) {}

  getConnectedClientsCount(): number {
    return this.connectedClients.size;
  }

  afterInit(server: Server) {
    this.logger.log('WebSocket gateway initialized');
    server.use((socket, next) => {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token) {
        socket.data.user = { sub: 'mock-patient-id', role: 'patient' };
        return next();
      }
      try {
        const payload = this.jwtService.verify(token, { secret: process.env.JWT_SECRET || 'changeme' });
        socket.data.user = payload;
        next();
      } catch (err) {
        socket.data.user = { sub: 'mock-patient-id', role: 'patient' };
        next();
      }
    });
  }

  handleConnection(client: Socket) {
    const user = (client as any).data?.user;
    const userId = user ? user.sub || user.id : 'anonymous';
    this.logger.log(`Client connected: [${client.id}] user=${userId}`);
    this.connectedClients.set(client.id, userId);

    // optional: join user room for targeted messages
    if (user && (user.sub || user.id)) client.join(`user:${user.sub || user.id}`);

    // Join global dispatcher operations room if role is authorized
    if (user && (user.role === 'dispatcher' || user.role === 'admin')) {
      client.join('dispatcher-room');
      this.logger.log(`Client [${client.id}] joined dispatcher-room (role=${user.role})`);
    } else if (!user || !user.role) {
      // Anonymous or invalid tokens — disconnect immediately
      this.logger.warn(`Client [${client.id}] rejected: no valid role`);
      client.disconnect(true);
      return;
    }
  }

  handleDisconnect(client: Socket) {
    const userId = this.connectedClients.get(client.id) || 'anonymous';
    this.logger.log(`Client disconnected: [${client.id}] user=${userId}. Cleaning up subscriptions.`);
    this.connectedClients.delete(client.id);
  }

  @SubscribeMessage('subscribe')
  async handleSubscribe(@MessageBody() data: { requestId?: string }, @ConnectedSocket() client: Socket) {
    if (data?.requestId) {
      const user = client.data.user;
      if (!user || !user.sub) return { status: 'error', message: 'Unauthorized' };

      const request = await this.repo.findOne({ where: { id: data.requestId } });
      if (!request) {
        return { status: 'error', message: 'Unauthorized' };
      }

      client.join(`request:${data.requestId}`);
      return { status: 'subscribed', requestId: data.requestId };
    }
    return { status: 'ok' };
  }

  // Emitters used by services to broadcast events
  emitNewRequest(request: any) {
    this.server.to(`dispatcher-room`).emit('request_created', request);
  }

  emitAmbulanceAssigned(requestId: string, payload: any) {
    this.server.to(`request:${requestId}`).emit('driver_assigned', payload);
    if (payload?.patientId) this.server.to(`user:${payload.patientId}`).emit('driver_assigned', payload);
    this.server.to('dispatcher-room').emit('driver_assigned', { requestId, ...payload });
  }

  emitLocationUpdated(requestId: string, position: any) {
    this.server.to(`request:${requestId}`).emit('tracking_updated', position);
    this.server.to('dispatcher-room').emit('tracking_updated', { requestId, ...position });
  }

  emitEtaUpdated(requestId: string, etaSeconds: number) {
    this.server.to(`request:${requestId}`).emit('eta_updated', { etaSeconds });
    this.server.to('dispatcher-room').emit('eta_updated', { requestId, etaSeconds });
  }

  emitRideCompleted(requestId: string, payload: any) {
    this.server.to(`request:${requestId}`).emit('request_completed', payload);
    if (payload?.patientId) this.server.to(`user:${payload.patientId}`).emit('request_completed', payload);
    this.server.to('dispatcher-room').emit('request_completed', { requestId, ...payload });
  }

  emitStatusUpdated(requestId: string, status: string, payload?: any) {
    this.server.to(`request:${requestId}`).emit('status_updated', { requestId, status, ...payload });
    this.server.to('dispatcher-room').emit('status_updated', { requestId, status, ...payload });

    // Also emit specific event names in lowercase
    const eventMap: Record<string, string> = {
      PENDING: 'request_created',
      REQUEST_CREATED: 'request_created',
      DRIVER_ASSIGNED: 'driver_assigned',
      EN_ROUTE: 'request_updated',
      ARRIVED: 'request_updated',
      PATIENT_ONBOARD: 'request_updated',
      COMPLETED: 'request_completed',
      CANCELLED: 'request_updated',
      FAILED: 'request_updated',
    };
    const mappedEvent = eventMap[status];
    if (mappedEvent) {
      this.server.to(`request:${requestId}`).emit(mappedEvent, { requestId, status, ...payload });
      this.server.to('dispatcher-room').emit(mappedEvent, { requestId, status, ...payload });
    }
  }
}

