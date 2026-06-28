import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { DashboardService } from './dashboard.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Dashboard')
@ApiBearerAuth()
@UseGuards(RolesGuard)
@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('active-requests')
  @Roles('dispatcher', 'admin')
  @ApiOperation({ summary: 'Get all active ambulance requests' })
  @ApiResponse({ status: 200, description: 'List of active requests' })
  async getActiveRequests() {
    return this.dashboardService.getActiveRequests();
  }

  @Get('system-health')
  @Roles('dispatcher', 'admin')
  @ApiOperation({ summary: 'Get system health metrics' })
  @ApiResponse({ status: 200, description: 'Health metrics including DB status and uptime' })
  async getSystemHealth() {
    return this.dashboardService.getSystemHealth();
  }

  @Get('queue-status')
  @Roles('dispatcher', 'admin')
  @ApiOperation({ summary: 'Get queue processing status' })
  @ApiResponse({ status: 200, description: 'Queue metrics (waiting, active, delayed, etc.)' })
  async getQueueStatus() {
    return this.dashboardService.getQueueStatus();
  }


  @Get('statistics')
  @Roles('dispatcher', 'admin')
  @ApiOperation({ summary: 'Get aggregate booking statistics' })
  @ApiResponse({ status: 200, description: 'Stats: total bookings, completion rate, avg ETA' })
  async getStatistics() {
    return this.dashboardService.getStatistics();
  }
}
