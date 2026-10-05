package com.callhealth.ambulance.queue.model;

import com.callhealth.ambulance.dto.LocationDto;
import com.callhealth.ambulance.dto.PatientInfoDto;

public record CreateBookingPayload(
        String requestId,
        String idempotencyKey,
        LocationDto pickup,
        LocationDto drop,
        String priority,
        PatientInfoDto patient,
        String notes,
        String scheduledFor,
        String preferredVendorId
) {}
