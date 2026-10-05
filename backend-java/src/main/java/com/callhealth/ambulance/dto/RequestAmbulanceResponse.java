package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record RequestAmbulanceResponse(
        UUID requestId,
        String requestNumber,
        AmbulanceRequestStatus status,
        LocalDateTime createdAt,
        String assignedVendor,
        String message,
        Integer baseFare,
        Integer walletDiscount,
        Integer totalPayable,
        String paymentStatus
) {}
