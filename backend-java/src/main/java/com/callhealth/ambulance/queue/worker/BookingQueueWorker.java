package com.callhealth.ambulance.queue.worker;

import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.CreateBookingPayload;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.model.QueueJobMessage;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.service.DlqService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Random;
import java.util.UUID;

@Component
public class BookingQueueWorker {

    private static final Logger log = LoggerFactory.getLogger(BookingQueueWorker.class);

    private final RedisQueueService queueService;
    private final DlqService dlqService;
    private final AmbulanceRequestRepository requestRepository;
    private final ObjectMapper objectMapper;
    private final com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway;
    private final Random random = new Random();

    public BookingQueueWorker(
            RedisQueueService queueService,
            DlqService dlqService,
            AmbulanceRequestRepository requestRepository,
            ObjectMapper objectMapper,
            com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway
    ) {
        this.queueService = queueService;
        this.dlqService = dlqService;
        this.requestRepository = requestRepository;
        this.objectMapper = objectMapper;
        this.webSocketGateway = webSocketGateway;
    }

    @Scheduled(fixedDelay = 200)
    public void processBookingQueue() {
        QueueJobMessage message = queueService.pollJob(QueueConstants.BOOKING_QUEUE);
        if (message == null) return;

        log.info("[QUEUE] Booking worker processing job {} (attempt {})", message.getJobId(), message.getAttemptsMade() + 1);

        CreateBookingPayload payload = null;
        try {
            payload = objectMapper.readValue(message.getPayloadJson(), CreateBookingPayload.class);
            executeBookingDispatch(payload);
            queueService.incrementCompleted(QueueConstants.BOOKING_QUEUE);
            log.info("[QUEUE] Booking job {} completed successfully", message.getJobId());
        } catch (Exception e) {
            log.error("[QUEUE] Booking worker error processing job {}: {}", message.getJobId(), e.getMessage(), e);
            handleWorkerFailure(message, payload, e);
        }
    }

    @Transactional
    public void executeBookingDispatch(CreateBookingPayload payload) {
        UUID requestId = UUID.fromString(payload.requestId());
        var requestOpt = requestRepository.findById(requestId);
        if (requestOpt.isEmpty()) {
            log.warn("[QUEUE] Request not found: {}, skipping booking dispatch", payload.requestId());
            return;
        }
        AmbulanceRequest request = requestOpt.get();

        if (request.getStatus() == AmbulanceRequestStatus.SCHEDULED) {
            request.setStatus(AmbulanceRequestStatus.SEARCHING);
            requestRepository.save(request);
            log.info("[QUEUE] Scheduled booking {} active now; status transitioned to SEARCHING", payload.requestId());
        }

        String vendorId = (payload.preferredVendorId() != null && !payload.preferredVendorId().isBlank())
                ? payload.preferredVendorId()
                : "mock";

        String vendorBookingRef = "VND_MOCK_" + System.currentTimeMillis() + "_" + (1000 + random.nextInt(9000));
        String driverRef = "DRV_" + (1000 + random.nextInt(9000));

        request.setAssignedVendorId(vendorId);
        request.setVendorBookingRef(vendorBookingRef);
        request.setVendorDriverRef(driverRef);
        request.setVendorDriverName("Rajesh Kumar");
        request.setVendorDriverPhone("+919876543210");
        request.setVendorVehicleNumber("TS-09-EA-1234");
        request.setVendorAmbulanceType("ALS");
        request.setEtaSeconds(480);
        request.setStatus(AmbulanceRequestStatus.DRIVER_ASSIGNED);

        requestRepository.save(request);
        log.info("[DATABASE] Request {} updated to DRIVER_ASSIGNED; vendor={}; ref={}", payload.requestId(), vendorId, vendorBookingRef);

        // Emit WebSocket real-time driver_assigned event
        java.util.Map<String, Object> driverMap = java.util.Map.of(
                "vendorDriverRef", driverRef,
                "name", "Rajesh Kumar",
                "phoneE164", "+919876543210",
                "vehicleNumber", "TS-09-EA-1234",
                "ambulanceType", "ALS"
        );
        webSocketGateway.emitAmbulanceAssigned(payload.requestId(), java.util.Map.of(
                "requestId", payload.requestId(),
                "patientId", request.getPatientId() != null ? request.getPatientId() : "",
                "driver", driverMap
        ));
        webSocketGateway.emitStatusUpdated(payload.requestId(), "DRIVER_ASSIGNED", java.util.Map.of(
                "requestId", payload.requestId(),
                "driver", driverMap
        ));

        // Enqueue initial poll-tracking job
        PollTrackingPayload trackingPayload = new PollTrackingPayload(
                payload.requestId(),
                vendorId,
                vendorBookingRef,
                null
        );

        queueService.enqueue(
                QueueConstants.TRACKING_QUEUE,
                "poll-tracking",
                trackingPayload,
                payload.requestId() + "-track",
                1000,
                3,
                500
        );
    }

    private void handleWorkerFailure(QueueJobMessage message, CreateBookingPayload payload, Exception e) {
        int currentAttempts = message.getAttemptsMade() + 1;
        if (currentAttempts < message.getMaxAttempts()) {
            long delay = message.getBackoffDelayMs() * (long) Math.pow(2, currentAttempts - 1);
            queueService.reenqueueDelayed(message, delay);
        } else {
            log.warn("[QUEUE] Booking job {} exhausted retries ({}/{}), moving to DLQ", message.getJobId(), currentAttempts, message.getMaxAttempts());
            if (payload != null && payload.requestId() != null) {
                try {
                    requestRepository.findById(UUID.fromString(payload.requestId())).ifPresent(req -> {
                        req.setStatus(AmbulanceRequestStatus.FAILED);
                        requestRepository.save(req);
                    });
                } catch (Exception ex) {
                    log.error("[QUEUE] Error setting request FAILED for exhausted job: {}", ex.getMessage());
                }
            }
            dlqService.storeFailedJob(QueueConstants.BOOKING_QUEUE, message.getJobId(), message.getPayloadJson(), e.getMessage(), currentAttempts);
            queueService.incrementFailed(QueueConstants.BOOKING_QUEUE);
        }
    }
}
