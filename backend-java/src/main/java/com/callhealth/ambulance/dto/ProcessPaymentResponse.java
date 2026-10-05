package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.PaymentStatus;

public record ProcessPaymentResponse(
        PaymentStatus status,
        String paymentStatus,
        String transactionId,
        String transactionRef,
        Integer amount,
        String paymentMethod,
        String message
) {
    public ProcessPaymentResponse(PaymentStatus status, String paymentStatus, String message) {
        this(status, paymentStatus, null, null, null, null, message);
    }
}
