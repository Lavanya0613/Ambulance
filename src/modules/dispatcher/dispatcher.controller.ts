import { Controller, Get, Post, Param, Body, UseGuards, Query, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { Request } from 'express';
import { DispatcherService } from './dispatcher.service';
import { DispatcherDashboardService } from './dispatcher-dashboard.service';
import { QueueMonitorService } from './queue-monitor.service';
import { AuditService } from '../audit/audit.service';
import { ListRequestsDto } from '../ambulance/dto/list-requests.dto';
import { CancelAmbulanceDto } from '../ambulance/dto/cancel-ambulance.dto';
import { DashboardResponseDto } from './dto/dashboard-response.dto';

@ApiTags('Dispatcher')
@Controller('dispatcher')
export class DispatcherController {
  constructor(
    private readonly dispatcherService: DispatcherService,
    private readonly dashboardService: DispatcherDashboardService,
    private readonly queueService: QueueMonitorService,
    private readonly auditService: AuditService,
  ) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get summary counts of request statuses' })
  @ApiResponse({ status: 200, type: DashboardResponseDto })
  async getDashboardSummary(): Promise<DashboardResponseDto> {
    return this.dashboardService.getDashboardSummary();
  }

  @Get('queues')
  @ApiOperation({ summary: 'Monitor BullMQ health and queue depth' })
  @ApiResponse({ status: 200, description: 'Queue monitoring telemetry' })
  async getQueueHealth() {
    return this.queueService.getQueueHealth();
  }

  @Get('requests')
  @ApiOperation({ summary: 'List all requests (supports filtering and pagination)' })
  @ApiResponse({ status: 200, description: 'Paginated list of active requests' })
  async listRequests(@Query() query: ListRequestsDto) {
    return this.dispatcherService.listRequests(query);
  }

  @Get('requests/:id')
  @ApiOperation({ summary: 'Get complete request information including tracking' })
  @ApiResponse({ status: 200, description: 'Complete Request details' })
  async getRequestDetails(@Param('id') id: string) {
    return this.dispatcherService.getRequestDetails(id);
  }



  @Post('requests/:id/cancel')
  @ApiOperation({ summary: 'Cancel a request' })
  @ApiResponse({ status: 200, description: 'Request cancelled' })
  async cancelRequest(@Param('id') id: string, @Body() dto: CancelAmbulanceDto) {
    return this.dispatcherService.cancelRequest(id, dto, 'dispatcher-system');
  }

  @Post('requests/:id/complete')
  @ApiOperation({ summary: 'Mark a request as completed' })
  @ApiResponse({ status: 200, description: 'Request marked as completed' })
  async completeRequest(@Param('id') id: string) {
    return this.dispatcherService.completeRequest(id);
  }
}
