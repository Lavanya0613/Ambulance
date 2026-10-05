package com.callhealth.ambulance.dto;

import java.util.UUID;

public record PaymentStatusResponse(
        UUID requestId,
        String paymentStatus,
        String transactionRef,
        Integer baseFare,
        Integer walletDiscount,
        Integer totalPayable,
        PaymentTransactionSummary tx
) {}
