package com.callhealth.ambulance.dto;

import java.time.Instant;

public record LastLocationDto(
        String vendorEventId,
        double lat,
        double lng,
        Double speedKmph,
        Double headingDeg,
        Instant capturedAt
) {}
