package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.PaymentStatus;

public record PaymentInitiateResponse(
        String transactionId,
        PaymentStatus status,
        String message
) {
    public PaymentInitiateResponse(String transactionId, PaymentStatus status) {
        this(transactionId, status, null);
    }
}
