package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record CancelAmbulanceResponse(
        UUID requestId,
        LocalDateTime cancelledAt,
        AmbulanceRequestStatus status,
        String message
) {}
