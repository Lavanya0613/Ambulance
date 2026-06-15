import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { WebsocketGateway } from './websocket.gateway';
import { WsJwtGuard } from './ws-jwt.guard';

@Module({
  imports: [JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' })],
  providers: [WebsocketGateway, WsJwtGuard],
  exports: [WebsocketGateway],
})
export class WebsocketModule {}
