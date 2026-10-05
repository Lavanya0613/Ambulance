package com.callhealth.ambulance.dto;

public record QueueMetricsMap(
        QueueCountMetrics bookingQueue,
        QueueCountMetrics trackingQueue
) {}
