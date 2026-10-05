package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record TrackingSnapshotResponse(
        UUID requestId,
        String requestNumber,
        AmbulanceRequestStatus status,
        String patientName,
        String pickupAddress,
        double pickupLat,
        double pickupLng,
        String dropAddress,
        double dropLat,
        double dropLng,
        DriverInfoDto driver,
        Integer etaSeconds,
        LastLocationDto lastLocation,
        LocalDateTime updatedAt
) {}
