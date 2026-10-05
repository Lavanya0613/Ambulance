package com.callhealth.ambulance.service;

import com.callhealth.ambulance.common.exception.ResourceNotFoundException;
import com.callhealth.ambulance.dto.AdminDashboardResponse;
import com.callhealth.ambulance.dto.PaginatedResponse;
import com.callhealth.ambulance.dto.PaginationMeta;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.SystemAuditLog;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.SystemAuditLogRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class AdminService {

    private final AmbulanceRequestRepository requestRepository;
    private final SystemAuditLogRepository auditLogRepository;

    public AdminService(
            AmbulanceRequestRepository requestRepository,
            SystemAuditLogRepository auditLogRepository
    ) {
        this.requestRepository = requestRepository;
        this.auditLogRepository = auditLogRepository;
    }

    public AdminDashboardResponse getDashboard() {
        long total = requestRepository.count();
        long pending = requestRepository.countByStatus(AmbulanceRequestStatus.REQUEST_RECEIVED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.SEARCHING_DRIVER);
        long assigned = requestRepository.countByStatus(AmbulanceRequestStatus.DRIVER_ASSIGNED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.VENDOR_ACCEPTED);
        long inProgress = requestRepository.countByStatus(AmbulanceRequestStatus.EN_ROUTE)
                + requestRepository.countByStatus(AmbulanceRequestStatus.ARRIVED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.TRIP_STARTED);
        long completed = requestRepository.countByStatus(AmbulanceRequestStatus.COMPLETED);
        long cancelled = requestRepository.countByStatus(AmbulanceRequestStatus.CANCELLED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.FAILED);

        return new AdminDashboardResponse(total, pending, assigned, inProgress, completed, cancelled);
    }

    public PaginatedResponse<AmbulanceRequest> getRequests(int page, int limit) {
        int pageNumber = Math.max(1, page);
        int pageSize = Math.max(1, limit);
        PageRequest pageable = PageRequest.of(pageNumber - 1, pageSize, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<AmbulanceRequest> requestPage = requestRepository.findAll(pageable);
        PaginationMeta meta = new PaginationMeta(
                requestPage.getTotalElements(),
                pageNumber,
                pageSize,
                requestPage.getTotalPages()
        );

        return new PaginatedResponse<>(requestPage.getContent(), meta);
    }

    public AmbulanceRequest getRequestDetails(UUID id) {
        return requestRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance request not found: " + id));
    }

    public PaginatedResponse<SystemAuditLog> getAuditLogs(int page, int limit) {
        int pageNumber = Math.max(1, page);
        int pageSize = Math.max(1, limit);
        PageRequest pageable = PageRequest.of(pageNumber - 1, pageSize, Sort.by(Sort.Direction.DESC, "timestamp"));

        Page<SystemAuditLog> auditPage = auditLogRepository.findAll(pageable);
        PaginationMeta meta = new PaginationMeta(
                auditPage.getTotalElements(),
                pageNumber,
                pageSize,
                auditPage.getTotalPages()
        );

        return new PaginatedResponse<>(auditPage.getContent(), meta);
    }
}
