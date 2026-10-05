package com.callhealth.ambulance.service;

import com.callhealth.ambulance.common.exception.ResourceNotFoundException;
import com.callhealth.ambulance.dto.DispatcherDashboardResponse;
import com.callhealth.ambulance.dto.PaginatedResponse;
import com.callhealth.ambulance.dto.PaginationMeta;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class DispatcherService {

    private final AmbulanceRequestRepository requestRepository;
    private final com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway;
    private final RedisQueueService redisQueueService;

    public DispatcherService(
            AmbulanceRequestRepository requestRepository,
            com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway,
            RedisQueueService redisQueueService
    ) {
        this.requestRepository = requestRepository;
        this.webSocketGateway = webSocketGateway;
        this.redisQueueService = redisQueueService;
    }

    public DispatcherDashboardResponse getDashboardSummary() {
        long total = requestRepository.count();
        long pending = requestRepository.countByStatus(AmbulanceRequestStatus.REQUEST_RECEIVED) 
                + requestRepository.countByStatus(AmbulanceRequestStatus.SEARCHING_DRIVER);
        long assigned = requestRepository.countByStatus(AmbulanceRequestStatus.DRIVER_ASSIGNED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.VENDOR_ACCEPTED);
        long enroute = requestRepository.countByStatus(AmbulanceRequestStatus.EN_ROUTE)
                + requestRepository.countByStatus(AmbulanceRequestStatus.ARRIVED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.TRIP_STARTED);
        long completed = requestRepository.countByStatus(AmbulanceRequestStatus.COMPLETED);
        long cancelled = requestRepository.countByStatus(AmbulanceRequestStatus.CANCELLED)
                + requestRepository.countByStatus(AmbulanceRequestStatus.FAILED);

        return new DispatcherDashboardResponse(
                total,
                pending,
                assigned,
                enroute,
                completed,
                cancelled,
                4, // driversAvailable
                2, // driversBusy
                0, // queueSize
                15, // averageEta
                25  // averageTripTime
        );
    }

    public PaginatedResponse<AmbulanceRequest> listRequests(int page, int limit, AmbulanceRequestStatus status) {
        int pageNumber = Math.max(1, page);
        int pageSize = Math.max(1, limit);
        PageRequest pageable = PageRequest.of(pageNumber - 1, pageSize, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<AmbulanceRequest> requestPage;
        if (status != null) {
            List<AmbulanceRequest> filtered = requestRepository.findByStatusIn(List.of(status));
            return new PaginatedResponse<>(filtered, new PaginationMeta(filtered.size(), pageNumber, pageSize, 1));
        } else {
            requestPage = requestRepository.findAll(pageable);
        }

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

    @Transactional
    public AmbulanceRequest acceptRequest(UUID id) {
        AmbulanceRequest request = getRequestDetails(id);
        request.setStatus(AmbulanceRequestStatus.VENDOR_ACCEPTED);
        AmbulanceRequest saved = requestRepository.save(request);
        webSocketGateway.emitStatusUpdated(id.toString(), "VENDOR_ACCEPTED", java.util.Map.of(
                "requestId", id.toString(),
                "status", "VENDOR_ACCEPTED"
        ));
        return saved;
    }

    @Transactional
    public AmbulanceRequest rejectRequest(UUID id) {
        AmbulanceRequest request = getRequestDetails(id);
        request.setStatus(AmbulanceRequestStatus.CANCELLED);
        request.setCancelReason("Declined by Vendor");
        AmbulanceRequest saved = requestRepository.save(request);
        webSocketGateway.emitStatusUpdated(id.toString(), "CANCELLED", java.util.Map.of(
                "requestId", id.toString(),
                "status", "CANCELLED",
                "reason", "Declined by Vendor"
        ));
        return saved;
    }

    @Transactional
    public AmbulanceRequest assignDriver(UUID id, String driverId, String vehicleId, Integer etaSeconds) {
        AmbulanceRequest request = getRequestDetails(id);
        request.setStatus(AmbulanceRequestStatus.DRIVER_ASSIGNED);
        request.setVendorDriverRef(driverId != null ? driverId : "drv-001");
        request.setVendorDriverName("Rajesh Kumar");
        request.setVendorDriverPhone("+919876543210");
        request.setVendorVehicleNumber(vehicleId != null ? vehicleId : "KA-01-EA-1234");
        request.setVendorAmbulanceType("ICU Advanced");
        if (etaSeconds != null) request.setEtaSeconds(etaSeconds);
        AmbulanceRequest saved = requestRepository.save(request);

        webSocketGateway.emitAmbulanceAssigned(id.toString(), java.util.Map.of(
                "requestId", id.toString(),
                "driverName", request.getVendorDriverName(),
                "driverPhone", request.getVendorDriverPhone(),
                "vehicleNumber", request.getVendorVehicleNumber(),
                "ambulanceType", request.getVendorAmbulanceType(),
                "etaSeconds", request.getEtaSeconds() != null ? request.getEtaSeconds() : 300
        ));
        webSocketGateway.emitStatusUpdated(id.toString(), "DRIVER_ASSIGNED", java.util.Map.of(
                "requestId", id.toString(),
                "status", "DRIVER_ASSIGNED",
                "driverName", request.getVendorDriverName(),
                "vehicleNumber", request.getVendorVehicleNumber()
        ));

        // Enqueue tracking job into Redis tracking queue to start simulation movement
        PollTrackingPayload trackingPayload = new PollTrackingPayload(
                id.toString(),
                request.getAssignedVendorId() != null ? request.getAssignedVendorId() : "vendor-01",
                request.getVendorBookingRef() != null ? request.getVendorBookingRef() : ("VND_" + id.toString().substring(0, 8)),
                null
        );
        redisQueueService.enqueue(
                QueueConstants.TRACKING_QUEUE,
                "poll-tracking",
                trackingPayload,
                id.toString() + "-track",
                500,
                3,
                500
        );

        return saved;
    }

    @Transactional
    public AmbulanceRequest updateStatus(UUID id, AmbulanceRequestStatus status) {
        AmbulanceRequest request = getRequestDetails(id);
        request.setStatus(status);
        AmbulanceRequest saved = requestRepository.save(request);
        webSocketGateway.emitStatusUpdated(id.toString(), status.name(), java.util.Map.of(
                "requestId", id.toString(),
                "status", status.name()
        ));
        return saved;
    }

    public void updateLocation(UUID id, double lat, double lng, double speed, double heading) {
        webSocketGateway.emitLocationUpdated(id.toString(), java.util.Map.of(
                "requestId", id.toString(),
                "lat", lat,
                "lng", lng,
                "speedKmph", speed,
                "headingDeg", heading
        ));
    }
}
