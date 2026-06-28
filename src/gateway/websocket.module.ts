import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebsocketGateway } from './websocket.gateway';
import { WsJwtGuard } from './ws-jwt.guard';
import { AmbulanceRequest } from '../modules/ambulance/entities/ambulance-request.entity';

@Module({
  imports: [
    JwtModule.register({ secret: process.env.JWT_SECRET || 'changeme' }),
    TypeOrmModule.forFeature([AmbulanceRequest])
  ],
  providers: [WebsocketGateway, WsJwtGuard],
  exports: [WebsocketGateway],
})
export class WebsocketModule {}
