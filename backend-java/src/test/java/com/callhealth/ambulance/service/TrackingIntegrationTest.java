package com.callhealth.ambulance.service;

import com.callhealth.ambulance.dto.EtaResult;
import com.callhealth.ambulance.dto.LocationDto;
import com.callhealth.ambulance.dto.PatientInfoDto;
import com.callhealth.ambulance.dto.RequestAmbulanceRequest;
import com.callhealth.ambulance.dto.RequestAmbulanceResponse;
import com.callhealth.ambulance.dto.TrackingSnapshotResponse;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.TrackingPosition;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.worker.TrackingQueueWorker;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.TrackingPositionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class TrackingIntegrationTest {

    @Autowired
    private PatientRequestService patientRequestService;

    @Autowired
    private EtaService etaService;

    @Autowired
    private TrackingQueueWorker trackingQueueWorker;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    @Autowired
    private TrackingPositionRepository positionRepository;

    private AmbulanceRequest createTestRequest(AmbulanceRequestStatus status) {
        AmbulanceRequest req = new AmbulanceRequest();
        req.setRequestNumber("AR-TRACK-" + System.nanoTime());
        req.setStatus(status);
        req.setPatientName("Tracking Test Patient");
        req.setPatientPhone("+919876543210");
        req.setPickupLat(17.4300);
        req.setPickupLng(78.4300);
        req.setPickupAddress("Pickup Point");
        req.setDropLat(17.4500);
        req.setDropLng(78.4500);
        req.setDropAddress("Drop Hospital");
        req.setBaseFare(1250);
        req.setTotalPayable(1250);
        req.setPaymentStatus("SUCCESS");
        return requestRepository.save(req);
    }

    @Test
    @DisplayName("1. SEARCHING State Guardrails: No driver, no fake location, no fake ARRIVED state")
    void testSearchingStateGuardrails() {
        RequestAmbulanceRequest req = new RequestAmbulanceRequest(
                "IDEM-TRACK-SEARCHING",
                new LocationDto(17.4300, 78.4300, "Pickup"),
                new LocationDto(17.4500, 78.4500, "Drop"),
                "normal",
                new PatientInfoDto("Patient Search", "+919876543210", 30, null),
                null,
                null,
                false,
                "BLS"
        );

        RequestAmbulanceResponse booking = patientRequestService.createRequest(req, "patient-search-01");
        assertEquals(AmbulanceRequestStatus.REQUEST_RECEIVED, booking.status());

        TrackingSnapshotResponse snapshot = patientRequestService.getTrackingSnapshot(booking.requestId());
        assertNotNull(snapshot);
        assertNull(snapshot.driver(), "SEARCHING status must return driver as null");
        assertNull(snapshot.lastLocation(), "SEARCHING status must return lastLocation as null when no tracking points exist");
        assertNotEquals(AmbulanceRequestStatus.ARRIVED, snapshot.status(), "SEARCHING status must not be fake ARRIVED");
    }

    @Test
    @DisplayName("2. DRIVER_ASSIGNED / ON_THE_WAY State returns driver information")
    void testDriverAssignedState() {
        AmbulanceRequest req = createTestRequest(AmbulanceRequestStatus.DRIVER_ASSIGNED);
        req.setVendorDriverRef("DRV-101");
        req.setVendorDriverName("Rajesh Driver");
        req.setVendorDriverPhone("+919876543210");
        req.setVendorVehicleNumber("TS-09-AB-1234");
        req.setVendorAmbulanceType("ALS");
        req.setAssignedVendorId("mock");
        requestRepository.save(req);

        TrackingSnapshotResponse snapshot = patientRequestService.getTrackingSnapshot(req.getId());
        assertNotNull(snapshot);
        assertNotNull(snapshot.driver(), "DRIVER_ASSIGNED status must return driver info");
        assertEquals("DRV-101", snapshot.driver().vendorDriverRef());
        assertEquals("Rajesh Driver", snapshot.driver().name());
        assertEquals("TS-09-AB-1234", snapshot.driver().vehicleNumber());
    }

    @Test
    @DisplayName("3. EN_ROUTE to ARRIVED Transition when within 50m of pickup")
    void testEnRouteToArrivedTransition() {
        AmbulanceRequest req = createTestRequest(AmbulanceRequestStatus.EN_ROUTE);
        req.setVendorDriverRef("DRV-102");
        req.setVendorDriverName("Suresh");
        req.setVendorDriverPhone("+919876543211");
        req.setVendorVehicleNumber("TS-09-AB-5678");
        req.setVendorAmbulanceType("BLS");
        req.setAssignedVendorId("mock");
        req.setPickupLat(17.43000);
        req.setPickupLng(78.43000);
        req = requestRepository.save(req);

        // Record a position point at the pickup location (0m distance)
        TrackingPosition pos = new TrackingPosition();
        pos.setAmbulanceRequest(req);
        pos.setVendorEventId("TEST_EVT_" + System.nanoTime());
        pos.setLat(17.43000);
        pos.setLng(78.43000);
        pos.setCapturedAt(Instant.now());
        positionRepository.save(pos);

        // Execute tracking poll at pickup location
        PollTrackingPayload payload = new PollTrackingPayload(req.getId().toString(), "mock", "VND-REF", null);
        trackingQueueWorker.executeTrackingPoll(payload);

        AmbulanceRequest updated = requestRepository.findById(req.getId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.ARRIVED, updated.getStatus(), "Should transition to ARRIVED when within 50m threshold");
    }

    @Test
    @DisplayName("4. TRIP_STARTED to DESTINATION_REACHED Transition when within 50m of drop")
    void testTripStartedToDestinationReachedTransition() {
        AmbulanceRequest req = createTestRequest(AmbulanceRequestStatus.TRIP_STARTED);
        req.setVendorDriverRef("DRV-103");
        req.setDropLat(17.45000);
        req.setDropLng(78.45000);
        req = requestRepository.save(req);

        // Record a position point at the drop location (0m distance)
        TrackingPosition pos = new TrackingPosition();
        pos.setAmbulanceRequest(req);
        pos.setVendorEventId("TEST_EVT_" + System.nanoTime());
        pos.setLat(17.45000);
        pos.setLng(78.45000);
        pos.setCapturedAt(Instant.now());
        positionRepository.save(pos);

        PollTrackingPayload payload = new PollTrackingPayload(req.getId().toString(), "mock", "VND-REF", null);
        trackingQueueWorker.executeTrackingPoll(payload);

        AmbulanceRequest updated = requestRepository.findById(req.getId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.DESTINATION_REACHED, updated.getStatus(), "Should transition to DESTINATION_REACHED when within 50m of drop target");
    }

    @Test
    @DisplayName("5. COMPLETED / CANCELLED Terminal State Protection")
    void testTerminalStateProtection() {
        AmbulanceRequest req = createTestRequest(AmbulanceRequestStatus.COMPLETED);
        PollTrackingPayload payload = new PollTrackingPayload(req.getId().toString(), "mock", "VND-REF", null);

        boolean isTerminal = trackingQueueWorker.executeTrackingPoll(payload);
        assertTrue(isTerminal, "Tracking poll should identify COMPLETED as terminal");

        AmbulanceRequest unchanged = requestRepository.findById(req.getId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.COMPLETED, unchanged.getStatus());
    }

    @Test
    @DisplayName("6. EtaService Distance and ETA Math Verification")
    void testEtaServiceCalculation() {
        // Distance ~2.22 km apart at 40 km/h
        EtaResult result = etaService.calculateEta(17.4300, 78.4300, 17.4500, 78.4500, 40.0, 0.05);

        assertFalse(result.hasArrived());
        assertTrue(result.distanceKm() > 2.0);
        assertTrue(result.etaSeconds() > 100);

        // Distance within threshold (< 0.05 km = 50m)
        EtaResult arrivedResult = etaService.calculateEta(17.43000, 78.43000, 17.43001, 78.43001, 40.0, 0.05);
        assertTrue(arrivedResult.hasArrived());
        assertEquals(0, arrivedResult.etaSeconds());
    }

    @Test
    @DisplayName("7. Verification of Dynamic Step-by-Step Position Movement and Persistence (Position 1 != Position 2 != Position 3)")
    void testDynamicStepByStepMovementAndPersistence() {
        AmbulanceRequest req = createTestRequest(AmbulanceRequestStatus.DRIVER_ASSIGNED);
        PollTrackingPayload payload = new PollTrackingPayload(req.getId().toString(), "mock", "VND-100", null);

        // Execute Poll 1
        trackingQueueWorker.executeTrackingPoll(payload);
        List<TrackingPosition> list1 = positionRepository.findByAmbulanceRequestIdOrderByCapturedAtAsc(req.getId());
        assertEquals(1, list1.size(), "After 1st poll, 1 position must be persisted");
        TrackingPosition pos1 = list1.get(0);

        // Execute Poll 2
        trackingQueueWorker.executeTrackingPoll(payload);
        List<TrackingPosition> list2 = positionRepository.findByAmbulanceRequestIdOrderByCapturedAtAsc(req.getId());
        assertEquals(2, list2.size(), "After 2nd poll, 2 positions must be persisted");
        TrackingPosition pos2 = list2.get(1);

        // Execute Poll 3
        trackingQueueWorker.executeTrackingPoll(payload);
        List<TrackingPosition> list3 = positionRepository.findByAmbulanceRequestIdOrderByCapturedAtAsc(req.getId());
        assertEquals(3, list3.size(), "After 3rd poll, 3 positions must be persisted");
        TrackingPosition pos3 = list3.get(2);

        // Verify Position 1 != Position 2 != Position 3
        assertNotEquals(pos1.getLat(), pos2.getLat(), "Position 1 lat must not equal Position 2 lat");
        assertNotEquals(pos2.getLat(), pos3.getLat(), "Position 2 lat must not equal Position 3 lat");

        // Verify progressive approach towards pickup coordinates (17.4300, 78.4300)
        double dist1 = com.callhealth.ambulance.util.GeoUtil.haversineDistanceMeters(pos1.getLat(), pos1.getLng(), req.getPickupLat(), req.getPickupLng());
        double dist2 = com.callhealth.ambulance.util.GeoUtil.haversineDistanceMeters(pos2.getLat(), pos2.getLng(), req.getPickupLat(), req.getPickupLng());
        double dist3 = com.callhealth.ambulance.util.GeoUtil.haversineDistanceMeters(pos3.getLat(), pos3.getLng(), req.getPickupLat(), req.getPickupLng());

        assertTrue(dist1 > dist2, "Dist 1 (" + dist1 + "m) must be > Dist 2 (" + dist2 + "m)");
        assertTrue(dist2 > dist3, "Dist 2 (" + dist2 + "m) must be > Dist 3 (" + dist3 + "m)");
    }
}
