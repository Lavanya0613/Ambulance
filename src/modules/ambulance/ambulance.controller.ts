import {
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AmbulanceService } from './ambulance.service';
import { RequestAmbulanceDto } from './dto/request-ambulance.dto';
import { RequestAmbulanceResponseDto } from './dto/request-ambulance-response.dto';
import { CancelAmbulanceDto } from './dto/cancel-ambulance.dto';
import { CancelAmbulanceResponseDto } from './dto/cancel-ambulance-response.dto';
import { TrackingSnapshotDto } from './dto/tracking-snapshot.dto';

@ApiTags('Patient')
@ApiBearerAuth()
@Controller('patient/requests')
export class AmbulanceController {
  constructor(private readonly ambulanceService: AmbulanceService) {}

  @Get()
  @ApiOperation({ summary: 'List all ambulance requests' })
  async listRequests() {
    return this.ambulanceService.listRequests();
  }

  @Post()
  @ApiOperation({ summary: 'Request Ambulance' })
  @ApiResponse({ status: 201, description: 'Ambulance request created', type: RequestAmbulanceResponseDto })
  async requestAmbulance(@Body() dto: RequestAmbulanceDto): Promise<RequestAmbulanceResponseDto> {
    const result = await this.ambulanceService.createRequest(dto);
    return result;
  }

  @Post(':requestId/cancel')
  @ApiOperation({ summary: 'Cancel Ambulance' })
  @ApiResponse({ status: 200, description: 'Cancellation accepted', type: CancelAmbulanceResponseDto })
  async cancelAmbulance(
    @Param('requestId') requestId: string,
    @Body() dto: CancelAmbulanceDto,
  ): Promise<CancelAmbulanceResponseDto> {
    const cancelled = await this.ambulanceService.cancelRequest(requestId, dto);
    if (!cancelled) throw new NotFoundException('Request not found');
    return cancelled;
  }

  @Get(':requestId/track')
  @ApiOperation({ summary: 'Track Ambulance' })
  @ApiResponse({ status: 200, description: 'Current tracking snapshot', type: TrackingSnapshotDto })
  async trackAmbulance(@Param('requestId') requestId: string): Promise<TrackingSnapshotDto> {
    const snapshot = await this.ambulanceService.getTrackingSnapshot(requestId);
    if (!snapshot) throw new NotFoundException('Request not found');
    return snapshot;
  }
}
