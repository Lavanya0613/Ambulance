package com.callhealth.ambulance.dto;

public record QueueStatusResponse(
        long waiting,
        long active,
        long completed,
        long failed,
        long delayed,
        long paused,
        long deadLetter,
        QueueMetricsMap metrics
) {}
