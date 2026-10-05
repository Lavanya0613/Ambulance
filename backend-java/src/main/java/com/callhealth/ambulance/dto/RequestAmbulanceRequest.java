package com.callhealth.ambulance.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record RequestAmbulanceRequest(
        String idempotencyKey,
        @NotNull @Valid LocationDto pickup,
        @NotNull @Valid LocationDto drop,
        String priority,
        @NotNull @Valid PatientInfoDto patient,
        String notes,
        Instant scheduledFor,
        Boolean applyWallet,
        String ambulanceType
) {}
