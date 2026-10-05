package com.callhealth.ambulance.dto;

import jakarta.validation.constraints.NotBlank;

public record CancelAmbulanceRequest(
        @NotBlank String reasonCode
) {}
