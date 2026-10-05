package com.callhealth.ambulance.dto;

import java.util.List;

public record PaginatedResponse<T>(
        List<T> data,
        PaginationMeta meta
) {}
