package com.callhealth.ambulance.dto;

public record WalletBenefitResponse(
        boolean ambulanceBenefitEligible,
        int ambulanceBenefitAmount
) {}
