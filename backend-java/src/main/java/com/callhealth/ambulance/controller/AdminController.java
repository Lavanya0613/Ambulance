package com.callhealth.ambulance.controller;

import com.callhealth.ambulance.dto.AdminDashboardResponse;
import com.callhealth.ambulance.dto.PaginatedResponse;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.SystemAuditLog;
import com.callhealth.ambulance.service.AdminService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/admin")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/dashboard")
    public ResponseEntity<AdminDashboardResponse> getDashboard() {
        return ResponseEntity.ok(adminService.getDashboard());
    }

    @GetMapping("/requests")
    public ResponseEntity<PaginatedResponse<AmbulanceRequest>> getRequests(
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "limit", defaultValue = "10") int limit
    ) {
        return ResponseEntity.ok(adminService.getRequests(page, limit));
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<AmbulanceRequest> getRequestDetails(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(adminService.getRequestDetails(id));
    }

    @GetMapping("/audit-logs")
    public ResponseEntity<PaginatedResponse<SystemAuditLog>> getAuditLogs(
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "limit", defaultValue = "10") int limit
    ) {
        return ResponseEntity.ok(adminService.getAuditLogs(page, limit));
    }
}
