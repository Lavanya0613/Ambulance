package com.callhealth.ambulance.dto;

public record DispatcherDashboardResponse(
        long todaysRequests,
        long pending,
        long assigned,
        long enroute,
        long completed,
        long cancelled,
        long driversAvailable,
        long driversBusy,
        long queueSize,
        long averageEta,
        long averageTripTime
) {}
