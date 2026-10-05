package com.callhealth.ambulance.service;

import com.callhealth.ambulance.common.exception.ResourceNotFoundException;
import com.callhealth.ambulance.model.entity.DlqJob;
import com.callhealth.ambulance.model.entity.SystemAuditLog;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.CreateBookingPayload;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import com.callhealth.ambulance.repository.DlqJobRepository;
import com.callhealth.ambulance.repository.SystemAuditLogRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class DlqService {

    private static final Logger log = LoggerFactory.getLogger(DlqService.class);

    private final DlqJobRepository repo;
    private final RedisQueueService queueService;
    private final SystemAuditLogRepository auditLogRepository;
    private final ObjectMapper objectMapper;

    public DlqService(
            DlqJobRepository repo,
            RedisQueueService queueService,
            SystemAuditLogRepository auditLogRepository,
            ObjectMapper objectMapper
    ) {
        this.repo = repo;
        this.queueService = queueService;
        this.auditLogRepository = auditLogRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public DlqJob storeFailedJob(String queueName, String jobId, Object payload, String error, int retryCount) {
        try {
            String payloadJson = payload instanceof String ? (String) payload : objectMapper.writeValueAsString(payload);
            DlqJob job = new DlqJob();
            job.setQueueName(queueName);
            job.setJobId(jobId);
            job.setPayload(payloadJson);
            job.setError(error != null ? error : "Unknown error");
            job.setRetryCount(retryCount);
            DlqJob saved = repo.save(job);

            String requestId = extractRequestId(payloadJson);

            recordAuditLog(
                    "Queue Failed",
                    requestId,
                    "Job moved to DLQ from " + queueName,
                    false,
                    error,
                    "queue:" + queueName
            );

            log.warn("[DLQ] Stored failed job {} from queue {}", jobId, queueName);
            return saved;
        } catch (Exception e) {
            log.error("[DLQ] Failed to store dead letter job: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to store DLQ job", e);
        }
    }

    public List<DlqJob> getFailedJobs() {
        return repo.findAllByOrderByFailedAtDesc();
    }

    public long getDlqCount() {
        return repo.count();
    }

    @Transactional
    public Map<String, Object> retryJob(UUID id) {
        DlqJob dlqJob = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("DLQ job with id " + id + " not found"));

        try {
            String newJobId = dlqJob.getJobId() + "-retry";
            String queueName = dlqJob.getQueueName();

            if (QueueConstants.BOOKING_QUEUE.equals(queueName)) {
                CreateBookingPayload payload = objectMapper.readValue(dlqJob.getPayload(), CreateBookingPayload.class);
                queueService.enqueue(QueueConstants.BOOKING_QUEUE, "create-booking", payload, newJobId, 0, 5, 1000);
            } else if (QueueConstants.TRACKING_QUEUE.equals(queueName)) {
                PollTrackingPayload payload = objectMapper.readValue(dlqJob.getPayload(), PollTrackingPayload.class);
                queueService.enqueue(QueueConstants.TRACKING_QUEUE, "poll-tracking", payload, newJobId, 1500, 3, 500);
            } else {
                throw new IllegalArgumentException("Unknown queue name: " + queueName);
            }

            String requestId = extractRequestId(dlqJob.getPayload());

            recordAuditLog(
                    "Queue Retry",
                    requestId,
                    "DLQ job re-queued to " + queueName,
                    true,
                    null,
                    "queue:" + queueName + ":retry"
            );

            repo.delete(dlqJob);
            log.info("[DLQ] Job {} re-queued to {}", id, queueName);
            return Map.of("success", true, "message", "Job " + id + " re-queued to " + queueName);
        } catch (Exception e) {
            log.error("[DLQ] Failed to retry job {}: {}", id, e.getMessage(), e);
            throw new RuntimeException("Failed to retry DLQ job", e);
        }
    }

    private String extractRequestId(String payloadJson) {
        try {
            var node = objectMapper.readTree(payloadJson);
            if (node.has("requestId")) return node.get("requestId").asText();
        } catch (Exception ignored) {}
        return null;
    }

    private void recordAuditLog(String action, String bookingId, String description, boolean success, String errorMessage, String apiEndpoint) {
        try {
            SystemAuditLog auditLog = new SystemAuditLog();
            auditLog.setAction(action);
            auditLog.setBookingId(bookingId);
            auditLog.setDescription(description);
            auditLog.setPerformedBy("System");
            auditLog.setPerformedByRole("SYSTEM");
            auditLog.setPerformedById("system");
            auditLog.setRequestSource("WEBHOOK");
            auditLog.setApiEndpoint(apiEndpoint);
            auditLog.setSuccess(success);
            auditLog.setErrorMessage(errorMessage);
            auditLogRepository.save(auditLog);
        } catch (Exception e) {
            log.error("Failed to write audit log from DLQ: {}", e.getMessage());
        }
    }
}
