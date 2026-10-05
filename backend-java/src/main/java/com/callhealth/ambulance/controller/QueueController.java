package com.callhealth.ambulance.controller;

import com.callhealth.ambulance.dto.QueueStatusResponse;
import com.callhealth.ambulance.model.entity.DlqJob;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import com.callhealth.ambulance.service.DlqService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/queues")
public class QueueController {

    private final RedisQueueService queueService;
    private final DlqService dlqService;

    public QueueController(RedisQueueService queueService, DlqService dlqService) {
        this.queueService = queueService;
        this.dlqService = dlqService;
    }

    @GetMapping("/status")
    public ResponseEntity<QueueStatusResponse> getQueueStatus() {
        long dlqCount = dlqService.getDlqCount();
        return ResponseEntity.ok(queueService.getQueueStatus(dlqCount));
    }

    @GetMapping("/dlq")
    public ResponseEntity<List<DlqJob>> getDlqJobs() {
        return ResponseEntity.ok(dlqService.getFailedJobs());
    }

    @PostMapping("/dlq/{id}/retry")
    public ResponseEntity<Map<String, Object>> retryDlqJob(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(dlqService.retryJob(id));
    }
}
