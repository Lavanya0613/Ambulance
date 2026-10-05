package com.callhealth.ambulance.queue.worker;

import com.callhealth.ambulance.dto.EtaResult;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.TrackingPosition;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.model.QueueJobMessage;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.TrackingPositionRepository;
import com.callhealth.ambulance.service.DlqService;
import com.callhealth.ambulance.service.EtaService;
import com.callhealth.ambulance.util.GeoUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class TrackingQueueWorker {

    private static final Logger log = LoggerFactory.getLogger(TrackingQueueWorker.class);

    private final RedisQueueService queueService;
    private final DlqService dlqService;
    private final AmbulanceRequestRepository requestRepository;
    private final TrackingPositionRepository positionRepository;
    private final EtaService etaService;
    private final ObjectMapper objectMapper;
    private final com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway;

    @Value("${mock.tracking.enabled:true}")
    private boolean mockTrackingEnabled;

    @Value("${mock.tracking.interval-ms:1500}")
    private long mockIntervalMs;

    @Value("${mock.tracking.step-distance-meters:80.0}")
    private double stepDistanceMeters;

    @Value("${mock.tracking.arrival-threshold-meters:40.0}")
    private double arrivalThresholdMeters;

    public TrackingQueueWorker(
            RedisQueueService queueService,
            DlqService dlqService,
            AmbulanceRequestRepository requestRepository,
            TrackingPositionRepository positionRepository,
            EtaService etaService,
            ObjectMapper objectMapper,
            com.callhealth.ambulance.gateway.WebSocketGateway webSocketGateway
    ) {
        this.queueService = queueService;
        this.dlqService = dlqService;
        this.requestRepository = requestRepository;
        this.positionRepository = positionRepository;
        this.etaService = etaService;
        this.objectMapper = objectMapper;
        this.webSocketGateway = webSocketGateway;
    }

    @Scheduled(fixedDelay = 200)
    public void processTrackingQueue() {
        QueueJobMessage message = queueService.pollJob(QueueConstants.TRACKING_QUEUE);
        if (message == null) return;

        log.info("[QUEUE] Tracking worker processing job {} (attempt {})", message.getJobId(), message.getAttemptsMade() + 1);

        PollTrackingPayload payload = null;
        try {
            payload = objectMapper.readValue(message.getPayloadJson(), PollTrackingPayload.class);
            boolean isTerminal = executeTrackingPoll(payload);
            queueService.incrementCompleted(QueueConstants.TRACKING_QUEUE);

            if (!isTerminal) {
                // Re-enqueue next tracking poll job with configured interval
                PollTrackingPayload nextPayload = new PollTrackingPayload(
                        payload.requestId(),
                        payload.vendorId(),
                        payload.vendorBookingRef(),
                        Instant.now().toString()
                );
                queueService.enqueue(
                        QueueConstants.TRACKING_QUEUE,
                        "poll-tracking",
                        nextPayload,
                        payload.requestId() + "-track-" + System.currentTimeMillis(),
                        mockIntervalMs,
                        3,
                        500
                );
            }
            log.info("[QUEUE] Tracking job {} processed successfully (isTerminal={})", message.getJobId(), isTerminal);
        } catch (Exception e) {
            log.error("[QUEUE] Tracking worker error processing job {}: {}", message.getJobId(), e.getMessage(), e);
            handleWorkerFailure(message, payload, e);
        }
    }

    @Transactional
    public boolean executeTrackingPoll(PollTrackingPayload payload) {
        UUID requestId = UUID.fromString(payload.requestId());
        var requestOpt = requestRepository.findById(requestId);
        if (requestOpt.isEmpty()) {
            log.warn("[QUEUE] Request not found: {}, skipping tracking poll", payload.requestId());
            return true;
        }
        AmbulanceRequest request = requestOpt.get();

        List<AmbulanceRequestStatus> terminalStates = List.of(
                AmbulanceRequestStatus.COMPLETED,
                AmbulanceRequestStatus.DESTINATION_REACHED,
                AmbulanceRequestStatus.CANCELLED,
                AmbulanceRequestStatus.FAILED
        );

        if (terminalStates.contains(request.getStatus())) {
            return true;
        }

        AmbulanceRequestStatus currentStatus = request.getStatus();

        // Advance status from DRIVER_ASSIGNED -> EN_ROUTE if needed
        if (currentStatus == AmbulanceRequestStatus.DRIVER_ASSIGNED || currentStatus == AmbulanceRequestStatus.SEARCHING_DRIVER || currentStatus == AmbulanceRequestStatus.VENDOR_ACCEPTED) {
            request.setStatus(AmbulanceRequestStatus.EN_ROUTE);
            currentStatus = AmbulanceRequestStatus.EN_ROUTE;
            requestRepository.save(request);
            webSocketGateway.emitStatusUpdated(payload.requestId(), "EN_ROUTE", Map.of("requestId", payload.requestId()));
            log.info("[MOCK TRACKING] Request {} status updated to EN_ROUTE", payload.requestId());
        }

        // Determine current position
        var latestPosOpt = positionRepository.findTopByAmbulanceRequestIdOrderByCapturedAtDesc(requestId);
        double currentLat;
        double currentLng;

        if (latestPosOpt.isPresent()) {
            currentLat = latestPosOpt.get().getLat();
            currentLng = latestPosOpt.get().getLng();
        } else {
            // Initial mock start position: ~1.2 km away from pickup
            currentLat = request.getPickupLat() + 0.008;
            currentLng = request.getPickupLng() + 0.008;
        }

        // Determine target coordinates based on status phase
        double targetLat = request.getPickupLat();
        double targetLng = request.getPickupLng();

        if (currentStatus == AmbulanceRequestStatus.TRIP_STARTED || currentStatus == AmbulanceRequestStatus.PATIENT_ONBOARD) {
            targetLat = request.getDropLat();
            targetLng = request.getDropLng();
        }

        double currentDistMeters = GeoUtil.haversineDistanceMeters(currentLat, currentLng, targetLat, targetLng);

        // Step movement towards target
        double nextLat;
        double nextLng;
        double headingDeg;

        if (currentDistMeters <= arrivalThresholdMeters) {
            nextLat = targetLat;
            nextLng = targetLng;
            headingDeg = 0.0;

            if (currentStatus == AmbulanceRequestStatus.EN_ROUTE || currentStatus == AmbulanceRequestStatus.DRIVER_ASSIGNED) {
                request.setStatus(AmbulanceRequestStatus.ARRIVED);
                request.setEtaSeconds(0);
                requestRepository.save(request);
                webSocketGateway.emitStatusUpdated(payload.requestId(), "ARRIVED", Map.of("requestId", payload.requestId()));
                webSocketGateway.emitEtaUpdated(payload.requestId(), 0);
                log.info("[MOCK TRACKING] Request {} arrived at pickup location", payload.requestId());
            } else if (currentStatus == AmbulanceRequestStatus.TRIP_STARTED || currentStatus == AmbulanceRequestStatus.PATIENT_ONBOARD || currentStatus == AmbulanceRequestStatus.ARRIVED) {
                request.setStatus(AmbulanceRequestStatus.DESTINATION_REACHED);
                request.setEtaSeconds(0);
                requestRepository.save(request);
                webSocketGateway.emitStatusUpdated(payload.requestId(), "DESTINATION_REACHED", Map.of("requestId", payload.requestId()));
                webSocketGateway.emitRideCompleted(payload.requestId(), Map.of("requestId", payload.requestId(), "status", "DESTINATION_REACHED"));
                webSocketGateway.emitEtaUpdated(payload.requestId(), 0);
                log.info("[MOCK TRACKING] Request {} reached destination - DESTINATION_REACHED", payload.requestId());
            }
        } else {
            double[] nextCoords = GeoUtil.moveTowards(currentLat, currentLng, targetLat, targetLng, stepDistanceMeters);
            nextLat = nextCoords[0];
            nextLng = nextCoords[1];
            headingDeg = GeoUtil.calculateBearingDeg(currentLat, currentLng, targetLat, targetLng);

            double remainingDistMeters = GeoUtil.haversineDistanceMeters(nextLat, nextLng, targetLat, targetLng);
            int etaSeconds = (int) Math.round(remainingDistMeters / 11.11); // ~40 km/h avg speed
            request.setEtaSeconds(etaSeconds);
            requestRepository.save(request);

            webSocketGateway.emitEtaUpdated(payload.requestId(), etaSeconds);
        }

        // Persist NEW TrackingPosition entity to PostgreSQL
        TrackingPosition newPos = new TrackingPosition();
        newPos.setAmbulanceRequest(request);
        newPos.setVendorEventId("EVT_" + System.currentTimeMillis());
        newPos.setLat(nextLat);
        newPos.setLng(nextLng);
        newPos.setSpeedKmph(40.0);
        newPos.setHeadingDeg(headingDeg);
        newPos.setCapturedAt(Instant.now());
        positionRepository.save(newPos);

        // Emit live position update via WebSocket
        webSocketGateway.emitLocationUpdated(payload.requestId(), Map.of(
                "requestId", payload.requestId(),
                "lat", nextLat,
                "lng", nextLng,
                "speedKmph", 40.0,
                "headingDeg", headingDeg,
                "capturedAt", Instant.now().toString()
        ));

        double distRem = GeoUtil.haversineDistanceMeters(nextLat, nextLng, targetLat, targetLng);
        log.info("[MOCK TRACKING] requestId={} status={} pos=({}, {}) target=({}, {}) dist={}m eta={}s",
                payload.requestId(), request.getStatus(),
                String.format("%.5f", nextLat), String.format("%.5f", nextLng),
                String.format("%.5f", targetLat), String.format("%.5f", targetLng),
                Math.round(distRem), request.getEtaSeconds());

        return terminalStates.contains(request.getStatus());
    }

    private void handleWorkerFailure(QueueJobMessage message, PollTrackingPayload payload, Exception e) {
        int currentAttempts = message.getAttemptsMade() + 1;
        if (currentAttempts < message.getMaxAttempts()) {
            long delay = message.getBackoffDelayMs() * (long) Math.pow(2, currentAttempts - 1);
            queueService.reenqueueDelayed(message, delay);
        } else {
            log.warn("[QUEUE] Tracking job {} exhausted retries ({}/{}), moving to DLQ", message.getJobId(), currentAttempts, message.getMaxAttempts());
            dlqService.storeFailedJob(QueueConstants.TRACKING_QUEUE, message.getJobId(), message.getPayloadJson(), e.getMessage(), currentAttempts);
            queueService.incrementFailed(QueueConstants.TRACKING_QUEUE);
        }
    }
}

