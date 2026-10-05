package com.callhealth.ambulance.common.health;

import com.callhealth.ambulance.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/health/entities")
public class EntityVerificationController {

    private static final Logger log = LoggerFactory.getLogger(EntityVerificationController.class);

    private final AmbulanceRequestRepository ambulanceRequestRepository;
    private final TrackingPositionRepository trackingPositionRepository;
    private final PatientWalletRepository patientWalletRepository;
    private final PaymentTransactionRepository paymentTransactionRepository;
    private final DriverRepository driverRepository;
    private final AmbulanceVehicleRepository ambulanceVehicleRepository;
    private final SystemAuditLogRepository systemAuditLogRepository;
    private final DlqJobRepository dlqJobRepository;

    public EntityVerificationController(
            AmbulanceRequestRepository ambulanceRequestRepository,
            TrackingPositionRepository trackingPositionRepository,
            PatientWalletRepository patientWalletRepository,
            PaymentTransactionRepository paymentTransactionRepository,
            DriverRepository driverRepository,
            AmbulanceVehicleRepository ambulanceVehicleRepository,
            SystemAuditLogRepository systemAuditLogRepository,
            DlqJobRepository dlqJobRepository
    ) {
        this.ambulanceRequestRepository = ambulanceRequestRepository;
        this.trackingPositionRepository = trackingPositionRepository;
        this.patientWalletRepository = patientWalletRepository;
        this.paymentTransactionRepository = paymentTransactionRepository;
        this.driverRepository = driverRepository;
        this.ambulanceVehicleRepository = ambulanceVehicleRepository;
        this.systemAuditLogRepository = systemAuditLogRepository;
        this.dlqJobRepository = dlqJobRepository;
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> verifyEntities() {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", Instant.now().toString());
        Map<String, Object> entityStatus = new HashMap<>();
        boolean allPassed = true;

        allPassed &= verify("ambulance_requests", ambulanceRequestRepository::count, entityStatus);
        allPassed &= verify("tracking_positions", trackingPositionRepository::count, entityStatus);
        allPassed &= verify("patient_wallet", patientWalletRepository::count, entityStatus);
        allPassed &= verify("payment_transactions", paymentTransactionRepository::count, entityStatus);
        allPassed &= verify("drivers", driverRepository::count, entityStatus);
        allPassed &= verify("ambulance_vehicles", ambulanceVehicleRepository::count, entityStatus);
        allPassed &= verify("system_audit_logs", systemAuditLogRepository::count, entityStatus);
        allPassed &= verify("dead_letter_jobs", dlqJobRepository::count, entityStatus);

        response.put("allEntitiesMappedSuccessfully", allPassed);
        response.put("entityRecordCounts", entityStatus);

        return allPassed ? ResponseEntity.ok(response) : ResponseEntity.status(500).body(response);
    }

    private boolean verify(String entityName, SupplierWithException<Long> countSupplier, Map<String, Object> statusMap) {
        try {
            long count = countSupplier.get();
            statusMap.put(entityName, Map.of(
                "status", "MAPPED_SUCCESSFULLY",
                "recordCount", count
            ));
            return true;
        } catch (Exception e) {
            log.error("Failed to map entity {}: {}", entityName, e.getMessage(), e);
            statusMap.put(entityName, Map.of(
                "status", "MAPPING_FAILED",
                "error", e.getMessage()
            ));
            return false;
        }
    }

    @FunctionalInterface
    private interface SupplierWithException<T> {
        T get() throws Exception;
    }
}
