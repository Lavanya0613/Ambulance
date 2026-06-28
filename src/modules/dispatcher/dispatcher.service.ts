import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AmbulanceRequest, RequestStatus } from '../ambulance/entities/ambulance-request.entity';
import { AmbulanceService } from '../ambulance/ambulance.service';
import { AuditService } from '../audit/audit.service';
import { WebsocketGateway } from '../../gateway/websocket.gateway';
import { ListRequestsDto } from '../ambulance/dto/list-requests.dto';
import { CancelAmbulanceDto } from '../ambulance/dto/cancel-ambulance.dto';

@Injectable()
export class DispatcherService {
  constructor(
    @InjectRepository(AmbulanceRequest)
    private readonly requestRepo: Repository<AmbulanceRequest>,
    private readonly ambulanceService: AmbulanceService,
    private readonly auditService: AuditService,
    private readonly websocketGateway: WebsocketGateway,
  ) {}

  async listRequests(query: ListRequestsDto) {
    // Reuses the ambulance service logic
    return this.ambulanceService.listRequests('', 'dispatcher', query);
  }

  async getRequestDetails(id: string) {
    return this.ambulanceService.getTrackingSnapshot(id, '', 'dispatcher');
  }


  async cancelRequest(id: string, dto: CancelAmbulanceDto, userId: string) {
    return this.ambulanceService.cancelRequest(id, dto, userId, 'dispatcher');
  }

  async completeRequest(id: string) {
    const request = await this.requestRepo.findOne({ 
      where: { id },
      relations: ['assignedDriver']
    });
    if (!request) {
      throw new NotFoundException('Request not found');
    }

    const prevStatus = request.status;
    request.status = RequestStatus.COMPLETED;
    request.updatedAt = new Date();
    await this.requestRepo.save(request);

    await this.auditService.logAction(
      'Trip Completed',
      'dispatcher',
      request.id,
      'AmbulanceRequest',
      prevStatus,
      request.status
    );

    this.websocketGateway.emitStatusUpdated(request.id, request.status);
    this.websocketGateway.emitRideCompleted(request.id, {
      requestId: request.id,
      patientId: request.patientId,
      status: request.status,
      completedAt: request.updatedAt,
    });

    return {
      requestId: request.id,
      status: request.status,
      message: 'Request completed successfully',
      updatedAt: request.updatedAt,
    };
  }
}
