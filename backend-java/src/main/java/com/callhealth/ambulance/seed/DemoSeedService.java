package com.callhealth.ambulance.seed;

import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class DemoSeedService {

    private static final Logger log = LoggerFactory.getLogger(DemoSeedService.class);

    private final AmbulanceRequestRepository requestRepository;

    public DemoSeedService(AmbulanceRequestRepository requestRepository) {
        this.requestRepository = requestRepository;
    }

    @Transactional
    public List<AmbulanceRequest> seedDemoData(String patientId) {
        String targetPatientId = (patientId != null && !patientId.isBlank()) ? patientId : "demo-patient-uuid";
        log.info("[SEED] Starting demo data seeding for patientId={}", targetPatientId);

        Instant now = Instant.now();
        Instant futureDate = now.plus(24, ChronoUnit.HOURS);

        List<AmbulanceRequest> demoRecords = new ArrayList<>();

        // 1. Scheduled
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-101",
                AmbulanceRequestStatus.SCHEDULED,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "TOWER-1 BLOCK-D, GRT GROUP PHASE-2, Yousufguda, Hyderabad", 17.43088, 78.43373,
                "Yashoda Hospitals, Hitec City, Hyderabad", 17.4470, 78.3756,
                futureDate, "normal", null, null, null, null, null, null, 2500, 0, 2500, "SUCCESS", null
        ));

        // 2. Searching
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-102",
                AmbulanceRequestStatus.SEARCHING,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "Banjara Hills Road No 1, Hyderabad", 17.4156, 78.4485,
                "Care Hospital, Road No 1, Banjara Hills, Hyderabad", 17.4123, 78.4499,
                null, "high", null, null, null, null, null, null, 1250, 0, 1250, "SUCCESS", null
        ));

        // 3. Driver Assigned / En Route
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-103",
                AmbulanceRequestStatus.EN_ROUTE,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "Jubilee Hills Check Post, Hyderabad", 17.4325, 78.4071,
                "Apollo Hospitals, Jubilee Hills, Hyderabad", 17.4262, 78.4116,
                null, "critical", "DRV-8821", "Ravi Kumar", "+919999998888", "MO-01-9012", "ALS", 360, 2500, 0, 2500, "SUCCESS", null
        ));

        // 4. Arrived
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-104",
                AmbulanceRequestStatus.ARRIVED,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "Madhapur Metro Station, Hyderabad", 17.4483, 78.3915,
                "Medicover Hospital, Madhapur, Hyderabad", 17.4431, 78.3842,
                null, "high", "DRV-4412", "Suresh Verma", "+919888887777", "MO-02-4412", "ICU", 0, 3500, 0, 3500, "SUCCESS", null
        ));

        // 5. Completed
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-105",
                AmbulanceRequestStatus.COMPLETED,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "Gachibowli DLF Cybercity, Hyderabad", 17.4475, 78.3582,
                "Continental Hospital, Gachibowli, Hyderabad", 17.4398, 78.3429,
                null, "normal", "DRV-1209", "Vikram Singh", "+919777776666", "MO-01-1209", "Standard", null, 1250, 0, 1250, "SUCCESS", null
        ));

        // 6. Cancelled
        demoRecords.add(createOrUpdateDemoRecord(
                "AR-DEMO-106",
                AmbulanceRequestStatus.CANCELLED,
                targetPatientId,
                "Demo Patient",
                "+919876543210",
                "Kukatpally Housing Board, Hyderabad", 17.4849, 78.3888,
                "KIMS Hospital, Kondapur, Hyderabad", 17.4654, 78.3664,
                null, "normal", null, null, null, null, null, null, 1250, 0, 1250, "CANCELLED", "patient_cancelled"
        ));

        log.info("[SEED] Successfully seeded {} demo ambulance records for testing states!", demoRecords.size());
        return demoRecords;
    }

    @Transactional
    public int resetDemoData() {
        log.info("[SEED] Resetting demo data records (AR-DEMO-%)");
        List<AmbulanceRequest> demoReqs = requestRepository.findAll().stream()
                .filter(r -> r.getRequestNumber() != null && r.getRequestNumber().startsWith("AR-DEMO-"))
                .toList();

        int count = demoReqs.size();
        requestRepository.deleteAll(demoReqs);
        log.info("[SEED] Removed {} demo records", count);
        return count;
    }

    private AmbulanceRequest createOrUpdateDemoRecord(
            String reqNumber,
            AmbulanceRequestStatus status,
            String patientId,
            String patientName,
            String patientPhone,
            String pickupAddress, double pickupLat, double pickupLng,
            String dropAddress, double dropLat, double dropLng,
            Instant scheduledFor,
            String priority,
            String driverRef, String driverName, String driverPhone, String vehicleNo, String ambType,
            Integer etaSeconds,
            Integer baseFare, Integer walletDiscount, Integer totalPayable,
            String paymentStatus,
            String cancelReason
    ) {
        Optional<AmbulanceRequest> existingOpt = requestRepository.findByRequestNumber(reqNumber);
        AmbulanceRequest req = existingOpt.orElseGet(AmbulanceRequest::new);

        req.setRequestNumber(reqNumber);
        req.setStatus(status);
        req.setPatientId(patientId);
        req.setPatientName(patientName);
        req.setPatientPhone(patientPhone);
        req.setPickupAddress(pickupAddress);
        req.setPickupLat(pickupLat);
        req.setPickupLng(pickupLng);
        req.setDropAddress(dropAddress);
        req.setDropLat(dropLat);
        req.setDropLng(dropLng);
        req.setScheduledFor(scheduledFor);
        req.setPriority(priority);
        req.setVendorDriverRef(driverRef);
        req.setVendorDriverName(driverName);
        req.setVendorDriverPhone(driverPhone);
        req.setVendorVehicleNumber(vehicleNo);
        req.setVendorAmbulanceType(ambType);
        req.setEtaSeconds(etaSeconds);
        req.setBaseFare(baseFare);
        req.setWalletDiscount(walletDiscount != null ? walletDiscount : 0);
        req.setTotalPayable(totalPayable);
        req.setPaymentStatus(paymentStatus);
        req.setCancelReason(cancelReason);

        return requestRepository.save(req);
    }
}
