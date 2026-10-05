package com.callhealth.ambulance.dto;

public record QueueCountMetrics(
        long waiting,
        long active,
        long completed,
        long failed,
        long delayed,
        long paused
) {
    public static QueueCountMetrics empty() {
        return new QueueCountMetrics(0, 0, 0, 0, 0, 0);
    }
}
