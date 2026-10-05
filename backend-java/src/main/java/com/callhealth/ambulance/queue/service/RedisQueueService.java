package com.callhealth.ambulance.queue.service;

import com.callhealth.ambulance.dto.QueueCountMetrics;
import com.callhealth.ambulance.dto.QueueMetricsMap;
import com.callhealth.ambulance.dto.QueueStatusResponse;
import com.callhealth.ambulance.queue.QueueConstants;
import com.callhealth.ambulance.queue.model.QueueJobMessage;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class RedisQueueService {

    private static final Logger log = LoggerFactory.getLogger(RedisQueueService.class);

    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    // Fallback in-memory structures if Redis connection is unavailable/offline
    private final Map<String, ConcurrentLinkedQueue<String>> memoryReadyQueues = new ConcurrentHashMap<>();
    private final Map<String, ConcurrentSkipListSet<QueueJobMessage>> memoryDelayedQueues = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> memoryCompletedCounts = new ConcurrentHashMap<>();
    private final Map<String, AtomicLong> memoryFailedCounts = new ConcurrentHashMap<>();

    public RedisQueueService(StringRedisTemplate redisTemplate, ObjectMapper objectMapper) {
        this.redisTemplate = redisTemplate;
        this.objectMapper = objectMapper;
    }

    public String enqueue(String queueName, String jobName, Object payload, String jobId, long delayMs, int maxAttempts, long backoffDelayMs) {
        String effectiveJobId = (jobId == null || jobId.isBlank()) ? UUID.randomUUID().toString() : jobId;
        try {
            String payloadJson = payload instanceof String ? (String) payload : objectMapper.writeValueAsString(payload);
            long now = System.currentTimeMillis();
            long executeAt = now + Math.max(0, delayMs);

            QueueJobMessage message = new QueueJobMessage(
                    effectiveJobId,
                    queueName,
                    jobName,
                    payloadJson,
                    0,
                    maxAttempts > 0 ? maxAttempts : 3,
                    executeAt,
                    backoffDelayMs > 0 ? backoffDelayMs : 1000,
                    now
            );

            String messageJson = objectMapper.writeValueAsString(message);

            try {
                if (delayMs > 0) {
                    redisTemplate.opsForZSet().add(getDelayedKey(queueName), messageJson, executeAt);
                    log.info("[QUEUE] Enqueued delayed job {} to {} with delay {}ms", effectiveJobId, queueName, delayMs);
                } else {
                    redisTemplate.opsForList().rightPush(getReadyKey(queueName), messageJson);
                    log.info("[QUEUE] Enqueued job {} to {}", effectiveJobId, queueName);
                }
            } catch (Exception redisEx) {
                log.warn("[REDIS] Redis unavailable, using in-memory queue fallback for {}: {}", queueName, redisEx.getMessage());
                if (delayMs > 0) {
                    getMemoryDelayed(queueName).add(message);
                } else {
                    getMemoryReady(queueName).add(messageJson);
                }
            }
            return effectiveJobId;
        } catch (Exception e) {
            log.error("[QUEUE] Failed to enqueue job to {}: {}", queueName, e.getMessage(), e);
            throw new RuntimeException("Failed to enqueue queue job", e);
        }
    }

    public QueueJobMessage pollJob(String queueName) {
        try {
            try {
                String messageJson = redisTemplate.opsForList().leftPop(getReadyKey(queueName));
                if (messageJson != null) {
                    return objectMapper.readValue(messageJson, QueueJobMessage.class);
                }
            } catch (Exception redisEx) {
                // Fallback to in-memory queue
            }

            String memoryMessageJson = getMemoryReady(queueName).poll();
            if (memoryMessageJson != null) {
                return objectMapper.readValue(memoryMessageJson, QueueJobMessage.class);
            }
            return null;
        } catch (Exception e) {
            log.error("[QUEUE] Failed to poll job from {}: {}", queueName, e.getMessage());
            return null;
        }
    }

    public void reenqueueDelayed(QueueJobMessage message, long delayMs) {
        try {
            message.setAttemptsMade(message.getAttemptsMade() + 1);
            long executeAt = System.currentTimeMillis() + delayMs;
            message.setExecuteAt(executeAt);

            String messageJson = objectMapper.writeValueAsString(message);
            try {
                redisTemplate.opsForZSet().add(getDelayedKey(message.getQueueName()), messageJson, executeAt);
                log.info("[QUEUE] Re-enqueued job {} to {} (attempt {}/{}) with backoff {}ms",
                        message.getJobId(), message.getQueueName(), message.getAttemptsMade(), message.getMaxAttempts(), delayMs);
            } catch (Exception redisEx) {
                log.warn("[REDIS] Redis unavailable, re-enqueuing to in-memory delayed queue for {}", message.getQueueName());
                getMemoryDelayed(message.getQueueName()).add(message);
            }
        } catch (Exception e) {
            log.error("[QUEUE] Failed to re-enqueue delayed job {}: {}", message.getJobId(), e.getMessage());
        }
    }

    @Scheduled(fixedDelay = 200)
    public void processDelayedJobs() {
        processDelayedQueue(QueueConstants.BOOKING_QUEUE);
        processDelayedQueue(QueueConstants.TRACKING_QUEUE);
    }

    private void processDelayedQueue(String queueName) {
        long now = System.currentTimeMillis();
        try {
            Set<String> readyItems = redisTemplate.opsForZSet().rangeByScore(getDelayedKey(queueName), 0, now);
            if (readyItems != null && !readyItems.isEmpty()) {
                for (String itemJson : readyItems) {
                    Long removed = redisTemplate.opsForZSet().remove(getDelayedKey(queueName), itemJson);
                    if (removed != null && removed > 0) {
                        redisTemplate.opsForList().rightPush(getReadyKey(queueName), itemJson);
                    }
                }
            }
        } catch (Exception redisEx) {
            // Process memory delayed queue
            var memorySet = getMemoryDelayed(queueName);
            var iterator = memorySet.iterator();
            while (iterator.hasNext()) {
                QueueJobMessage msg = iterator.next();
                if (msg.getExecuteAt() <= now) {
                    iterator.remove();
                    try {
                        getMemoryReady(queueName).add(objectMapper.writeValueAsString(msg));
                    } catch (Exception ignored) {}
                }
            }
        }
    }

    public void incrementCompleted(String queueName) {
        try {
            redisTemplate.opsForValue().increment("queue:" + queueName + ":completed");
        } catch (Exception redisEx) {
            getMemoryCompleted(queueName).incrementAndGet();
        }
    }

    public void incrementFailed(String queueName) {
        try {
            redisTemplate.opsForValue().increment("queue:" + queueName + ":failed");
        } catch (Exception redisEx) {
            getMemoryFailed(queueName).incrementAndGet();
        }
    }

    public QueueCountMetrics getMetrics(String queueName) {
        long waitingCount = 0;
        long delayedCount = 0;
        long completedCount = 0;
        long failedCount = 0;

        try {
            Long waiting = redisTemplate.opsForList().size(getReadyKey(queueName));
            Long delayed = redisTemplate.opsForZSet().zCard(getDelayedKey(queueName));
            String completedStr = redisTemplate.opsForValue().get("queue:" + queueName + ":completed");
            String failedStr = redisTemplate.opsForValue().get("queue:" + queueName + ":failed");

            waitingCount = waiting != null ? waiting : 0;
            delayedCount = delayed != null ? delayed : 0;
            completedCount = completedStr != null ? Long.parseLong(completedStr) : 0;
            failedCount = failedStr != null ? Long.parseLong(failedStr) : 0;
        } catch (Exception redisEx) {
            waitingCount = getMemoryReady(queueName).size();
            delayedCount = getMemoryDelayed(queueName).size();
            completedCount = getMemoryCompleted(queueName).get();
            failedCount = getMemoryFailed(queueName).get();
        }

        return new QueueCountMetrics(waitingCount, 0, completedCount, failedCount, delayedCount, 0);
    }

    public QueueStatusResponse getQueueStatus(long dlqCount) {
        QueueCountMetrics bookingMetrics = getMetrics(QueueConstants.BOOKING_QUEUE);
        QueueCountMetrics trackingMetrics = getMetrics(QueueConstants.TRACKING_QUEUE);

        long waiting = bookingMetrics.waiting() + trackingMetrics.waiting();
        long active = bookingMetrics.active() + trackingMetrics.active();
        long completed = bookingMetrics.completed() + trackingMetrics.completed();
        long failed = bookingMetrics.failed() + trackingMetrics.failed();
        long delayed = bookingMetrics.delayed() + trackingMetrics.delayed();

        return new QueueStatusResponse(
                waiting,
                active,
                completed,
                failed,
                delayed,
                0,
                dlqCount,
                new QueueMetricsMap(bookingMetrics, trackingMetrics)
        );
    }

    private ConcurrentLinkedQueue<String> getMemoryReady(String queueName) {
        return memoryReadyQueues.computeIfAbsent(queueName, k -> new ConcurrentLinkedQueue<>());
    }

    private ConcurrentSkipListSet<QueueJobMessage> getMemoryDelayed(String queueName) {
        return memoryDelayedQueues.computeIfAbsent(queueName, k -> new ConcurrentSkipListSet<>(
                Comparator.comparingLong(QueueJobMessage::getExecuteAt)
                        .thenComparing(QueueJobMessage::getJobId)
        ));
    }

    private AtomicLong getMemoryCompleted(String queueName) {
        return memoryCompletedCounts.computeIfAbsent(queueName, k -> new AtomicLong(0));
    }

    private AtomicLong getMemoryFailed(String queueName) {
        return memoryFailedCounts.computeIfAbsent(queueName, k -> new AtomicLong(0));
    }

    private String getReadyKey(String queueName) {
        return "queue:" + queueName;
    }

    private String getDelayedKey(String queueName) {
        return "queue:" + queueName + ":delayed";
    }
}
