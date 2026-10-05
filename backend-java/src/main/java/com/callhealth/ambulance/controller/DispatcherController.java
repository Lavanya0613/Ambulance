package com.callhealth.ambulance.controller;

import com.callhealth.ambulance.dto.DispatcherDashboardResponse;
import com.callhealth.ambulance.dto.PaginatedResponse;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.service.DispatcherService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/dispatcher")
@CrossOrigin(originPatterns = "*")
public class DispatcherController {

    private final DispatcherService dispatcherService;

    public DispatcherController(DispatcherService dispatcherService) {
        this.dispatcherService = dispatcherService;
    }

    @GetMapping("/dashboard")
    public ResponseEntity<DispatcherDashboardResponse> getDashboardSummary() {
        return ResponseEntity.ok(dispatcherService.getDashboardSummary());
    }

    @GetMapping("/requests")
    public ResponseEntity<PaginatedResponse<AmbulanceRequest>> listRequests(
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "limit", defaultValue = "10") int limit,
            @RequestParam(value = "status", required = false) AmbulanceRequestStatus status
    ) {
        return ResponseEntity.ok(dispatcherService.listRequests(page, limit, status));
    }

    @GetMapping("/requests/{id}")
    public ResponseEntity<AmbulanceRequest> getRequestDetails(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(dispatcherService.getRequestDetails(id));
    }

    @PostMapping("/requests/{id}/accept")
    public ResponseEntity<AmbulanceRequest> acceptRequest(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(dispatcherService.acceptRequest(id));
    }

    @PostMapping("/requests/{id}/reject")
    public ResponseEntity<AmbulanceRequest> rejectRequest(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(dispatcherService.rejectRequest(id));
    }

    @PostMapping("/requests/{id}/assign-driver")
    public ResponseEntity<AmbulanceRequest> assignDriver(
            @PathVariable("id") UUID id,
            @RequestBody(required = false) java.util.Map<String, Object> body
    ) {
        String driverId = body != null && body.containsKey("driverId") ? String.valueOf(body.get("driverId")) : "drv-001";
        String vehicleId = body != null && body.containsKey("vehicleId") ? String.valueOf(body.get("vehicleId")) : "KA-01-EA-1234";
        Integer eta = body != null && body.containsKey("etaSeconds") ? Integer.parseInt(String.valueOf(body.get("etaSeconds"))) : 300;
        return ResponseEntity.ok(dispatcherService.assignDriver(id, driverId, vehicleId, eta));
    }

    @PatchMapping("/requests/{id}/status")
    public ResponseEntity<AmbulanceRequest> updateStatus(
            @PathVariable("id") UUID id,
            @RequestBody java.util.Map<String, String> body
    ) {
        AmbulanceRequestStatus status = AmbulanceRequestStatus.valueOf(body.get("status"));
        return ResponseEntity.ok(dispatcherService.updateStatus(id, status));
    }

    @PostMapping("/requests/{id}/location")
    public ResponseEntity<java.util.Map<String, Object>> updateLocation(
            @PathVariable("id") UUID id,
            @RequestBody java.util.Map<String, Object> body
    ) {
        double lat = Double.parseDouble(String.valueOf(body.get("lat")));
        double lng = Double.parseDouble(String.valueOf(body.get("lng")));
        double speed = body.containsKey("speed") ? Double.parseDouble(String.valueOf(body.get("speed"))) : 45.0;
        double heading = body.containsKey("heading") ? Double.parseDouble(String.valueOf(body.get("heading"))) : 90.0;
        dispatcherService.updateLocation(id, lat, lng, speed, heading);
        return ResponseEntity.ok(java.util.Map.of("success", true));
    }
}
