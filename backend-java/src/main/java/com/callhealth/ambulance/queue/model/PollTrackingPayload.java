package com.callhealth.ambulance.queue.model;

public record PollTrackingPayload(
        String requestId,
        String vendorId,
        String vendorBookingRef,
        String since
) {}
