package com.callhealth.ambulance.dto;

import jakarta.validation.constraints.NotNull;

public record LocationDto(
        @NotNull double lat,
        @NotNull double lng,
        String address
) {}
