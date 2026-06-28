import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  Req,
  Query,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { ThrottlerGuard } from '@nestjs/throttler';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AmbulanceService } from './ambulance.service';
import { RequestAmbulanceDto } from './dto/request-ambulance.dto';
import { RequestAmbulanceResponseDto } from './dto/request-ambulance-response.dto';
import { CancelAmbulanceDto } from './dto/cancel-ambulance.dto';
import { CancelAmbulanceResponseDto } from './dto/cancel-ambulance-response.dto';
import { TrackingSnapshotDto } from './dto/tracking-snapshot.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

import { ListRequestsDto } from './dto/list-requests.dto';

@ApiTags('Patient')
@ApiBearerAuth()
@UseGuards(RolesGuard)
@Controller('patient/requests')
export class AmbulanceController {
  constructor(private readonly ambulanceService: AmbulanceService) {}

  @Get()
  @Roles('patient', 'dispatcher', 'admin')
  @ApiOperation({ summary: 'List all ambulance requests' })
  async listRequests(@Query() query: ListRequestsDto, @Req() req: Request) {
    const user = (req as any).user;
    return this.ambulanceService.listRequests(user.sub, user.role, query);
  }

  @Post()
  @Roles('patient', 'dispatcher', 'admin')
  @UseGuards(ThrottlerGuard)
  @ApiOperation({ summary: 'Request Ambulance' })
  @ApiResponse({ status: 201, description: 'Ambulance request created', type: RequestAmbulanceResponseDto })
  async requestAmbulance(@Body() dto: RequestAmbulanceDto, @Req() req: Request): Promise<RequestAmbulanceResponseDto> {
    const patientId = (req as any).user?.sub;
    const result = await this.ambulanceService.createRequest(dto, patientId);
    return result;
  }

  @Post(':requestId/cancel')
  @Roles('patient', 'dispatcher', 'admin')
  @UseGuards(ThrottlerGuard)
  @ApiOperation({ summary: 'Cancel Ambulance' })
  @ApiResponse({ status: 200, description: 'Cancellation accepted', type: CancelAmbulanceResponseDto })
  async cancelAmbulance(
    @Param('requestId') requestId: string,
    @Body() dto: CancelAmbulanceDto,
    @Req() req: Request,
  ): Promise<CancelAmbulanceResponseDto> {
    const user = (req as any).user;
    const cancelled = await this.ambulanceService.cancelRequest(requestId, dto, user.sub, user.role);
    if (!cancelled) throw new NotFoundException('Request not found');
    return cancelled;
  }

  @Get(':requestId/track')
  @Roles('patient', 'dispatcher', 'admin')
  @UseGuards(ThrottlerGuard)
  @ApiOperation({ summary: 'Track Ambulance' })
  @ApiResponse({ status: 200, description: 'Current tracking snapshot', type: TrackingSnapshotDto })
  async trackAmbulance(@Param('requestId') requestId: string, @Req() req: Request): Promise<TrackingSnapshotDto> {
    const user = (req as any).user;
    const snapshot = await this.ambulanceService.getTrackingSnapshot(requestId, user.sub, user.role);
    if (!snapshot) throw new NotFoundException('Request not found');
    return snapshot;
  }
  @Get(':requestId/audit')
  @Roles('patient', 'dispatcher', 'admin')
  @ApiOperation({ summary: 'Get Audit History' })
  @ApiResponse({ status: 200, description: 'List of audit events' })
  async getAuditHistory(@Param('requestId') requestId: string, @Req() req: Request) {
    const user = (req as any).user;
    return this.ambulanceService.getAuditHistory(requestId, user.sub, user.role);
  }

}
