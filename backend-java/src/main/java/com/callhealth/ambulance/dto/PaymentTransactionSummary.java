package com.callhealth.ambulance.dto;

import com.callhealth.ambulance.model.enums.PaymentStatus;

import java.util.UUID;

public record PaymentTransactionSummary(
        UUID id,
        PaymentStatus status,
        String transactionRef,
        Integer amount
) {}
