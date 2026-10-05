package com.callhealth.ambulance.queue.model;

public class QueueJobMessage {
    private String jobId;
    private String queueName;
    private String jobName;
    private String payloadJson;
    private int attemptsMade;
    private int maxAttempts;
    private long executeAt;
    private long backoffDelayMs;
    private long createdAt;

    public QueueJobMessage() {}

    public QueueJobMessage(String jobId, String queueName, String jobName, String payloadJson, int attemptsMade, int maxAttempts, long executeAt, long backoffDelayMs, long createdAt) {
        this.jobId = jobId;
        this.queueName = queueName;
        this.jobName = jobName;
        this.payloadJson = payloadJson;
        this.attemptsMade = attemptsMade;
        this.maxAttempts = maxAttempts;
        this.executeAt = executeAt;
        this.backoffDelayMs = backoffDelayMs;
        this.createdAt = createdAt;
    }

    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }

    public String getQueueName() { return queueName; }
    public void setQueueName(String queueName) { this.queueName = queueName; }

    public String getJobName() { return jobName; }
    public void setJobName(String jobName) { this.jobName = jobName; }

    public String getPayloadJson() { return payloadJson; }
    public void setPayloadJson(String payloadJson) { this.payloadJson = payloadJson; }

    public int getAttemptsMade() { return attemptsMade; }
    public void setAttemptsMade(int attemptsMade) { this.attemptsMade = attemptsMade; }

    public int getMaxAttempts() { return maxAttempts; }
    public void setMaxAttempts(int maxAttempts) { this.maxAttempts = maxAttempts; }

    public long getExecuteAt() { return executeAt; }
    public void setExecuteAt(long executeAt) { this.executeAt = executeAt; }

    public long getBackoffDelayMs() { return backoffDelayMs; }
    public void setBackoffDelayMs(long backoffDelayMs) { this.backoffDelayMs = backoffDelayMs; }

    public long getCreatedAt() { return createdAt; }
    public void setCreatedAt(long createdAt) { this.createdAt = createdAt; }
}
