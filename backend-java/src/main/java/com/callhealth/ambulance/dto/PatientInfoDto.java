package com.callhealth.ambulance.dto;

import jakarta.validation.constraints.NotBlank;

public record PatientInfoDto(
        @NotBlank String name,
        @NotBlank String phoneE164,
        Integer age,
        String notes
) {}
