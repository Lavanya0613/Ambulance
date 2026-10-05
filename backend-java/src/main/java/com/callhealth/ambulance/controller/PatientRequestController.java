package com.callhealth.ambulance.controller;

import com.callhealth.ambulance.dto.*;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.service.PatientRequestService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/patient/requests")
@CrossOrigin(originPatterns = "*")
public class PatientRequestController {

    private final PatientRequestService patientRequestService;
    private final com.callhealth.ambulance.seed.DemoSeedService demoSeedService;

    public PatientRequestController(
            PatientRequestService patientRequestService,
            com.callhealth.ambulance.seed.DemoSeedService demoSeedService
    ) {
        this.patientRequestService = patientRequestService;
        this.demoSeedService = demoSeedService;
    }

    @PostMapping("/seed-demo-data")
    public ResponseEntity<java.util.Map<String, Object>> seedDemoData(@RequestHeader(value = "x-patient-id", required = false) String patientId) {
        var records = demoSeedService.seedDemoData(patientId);
        return ResponseEntity.ok(java.util.Map.of(
                "success", true,
                "message", "Seeded " + records.size() + " demo records successfully",
                "count", records.size()
        ));
    }

    @PostMapping("/reset-demo-data")
    public ResponseEntity<java.util.Map<String, Object>> resetDemoData() {
        int count = demoSeedService.resetDemoData();
        return ResponseEntity.ok(java.util.Map.of(
                "success", true,
                "message", "Reset " + count + " demo records successfully",
                "count", count
        ));
    }

    @PostMapping
    public ResponseEntity<RequestAmbulanceResponse> requestAmbulance(
            @Valid @RequestBody RequestAmbulanceRequest request,
            @RequestHeader(value = "x-patient-id", required = false) String patientId
    ) {
        RequestAmbulanceResponse response = patientRequestService.createRequest(request, patientId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/{requestId}/cancel")
    public ResponseEntity<CancelAmbulanceResponse> cancelAmbulance(
            @PathVariable("requestId") UUID requestId,
            @Valid @RequestBody CancelAmbulanceRequest dto,
            @RequestHeader(value = "x-patient-id", required = false) String patientId
    ) {
        CancelAmbulanceResponse response = patientRequestService.cancelRequest(requestId, dto, patientId);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/wallet")
    public ResponseEntity<WalletBenefitResponse> getWallet(@RequestParam(value = "patientId", required = false) String patientId) {
        return ResponseEntity.ok(patientRequestService.getWallet(patientId));
    }

    @GetMapping("/{requestId}/track")
    public ResponseEntity<TrackingSnapshotResponse> trackAmbulance(@PathVariable("requestId") UUID requestId) {
        return ResponseEntity.ok(patientRequestService.getTrackingSnapshot(requestId));
    }

    @GetMapping("/{requestId}")
    public ResponseEntity<AmbulanceRequest> getRequestById(@PathVariable("requestId") UUID requestId) {
        return ResponseEntity.ok(patientRequestService.getRequestById(requestId));
    }

    @GetMapping
    public ResponseEntity<PaginatedResponse<OrderListItemResponse>> listRequests(
            @RequestParam(value = "patientId", required = false) String patientId,
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "fromDate", required = false) String fromDate,
            @RequestParam(value = "toDate", required = false) String toDate,
            @RequestParam(value = "page", defaultValue = "1") int page,
            @RequestParam(value = "limit", defaultValue = "10") int limit,
            @RequestParam(value = "sortBy", defaultValue = "createdAt") String sortBy,
            @RequestParam(value = "sortOrder", defaultValue = "DESC") String sortOrder,
            @RequestHeader(value = "x-patient-id", required = false) String headerPatientId
    ) {
        String effectivePatientId = (patientId != null && !patientId.isBlank()) ? patientId : headerPatientId;
        return ResponseEntity.ok(patientRequestService.listRequests(effectivePatientId, status, fromDate, toDate, page, limit, sortBy, sortOrder));
    }

    @PostMapping("/{requestId}/payment/initiate")
    public ResponseEntity<PaymentInitiateResponse> initiatePayment(
            @PathVariable("requestId") UUID requestId,
            @RequestHeader(value = "x-patient-id", required = false) String patientId
    ) {
        return ResponseEntity.ok(patientRequestService.initiatePayment(requestId, patientId));
    }

    @PostMapping("/{requestId}/payment/process")
    public ResponseEntity<ProcessPaymentResponse> processPayment(
            @PathVariable("requestId") UUID requestId,
            @RequestBody(required = false) ProcessPaymentRequest body,
            @RequestHeader(value = "x-patient-id", required = false) String patientId
    ) {
        return ResponseEntity.ok(patientRequestService.processPayment(requestId, body, patientId));
    }

    @GetMapping("/{requestId}/payment/status")
    public ResponseEntity<PaymentStatusResponse> getPaymentStatus(
            @PathVariable("requestId") UUID requestId,
            @RequestHeader(value = "x-patient-id", required = false) String patientId
    ) {
        return ResponseEntity.ok(patientRequestService.getPaymentStatus(requestId, patientId));
    }
}
