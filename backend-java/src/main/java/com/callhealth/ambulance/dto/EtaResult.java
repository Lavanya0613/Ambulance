package com.callhealth.ambulance.dto;

public record EtaResult(
        int etaSeconds,
        double distanceKm,
        boolean hasArrived
) {}
