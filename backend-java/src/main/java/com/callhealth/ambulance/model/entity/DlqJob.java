package com.callhealth.ambulance.model.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "dead_letter_jobs")
public class DlqJob {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "jobId", nullable = false)
    private String jobId;

    @Column(name = "queueName", nullable = false)
    private String queueName;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload", columnDefinition = "jsonb", nullable = false)
    private String payload;

    @Column(name = "error", columnDefinition = "text", nullable = false)
    private String error;

    @Column(name = "retryCount", nullable = false)
    private int retryCount;

    @CreationTimestamp
    @Column(name = "failedAt", nullable = false, updatable = false)
    private LocalDateTime failedAt;

    public DlqJob() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }

    public String getQueueName() { return queueName; }
    public void setQueueName(String queueName) { this.queueName = queueName; }

    public String getPayload() { return payload; }
    public void setPayload(String payload) { this.payload = payload; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }

    public int getRetryCount() { return retryCount; }
    public void setRetryCount(int retryCount) { this.retryCount = retryCount; }

    public LocalDateTime getFailedAt() { return failedAt; }
    public void setFailedAt(LocalDateTime failedAt) { this.failedAt = failedAt; }
}
