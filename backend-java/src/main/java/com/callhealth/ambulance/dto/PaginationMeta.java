package com.callhealth.ambulance.dto;

public record PaginationMeta(
        long total,
        int page,
        int limit,
        int totalPages
) {}
