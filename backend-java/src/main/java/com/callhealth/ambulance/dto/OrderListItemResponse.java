package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

public record OrderListItemResponse(
        UUID requestId,
        String requestNumber,
        AmbulanceRequestStatus status,
        String priority,
        String patientName,
        String patientPhone,
        String pickupAddress,
        double pickupLat,
        double pickupLng,
        String dropAddress,
        double dropLat,
        double dropLng,
        String assignedVendorId,
        String ambulanceType,
        DriverInfoDto driver,
        Integer etaSeconds,
        String cancelReason,
        Integer baseFare,
        Integer walletDiscount,
        Integer totalPayable,
        Instant scheduledFor,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
