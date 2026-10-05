package com.callhealth.ambulance.dto;

public record DriverInfoDto(
        String vendorDriverRef,
        String name,
        String phoneE164,
        String vehicleNumber,
        String ambulanceType
) {}
