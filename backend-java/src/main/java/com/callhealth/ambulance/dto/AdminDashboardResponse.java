package com.callhealth.ambulance.dto;

public record AdminDashboardResponse(
        long totalRequests,
        long pendingRequests,
        long assignedRequests,
        long inProgressRequests,
        long completedRequests,
        long cancelledRequests
) {}
