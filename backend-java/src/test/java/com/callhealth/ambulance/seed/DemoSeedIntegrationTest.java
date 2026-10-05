package com.callhealth.ambulance.seed;

import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class DemoSeedIntegrationTest {

    @Autowired
    private DemoSeedService demoSeedService;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    @Test
    @DisplayName("1. Seed Demo Data creates all 6 ambulance status scenarios")
    void testSeedDemoDataCreatesAllSixScenarios() {
        List<AmbulanceRequest> seeded = demoSeedService.seedDemoData("patient-seed-test-01");
        assertEquals(6, seeded.size(), "Should seed 6 demo records");

        Map<String, AmbulanceRequestStatus> statusMap = requestRepository.findAll().stream()
                .filter(r -> r.getRequestNumber() != null && r.getRequestNumber().startsWith("AR-DEMO-"))
                .collect(Collectors.toMap(AmbulanceRequest::getRequestNumber, AmbulanceRequest::getStatus));

        assertEquals(6, statusMap.size(), "Database must contain all 6 AR-DEMO- records");
        assertEquals(AmbulanceRequestStatus.SCHEDULED, statusMap.get("AR-DEMO-101"));
        assertEquals(AmbulanceRequestStatus.SEARCHING, statusMap.get("AR-DEMO-102"));
        assertEquals(AmbulanceRequestStatus.EN_ROUTE, statusMap.get("AR-DEMO-103"));
        assertEquals(AmbulanceRequestStatus.ARRIVED, statusMap.get("AR-DEMO-104"));
        assertEquals(AmbulanceRequestStatus.COMPLETED, statusMap.get("AR-DEMO-105"));
        assertEquals(AmbulanceRequestStatus.CANCELLED, statusMap.get("AR-DEMO-106"));
    }

    @Test
    @DisplayName("2. Seed Demo Data is idempotent and prevents duplicate records")
    void testSeedDemoDataIsIdempotentWithoutDuplicates() {
        demoSeedService.seedDemoData("patient-seed-test-02");
        demoSeedService.seedDemoData("patient-seed-test-02"); // Re-run seed

        long count = requestRepository.findAll().stream()
                .filter(r -> r.getRequestNumber() != null && r.getRequestNumber().startsWith("AR-DEMO-"))
                .count();

        assertEquals(6, count, "Re-running seed must NOT create duplicate records");
    }

    @Test
    @DisplayName("3. Reset Demo Data removes only AR-DEMO-% records, preserving real bookings")
    void testResetDemoDataRemovesOnlyDemoRecords() {
        // Create a non-demo request
        AmbulanceRequest realBooking = new AmbulanceRequest();
        realBooking.setRequestNumber("AR-REAL-999");
        realBooking.setStatus(AmbulanceRequestStatus.REQUEST_RECEIVED);
        realBooking.setPatientName("Real Patient");
        realBooking.setPatientPhone("+919999911111");
        realBooking.setPickupLat(17.43);
        realBooking.setPickupLng(78.43);
        realBooking.setDropLat(17.45);
        realBooking.setDropLng(78.45);
        requestRepository.save(realBooking);

        demoSeedService.seedDemoData("patient-seed-test-03");

        int resetCount = demoSeedService.resetDemoData();
        assertEquals(6, resetCount, "Reset should report 6 removed demo records");

        assertTrue(requestRepository.findByRequestNumber("AR-REAL-999").isPresent(), "Non-demo booking must be preserved");
        assertTrue(requestRepository.findByRequestNumber("AR-DEMO-101").isEmpty(), "Demo booking AR-DEMO-101 must be deleted");
    }
}
