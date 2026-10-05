package com.callhealth.ambulance.service;

import com.callhealth.ambulance.common.exception.BadRequestException;
import com.callhealth.ambulance.common.exception.ResourceNotFoundException;
import com.callhealth.ambulance.dto.*;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.PatientWallet;
import com.callhealth.ambulance.model.entity.SystemAuditLog;
import com.callhealth.ambulance.model.entity.TrackingPosition;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.model.enums.DriverStatus;
import com.callhealth.ambulance.model.entity.PaymentTransaction;
import com.callhealth.ambulance.model.enums.PaymentMethod;
import com.callhealth.ambulance.model.enums.PaymentStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.DriverRepository;
import com.callhealth.ambulance.repository.PatientWalletRepository;
import com.callhealth.ambulance.repository.PaymentTransactionRepository;
import com.callhealth.ambulance.repository.SystemAuditLogRepository;
import com.callhealth.ambulance.repository.TrackingPositionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDateTime;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.CreateBookingPayload;
import com.callhealth.ambulance.queue.service.RedisQueueService;

import java.util.Optional;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class PatientRequestService {

    private static final Logger log = LoggerFactory.getLogger(PatientRequestService.class);

    private final AmbulanceRequestRepository requestRepository;
    private final TrackingPositionRepository positionRepository;
    private final PatientWalletRepository walletRepository;
    private final SystemAuditLogRepository auditLogRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final DriverRepository driverRepository;
    private final RedisQueueService queueService;
    private final com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway;

    public PatientRequestService(
            AmbulanceRequestRepository requestRepository,
            TrackingPositionRepository positionRepository,
            PatientWalletRepository walletRepository,
            SystemAuditLogRepository auditLogRepository,
            PaymentTransactionRepository paymentTransactionRepository,
            DriverRepository driverRepository,
            RedisQueueService queueService,
            com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway
    ) {
        this.requestRepository = requestRepository;
        this.positionRepository = positionRepository;
        this.walletRepository = walletRepository;
        this.auditLogRepository = auditLogRepository;
        this.paymentTransactionRepository = paymentTransactionRepository;
        this.driverRepository = driverRepository;
        this.queueService = queueService;
        this.webSocketGateway = webSocketGateway;
    }

    @Transactional
    public RequestAmbulanceResponse createRequest(RequestAmbulanceRequest dto, String patientId) {
        String effectivePatientId = (patientId == null || patientId.isBlank()) ? "demo-patient-uuid" : patientId;

        // 1. Idempotency Check
        if (dto.idempotencyKey() != null && !dto.idempotencyKey().isBlank()) {
            Optional<AmbulanceRequest> existingOpt = requestRepository.findByIdempotencyKey(dto.idempotencyKey());
            if (existingOpt.isPresent()) {
                AmbulanceRequest existing = existingOpt.get();
                return new RequestAmbulanceResponse(
                        existing.getId(),
                        existing.getRequestNumber(),
                        existing.getStatus(),
                        existing.getCreatedAt(),
                        existing.getAssignedVendorId(),
                        "Returned existing request based on idempotency key",
                        existing.getBaseFare(),
                        existing.getWalletDiscount(),
                        existing.getTotalPayable(),
                        existing.getPaymentStatus()
                );
            }
        }

        // 2. Base Fare Estimation
        int baseFare = 1250;
        if ("ALS".equalsIgnoreCase(dto.ambulanceType())) {
            baseFare = 2500;
        } else if ("ICU".equalsIgnoreCase(dto.ambulanceType())) {
            baseFare = 3500;
        }

        // 3. Wallet Discount Calculation
        int walletDiscount = 0;
        int totalPayable = baseFare;

        if (Boolean.TRUE.equals(dto.applyWallet())) {
            PatientWallet wallet = walletRepository.findByPatientId(effectivePatientId)
                    .orElseGet(() -> walletRepository.save(new PatientWallet(effectivePatientId, false)));
            
            if (!wallet.isAmbulanceBenefitUsed()) {
                walletDiscount = 50;
                totalPayable = baseFare - walletDiscount;
            }
        }

        // 4. Book Now / Book Later Status Determination
        Instant now = Instant.now();
        boolean isFutureScheduled = dto.scheduledFor() != null && dto.scheduledFor().isAfter(now.plusSeconds(60));
        AmbulanceRequestStatus initialStatus = isFutureScheduled ? AmbulanceRequestStatus.SCHEDULED : AmbulanceRequestStatus.REQUEST_RECEIVED;

        // 5. Request Entity Persistence
        AmbulanceRequest request = new AmbulanceRequest();
        request.setRequestNumber("AR-" + System.currentTimeMillis());
        request.setStatus(initialStatus);
        request.setPatientId(effectivePatientId);
        request.setPatientName(dto.patient().name());
        request.setPatientPhone(dto.patient().phoneE164());
        request.setPickupAddress(dto.pickup().address() != null ? dto.pickup().address() : "Current Location");
        request.setPickupLat(dto.pickup().lat());
        request.setPickupLng(dto.pickup().lng());
        request.setDropAddress(dto.drop().address() != null ? dto.drop().address() : "Destination");
        request.setDropLat(dto.drop().lat());
        request.setDropLng(dto.drop().lng());
        request.setPriority(dto.priority() != null ? dto.priority() : "normal");
        request.setScheduledFor(dto.scheduledFor());
        request.setNotes(dto.notes());
        request.setIdempotencyKey(dto.idempotencyKey());
        request.setBaseFare(baseFare);
        request.setWalletDiscount(walletDiscount);
        request.setTotalPayable(totalPayable);
        request.setPaymentStatus("PENDING");

        request = requestRepository.save(request);

        // 6. Audit Logging Persistence
        recordAuditLog(
                "Booking Created",
                request.getId().toString(),
                "Ambulance booking created (awaiting payment)",
                "Patient",
                "PATIENT",
                effectivePatientId,
                request.getPatientName(),
                null,
                request.getStatus().name(),
                "FLUTTER",
                "/patient/requests"
        );

        log.info("[BOOKING] Request created: {} id={}", request.getRequestNumber(), request.getId());

        RequestAmbulanceResponse response = new RequestAmbulanceResponse(
                request.getId(),
                request.getRequestNumber(),
                request.getStatus(),
                request.getCreatedAt(),
                null,
                "Request stored. Awaiting payment confirmation before dispatch.",
                request.getBaseFare(),
                request.getWalletDiscount(),
                request.getTotalPayable(),
                request.getPaymentStatus()
        );

        webSocketGateway.emitNewRequest(response);
        return response;
    }

    @Transactional
    public CancelAmbulanceResponse cancelRequest(UUID requestId, CancelAmbulanceRequest dto, String patientId) {
        AmbulanceRequest request = getRequestById(requestId);

        List<AmbulanceRequestStatus> uncancelableStates = List.of(
                AmbulanceRequestStatus.ARRIVED,
                AmbulanceRequestStatus.PATIENT_ONBOARD,
                AmbulanceRequestStatus.DESTINATION_REACHED,
                AmbulanceRequestStatus.COMPLETED,
                AmbulanceRequestStatus.CANCELLED,
                AmbulanceRequestStatus.FAILED
        );

        if (uncancelableStates.contains(request.getStatus())) {
            throw new BadRequestException("Cannot cancel request when status is " + request.getStatus());
        }

        AmbulanceRequestStatus prevStatus = request.getStatus();
        request.setStatus(AmbulanceRequestStatus.CANCELLED);
        String reason = (dto != null && dto.reasonCode() != null && !dto.reasonCode().isBlank()) 
                ? dto.reasonCode() : "patient_cancelled";
        request.setCancelReason(reason);
        request.setUpdatedAt(LocalDateTime.now());

        if (request.getVendorDriverRef() != null) {
            try {
                UUID driverId = UUID.fromString(request.getVendorDriverRef());
                driverRepository.findById(driverId).ifPresent(driver -> {
                    driver.setStatus(DriverStatus.AVAILABLE);
                    driverRepository.save(driver);
                });
            } catch (Exception ignored) {}
        }

        request = requestRepository.save(request);

        recordAuditLog(
                "Trip Cancelled",
                request.getId().toString(),
                "Request cancelled by patient or dispatcher",
                "Patient",
                "PATIENT",
                patientId != null ? patientId : "patient",
                request.getPatientName(),
                prevStatus.name(),
                request.getStatus().name(),
                "FLUTTER",
                "/patient/requests/" + requestId + "/cancel"
        );

        webSocketGateway.emitStatusUpdated(requestId.toString(), "CANCELLED", java.util.Map.of(
                "requestId", requestId.toString(),
                "cancelReason", request.getCancelReason() != null ? request.getCancelReason() : ""
        ));

        return new CancelAmbulanceResponse(
                request.getId(),
                request.getUpdatedAt(),
                request.getStatus(),
                "Cancelled"
        );
    }

    @Transactional
    public WalletBenefitResponse getWallet(String patientId) {
        String effectivePatientId = (patientId == null || patientId.isBlank()) ? "demo-patient-uuid" : patientId;
        Optional<PatientWallet> walletOpt = walletRepository.findByPatientId(effectivePatientId);
        PatientWallet wallet;
        if (walletOpt.isEmpty()) {
            wallet = new PatientWallet(effectivePatientId, false);
            wallet = walletRepository.save(wallet);
        } else {
            wallet = walletOpt.get();
        }
        return new WalletBenefitResponse(!wallet.isAmbulanceBenefitUsed(), 50);
    }

    public AmbulanceRequest getRequestById(UUID requestId) {
        return requestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("Ambulance request not found: " + requestId));
    }

    public TrackingSnapshotResponse getTrackingSnapshot(UUID requestId) {
        AmbulanceRequest request = getRequestById(requestId);

        Optional<TrackingPosition> lastPosOpt = positionRepository.findTopByAmbulanceRequestIdOrderByCapturedAtDesc(requestId);
        LastLocationDto lastLocation = lastPosOpt.map(p -> new LastLocationDto(
                p.getVendorEventId(),
                p.getLat(),
                p.getLng(),
                p.getSpeedKmph(),
                p.getHeadingDeg(),
                p.getCapturedAt()
        )).orElse(null);

        DriverInfoDto driver = null;
        if (request.getStatus() != AmbulanceRequestStatus.REQUEST_CREATED
                && request.getStatus() != AmbulanceRequestStatus.SEARCHING_DRIVER
                && request.getStatus() != AmbulanceRequestStatus.SEARCHING
                && request.getStatus() != AmbulanceRequestStatus.REQUEST_RECEIVED) {
            if (request.getVendorDriverRef() != null) {
                driver = new DriverInfoDto(
                        request.getVendorDriverRef(),
                        request.getVendorDriverName(),
                        request.getVendorDriverPhone(),
                        request.getVendorVehicleNumber(),
                        request.getVendorAmbulanceType()
                );
            }
        }

        return new TrackingSnapshotResponse(
                request.getId(),
                request.getRequestNumber(),
                request.getStatus(),
                request.getPatientName(),
                request.getPickupAddress() != null ? request.getPickupAddress() : "",
                request.getPickupLat(),
                request.getPickupLng(),
                request.getDropAddress() != null ? request.getDropAddress() : "",
                request.getDropLat(),
                request.getDropLng(),
                driver,
                request.getEtaSeconds(),
                lastLocation,
                request.getUpdatedAt()
        );
    }

    public PaginatedResponse<OrderListItemResponse> listRequests(String patientId, int page, int limit) {
        return listRequests(patientId, null, null, null, page, limit, "createdAt", "DESC");
    }

    public PaginatedResponse<OrderListItemResponse> listRequests(
            String patientId,
            String status,
            String fromDate,
            String toDate,
            int page,
            int limit,
            String sortBy,
            String sortOrder
    ) {
        int pageNumber = Math.max(1, page);
        int pageSize = Math.max(1, limit);

        Specification<AmbulanceRequest> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (patientId != null && !patientId.isBlank()) {
                predicates.add(cb.equal(root.get("patientId"), patientId));
            }

            if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
                if ("ACTIVE".equalsIgnoreCase(status)) {
                    List<AmbulanceRequestStatus> activeStatuses = List.of(
                            AmbulanceRequestStatus.REQUEST_CREATED,
                            AmbulanceRequestStatus.REQUEST_RECEIVED,
                            AmbulanceRequestStatus.SEARCHING,
                            AmbulanceRequestStatus.SEARCHING_DRIVER,
                            AmbulanceRequestStatus.DRIVER_ASSIGNED,
                            AmbulanceRequestStatus.EN_ROUTE,
                            AmbulanceRequestStatus.ARRIVED,
                            AmbulanceRequestStatus.PATIENT_ONBOARD,
                            AmbulanceRequestStatus.TRIP_STARTED
                    );
                    predicates.add(root.get("status").in(activeStatuses));
                } else {
                    try {
                        AmbulanceRequestStatus statusEnum = AmbulanceRequestStatus.valueOf(status.toUpperCase());
                        predicates.add(cb.equal(root.get("status"), statusEnum));
                    } catch (IllegalArgumentException ignored) {
                        // ignore invalid status string
                    }
                }
            }

            if (fromDate != null && !fromDate.isBlank()) {
                try {
                    LocalDateTime from = LocalDateTime.parse(fromDate);
                    predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), from));
                } catch (Exception ignored) {}
            }

            if (toDate != null && !toDate.isBlank()) {
                try {
                    LocalDateTime to = LocalDateTime.parse(toDate);
                    predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), to));
                } catch (Exception ignored) {}
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        String sortField = (sortBy != null && !sortBy.isBlank()) ? sortBy : "createdAt";
        Sort.Direction direction = "ASC".equalsIgnoreCase(sortOrder) ? Sort.Direction.ASC : Sort.Direction.DESC;
        PageRequest pageable = PageRequest.of(pageNumber - 1, pageSize, Sort.by(direction, sortField));

        Page<AmbulanceRequest> requestPage = requestRepository.findAll(spec, pageable);

        List<OrderListItemResponse> dtos = requestPage.getContent().stream().map(r -> {
            DriverInfoDto driver = null;
            if (r.getStatus() != AmbulanceRequestStatus.REQUEST_CREATED
                    && r.getStatus() != AmbulanceRequestStatus.REQUEST_RECEIVED
                    && r.getStatus() != AmbulanceRequestStatus.SEARCHING
                    && r.getStatus() != AmbulanceRequestStatus.SEARCHING_DRIVER) {
                if (r.getVendorDriverRef() != null) {
                    driver = new DriverInfoDto(
                            r.getVendorDriverRef(),
                            r.getVendorDriverName(),
                            r.getVendorDriverPhone(),
                            r.getVendorVehicleNumber(),
                            r.getVendorAmbulanceType()
                    );
                }
            }

            return new OrderListItemResponse(
                    r.getId(),
                    r.getRequestNumber(),
                    r.getStatus(),
                    r.getPriority() != null ? r.getPriority() : "normal",
                    r.getPatientName(),
                    r.getPatientPhone(),
                    r.getPickupAddress(),
                    r.getPickupLat(),
                    r.getPickupLng(),
                    r.getDropAddress(),
                    r.getDropLat(),
                    r.getDropLng(),
                    r.getAssignedVendorId(),
                    r.getVendorAmbulanceType(),
                    driver,
                    r.getEtaSeconds(),
                    r.getCancelReason(),
                    r.getBaseFare(),
                    r.getWalletDiscount() != null ? r.getWalletDiscount() : 0,
                    r.getTotalPayable(),
                    r.getScheduledFor(),
                    r.getCreatedAt(),
                    r.getUpdatedAt()
            );
        }).toList();

        PaginationMeta meta = new PaginationMeta(
                requestPage.getTotalElements(),
                pageNumber,
                pageSize,
                requestPage.getTotalPages()
        );

        return new PaginatedResponse<>(dtos, meta);
    }

    private void recordAuditLog(
            String action,
            String bookingId,
            String description,
            String performedBy,
            String performedByRole,
            String performedById,
            String patientName,
            String previousStatus,
            String newStatus,
            String requestSource,
            String apiEndpoint
    ) {
        try {
            SystemAuditLog auditLog = new SystemAuditLog();
            auditLog.setAction(action);
            auditLog.setBookingId(bookingId);
            auditLog.setDescription(description);
            auditLog.setPerformedBy(performedBy);
            auditLog.setPerformedByRole(performedByRole);
            auditLog.setPerformedById(performedById);
            auditLog.setPatientName(patientName);
            auditLog.setPreviousStatus(previousStatus);
            auditLog.setNewStatus(newStatus);
            auditLog.setRequestSource(requestSource);
            auditLog.setApiEndpoint(apiEndpoint);
            auditLog.setSuccess(true);
            auditLogRepository.save(auditLog);
        } catch (Exception e) {
            log.error("Failed to write audit log: {}", e.getMessage());
        }
    }

    @Transactional
    public PaymentInitiateResponse initiatePayment(UUID requestId, String patientId) {
        String effectivePatientId = (patientId == null || patientId.isBlank()) ? "demo-patient-uuid" : patientId;
        AmbulanceRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new BadRequestException("Request not found"));

        if ("SUCCESS".equalsIgnoreCase(request.getPaymentStatus())) {
            return new PaymentInitiateResponse(
                    request.getPaymentRef(),
                    PaymentStatus.SUCCESS,
                    "Payment already completed"
            );
        }

        // Check if a transaction already exists for this request
        Optional<PaymentTransaction> existingTxOpt = paymentTransactionRepository
                .findTopByRequestIdOrderByCreatedAtDesc(requestId.toString());

        PaymentTransaction tx;
        if (existingTxOpt.isEmpty() || existingTxOpt.get().getStatus() == PaymentStatus.FAILED) {
            tx = new PaymentTransaction();
            tx.setRequestId(requestId.toString());
            tx.setPatientId(effectivePatientId);
            tx.setAmount(request.getTotalPayable() != null ? request.getTotalPayable() : (request.getBaseFare() != null ? request.getBaseFare() : 0));
            tx.setStatus(PaymentStatus.PENDING);
            tx.setMethod(PaymentMethod.MOCK);
            tx = paymentTransactionRepository.save(tx);
        } else {
            tx = existingTxOpt.get();
        }

        // Update request payment status & ref
        request.setPaymentStatus("PENDING");
        request.setPaymentRef(tx.getId().toString());
        requestRepository.save(request);

        return new PaymentInitiateResponse(tx.getId().toString(), PaymentStatus.PENDING);
    }

    @Transactional
    public ProcessPaymentResponse processPayment(UUID requestId, ProcessPaymentRequest dto, String patientId) {
        String effectivePatientId = (patientId == null || patientId.isBlank()) ? "demo-patient-uuid" : patientId;
        AmbulanceRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new BadRequestException("Request not found"));

        if ("SUCCESS".equalsIgnoreCase(request.getPaymentStatus())) {
            return new ProcessPaymentResponse(
                    PaymentStatus.SUCCESS,
                    "SUCCESS",
                    request.getPaymentRef(),
                    request.getPaymentRef(),
                    request.getTotalPayable(),
                    "MOCK_PAYMENT",
                    "Payment already completed. Ambulance dispatching."
            );
        }

        // Find pending/processing transaction
        Optional<PaymentTransaction> txOpt = paymentTransactionRepository
                .findTopByRequestIdOrderByCreatedAtDesc(requestId.toString());

        PaymentTransaction tx = txOpt.orElse(null);
        if (tx != null) {
            tx.setStatus(PaymentStatus.PROCESSING);
            paymentTransactionRepository.save(tx);
        }
        request.setPaymentStatus("PROCESSING");
        requestRepository.save(request);

        boolean simulateFail = dto != null && Boolean.TRUE.equals(dto.simulateFail());
        boolean paymentSucceeded = !simulateFail;

        if (paymentSucceeded) {
            // Consume wallet benefit NOW after successful payment
            if (request.getWalletDiscount() != null && request.getWalletDiscount() > 0) {
                PatientWallet wallet = walletRepository.findByPatientId(request.getPatientId())
                        .orElseGet(() -> new PatientWallet(request.getPatientId(), true));
                wallet.setAmbulanceBenefitUsed(true);
                walletRepository.save(wallet);
                log.info("[WALLETT] Consumed ambulance wallet benefit for patientId={} (requestId={})", request.getPatientId(), requestId);
            }

            String transactionRef = "MOCK_TXN_" + System.currentTimeMillis() + "_" + (1000 + (int)(Math.random() * 9000));
            if (tx != null) {
                tx.setStatus(PaymentStatus.SUCCESS);
                tx.setTransactionRef(transactionRef);
                tx.setAmount(request.getTotalPayable());
                paymentTransactionRepository.save(tx);
            }

            Instant now = Instant.now();
            boolean isFutureScheduled = request.getScheduledFor() != null && request.getScheduledFor().isAfter(now.plusSeconds(60));
            AmbulanceRequestStatus postPaymentStatus = isFutureScheduled ? AmbulanceRequestStatus.SCHEDULED : AmbulanceRequestStatus.SEARCHING;

            request.setPaymentStatus("SUCCESS");
            request.setPaymentRef(transactionRef);
            request.setStatus(postPaymentStatus);
            requestRepository.save(request);

            log.info("[PAYMENT] SUCCESS requestId={} ref={} status={}", requestId, transactionRef, postPaymentStatus);

            recordAuditLog(
                    "Payment Success",
                    request.getId().toString(),
                    "Mock payment succeeded. Ref: " + transactionRef,
                    "Patient",
                    "PATIENT",
                    effectivePatientId,
                    request.getPatientName(),
                    request.getStatus().name(),
                    postPaymentStatus.name(),
                    "FLUTTER",
                    "/patient/requests/" + requestId + "/payment/process"
            );

            // Enqueue booking dispatch job to bookingQueue
            CreateBookingPayload bookingPayload = new CreateBookingPayload(
                    request.getId().toString(),
                    request.getIdempotencyKey(),
                    new LocationDto(request.getPickupLat(), request.getPickupLng(), request.getPickupAddress()),
                    new LocationDto(request.getDropLat(), request.getDropLng(), request.getDropAddress()),
                    request.getPriority(),
                    new PatientInfoDto(request.getPatientName(), request.getPatientPhone(), null, null),
                    request.getNotes(),
                    request.getScheduledFor() != null ? request.getScheduledFor().toString() : null,
                    (request.getNotes() != null && request.getNotes().toUpperCase().contains("DEMO")) ? "mock" : null
            );

            long delay = isFutureScheduled ? Math.max(0, request.getScheduledFor().toEpochMilli() - System.currentTimeMillis()) : 0;
            queueService.enqueue(
                    QueueConstants.BOOKING_QUEUE,
                    "create-booking",
                    bookingPayload,
                    request.getId().toString(),
                    delay,
                    5,
                    1000
            );
            log.info("[QUEUE] Dispatch job created after payment: request={}", request.getId());

            return new ProcessPaymentResponse(
                    PaymentStatus.SUCCESS,
                    "SUCCESS",
                    transactionRef,
                    transactionRef,
                    request.getTotalPayable(),
                    "MOCK_PAYMENT",
                    "Payment successful. Ambulance dispatching."
            );
        } else {
            if (tx != null) {
                tx.setStatus(PaymentStatus.FAILED);
                tx.setFailureReason("Mock payment failure (simulate_fail=true)");
                paymentTransactionRepository.save(tx);
            }
            request.setPaymentStatus("FAILED");
            requestRepository.save(request);
            log.warn("[PAYMENT] FAILED requestId={}", requestId);
            return new ProcessPaymentResponse(
                    PaymentStatus.FAILED,
                    "FAILED",
                    "Payment failed. Please retry."
            );
        }
    }

    public PaymentStatusResponse getPaymentStatus(UUID requestId, String patientId) {
        AmbulanceRequest request = requestRepository.findById(requestId)
                .orElseThrow(() -> new BadRequestException("Request not found"));

        Optional<PaymentTransaction> txOpt = paymentTransactionRepository
                .findTopByRequestIdOrderByCreatedAtDesc(requestId.toString());

        PaymentTransaction tx = txOpt.orElse(null);

        PaymentTransactionSummary txSummary = tx != null ? new PaymentTransactionSummary(
                tx.getId(),
                tx.getStatus(),
                tx.getTransactionRef(),
                tx.getAmount()
        ) : null;

        String transactionRef = (tx != null && tx.getTransactionRef() != null) ? tx.getTransactionRef() : request.getPaymentRef();

        return new PaymentStatusResponse(
                requestId,
                request.getPaymentStatus() != null ? request.getPaymentStatus() : "NONE",
                transactionRef,
                request.getBaseFare(),
                request.getWalletDiscount() != null ? request.getWalletDiscount() : 0,
                request.getTotalPayable(),
                txSummary
        );
    }
}
