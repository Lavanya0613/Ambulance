import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(RolesGuard)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @Roles('admin')
  @ApiOperation({ summary: 'Get overall metrics for the admin dashboard' })
  @ApiResponse({ status: 200, description: 'Dashboard metrics returned successfully.' })
  async getDashboard() {
    return this.adminService.getDashboard();
  }

  @Get('requests')
  @Roles('admin')
  @ApiOperation({ summary: 'Get a paginated list of ambulance requests with optional filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, type: String })
  @ApiQuery({ name: 'date', required: false, type: String, description: 'Format: YYYY-MM-DD' })
  @ApiQuery({ name: 'search', required: false, type: String, description: 'Search by patient name or request number' })
  @ApiResponse({ status: 200, description: 'List of requests returned successfully.' })
  async getRequests(@Query() query: any) {
    return this.adminService.getRequests(query);
  }

  @Get('requests/:id')
  @Roles('admin')
  @ApiOperation({ summary: 'Get detailed information for a specific ambulance request including tracking history' })
  @ApiResponse({ status: 200, description: 'Request details returned successfully.' })
  @ApiResponse({ status: 404, description: 'Request not found.' })
  async getRequestDetails(@Param('id') id: string) {
    return this.adminService.getRequestDetails(id);
  }

  @Get('audit-logs')
  @Roles('admin')
  @ApiOperation({ summary: 'Get a paginated list of system audit logs' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'action', required: false, type: String })
  @ApiQuery({ name: 'request', required: false, type: String, description: 'Request ID to filter by' })
  @ApiQuery({ name: 'date', required: false, type: String, description: 'Format: YYYY-MM-DD' })
  @ApiResponse({ status: 200, description: 'List of audit logs returned successfully.' })
  async getAuditLogs(@Query() query: any) {
    return this.adminService.getAuditLogs(query);
  }

  @Get('system-status')
  @Roles('admin')
  @ApiOperation({ summary: 'Get overall system health and monitoring metrics' })
  @ApiResponse({ status: 200, description: 'System status returned successfully.' })
  async getSystemStatus() {
    return this.adminService.getSystemStatus();
  }

  @Get('analytics')
  @Roles('admin')
  @ApiOperation({ summary: 'Get analytics and reporting metrics' })
  @ApiResponse({ status: 200, description: 'Analytics data returned successfully.' })
  async getAnalytics() {
    return this.adminService.getAnalytics();
  }
}
