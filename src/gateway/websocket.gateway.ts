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
import { WsJwtGuard } from './ws-jwt.guard';

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

  afterInit(server: Server) {
    this.logger.log('WebSocket gateway initialized');
  }

  handleConnection(client: Socket) {
    const user = (client as any).data?.user;
    this.logger.log(`Client connected: ${client.id} user=${user ? user.sub || user.id : 'anonymous'}`);
    // optional: join user room for targeted messages
    if (user && (user.sub || user.id)) client.join(`user:${user.sub || user.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('subscribe')
  handleSubscribe(@MessageBody() data: { requestId?: string }, @ConnectedSocket() client: Socket) {
    if (data?.requestId) {
      client.join(`request:${data.requestId}`);
      return { status: 'subscribed', requestId: data.requestId };
    }
    return { status: 'ok' };
  }

  // Emitters used by services to broadcast events
  emitAmbulanceAssigned(requestId: string, payload: any) {
    this.server.to(`request:${requestId}`).emit('ambulance_assigned', payload);
    if (payload?.patientId) this.server.to(`user:${payload.patientId}`).emit('ambulance_assigned', payload);
  }

  emitLocationUpdated(requestId: string, position: any) {
    this.server.to(`request:${requestId}`).emit('location_updated', position);
  }

  emitEtaUpdated(requestId: string, etaSeconds: number) {
    this.server.to(`request:${requestId}`).emit('eta_updated', { etaSeconds });
  }

  emitRideCompleted(requestId: string, payload: any) {
    this.server.to(`request:${requestId}`).emit('ride_completed', payload);
    if (payload?.patientId) this.server.to(`user:${payload.patientId}`).emit('ride_completed', payload);
  }

  emitStatusUpdated(requestId: string, status: string, payload?: any) {
    this.server.to(`request:${requestId}`).emit('status_updated', { requestId, status, ...payload });

    // Also emit specific event names in lowercase
    const eventMap: Record<string, string> = {
      PENDING: 'request_created',
      ASSIGNED: 'driver_assigned',
      EN_ROUTE: 'en_route',
      ARRIVED: 'arrived',
      IN_PROGRESS: 'in_progress',
      COMPLETED: 'ride_completed',
      CANCELLED: 'cancelled',
      FAILED: 'failed',
    };
    const mappedEvent = eventMap[status];
    if (mappedEvent) {
      this.server.to(`request:${requestId}`).emit(mappedEvent, { requestId, status, ...payload });
    }
  }
}

