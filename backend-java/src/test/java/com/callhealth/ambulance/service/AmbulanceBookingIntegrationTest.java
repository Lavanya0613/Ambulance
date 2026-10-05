package com.callhealth.ambulance.service;

import com.callhealth.ambulance.common.exception.BadRequestException;
import com.callhealth.ambulance.dto.*;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class AmbulanceBookingIntegrationTest {

    @Autowired
    private PatientRequestService patientRequestService;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    @Test
    @DisplayName("1. Valid immediate booking (Book Now) sets status to REQUEST_RECEIVED and calculates fare")
    void testValidBooking() {
        RequestAmbulanceRequest request = new RequestAmbulanceRequest(
                "IDEM-TEST-101",
                new LocationDto(17.43088, 78.43373, "Yousufguda, Hyderabad"),
                new LocationDto(17.44088, 78.44373, "Yashoda Hospitals, Hyderabad"),
                "high",
                new PatientInfoDto("John Doe", "+919876543210", 30, "Urgent care needed"),
                "Handle with care",
                null,
                true,
                "ALS"
        );

        RequestAmbulanceResponse response = patientRequestService.createRequest(request, "patient-test-01");

        assertNotNull(response.requestId());
        assertNotNull(response.requestNumber());
        assertEquals(AmbulanceRequestStatus.REQUEST_RECEIVED, response.status());
        assertEquals(2500, response.baseFare()); // ALS fare
        assertEquals(50, response.walletDiscount());
        assertEquals(2450, response.totalPayable());
        assertEquals("PENDING", response.paymentStatus());

        // Verify Database Persistence
        AmbulanceRequest savedEntity = requestRepository.findById(response.requestId()).orElse(null);
        assertNotNull(savedEntity);
        assertEquals("John Doe", savedEntity.getPatientName());
        assertEquals("IDEM-TEST-101", savedEntity.getIdempotencyKey());
    }

    @Test
    @DisplayName("2. Idempotent request returns existing booking")
    void testIdempotency() {
        RequestAmbulanceRequest request = new RequestAmbulanceRequest(
                "IDEM-REPEAT-001",
                new LocationDto(17.43088, 78.43373, "Pickup A"),
                new LocationDto(17.44088, 78.44373, "Drop B"),
                "normal",
                new PatientInfoDto("Jane Doe", "+919876543211", null, null),
                null,
                null,
                false,
                "BLS"
        );

        RequestAmbulanceResponse firstResponse = patientRequestService.createRequest(request, "patient-test-02");
        RequestAmbulanceResponse duplicateResponse = patientRequestService.createRequest(request, "patient-test-02");

        assertEquals(firstResponse.requestId(), duplicateResponse.requestId());
        assertEquals(firstResponse.requestNumber(), duplicateResponse.requestNumber());
        assertTrue(duplicateResponse.message().contains("Returned existing request"));
    }

    @Test
    @DisplayName("3. Scheduled booking (Book Later) sets status to SCHEDULED")
    void testScheduledBooking() {
        Instant futureTime = Instant.now().plusSeconds(3600); // 1 hour in future
        RequestAmbulanceRequest request = new RequestAmbulanceRequest(
                "IDEM-SCHED-001",
                new LocationDto(17.43088, 78.43373, "Pickup Scheduled"),
                new LocationDto(17.44088, 78.44373, "Drop Scheduled"),
                "normal",
                new PatientInfoDto("Alice Smith", "+919876543212", null, null),
                "Scheduled visit",
                futureTime,
                false,
                "ICU"
        );

        RequestAmbulanceResponse response = patientRequestService.createRequest(request, "patient-test-03");

        assertEquals(AmbulanceRequestStatus.SCHEDULED, response.status());
        assertEquals(3500, response.baseFare()); // ICU fare
    }

    @Test
    @DisplayName("4. Valid Cancellation transitions status to CANCELLED")
    void testCancellation() {
        RequestAmbulanceRequest request = new RequestAmbulanceRequest(
                "IDEM-CANCEL-001",
                new LocationDto(17.43088, 78.43373, "Pickup C"),
                new LocationDto(17.44088, 78.44373, "Drop C"),
                "normal",
                new PatientInfoDto("Bob Vance", "+919876543213", null, null),
                null,
                null,
                false,
                "BLS"
        );

        RequestAmbulanceResponse booking = patientRequestService.createRequest(request, "patient-test-04");

        CancelAmbulanceRequest cancelReq = new CancelAmbulanceRequest("patient_changed_mind");
        CancelAmbulanceResponse cancelResp = patientRequestService.cancelRequest(booking.requestId(), cancelReq, "patient-test-04");

        assertEquals(booking.requestId(), cancelResp.requestId());
        assertEquals(AmbulanceRequestStatus.CANCELLED, cancelResp.status());

        AmbulanceRequest cancelledEntity = requestRepository.findById(booking.requestId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.CANCELLED, cancelledEntity.getStatus());
        assertEquals("patient_changed_mind", cancelledEntity.getCancelReason());
    }

    @Test
    @DisplayName("5. Uncancelable Status Transition Protection throws BadRequestException")
    void testUncancelableStatusTransition() {
        AmbulanceRequest request = new AmbulanceRequest();
        request.setRequestNumber("AR-TEST-COMPLETED");
        request.setStatus(AmbulanceRequestStatus.COMPLETED);
        request.setPatientName("Test Patient");
        request.setPatientPhone("+919999999999");
        request.setPickupLat(17.4);
        request.setPickupLng(78.4);
        request.setDropLat(17.5);
        request.setDropLng(78.5);
        request = requestRepository.save(request);

        final UUID id = request.getId();
        CancelAmbulanceRequest cancelReq = new CancelAmbulanceRequest("try_cancel");

        assertThrows(BadRequestException.class, () -> patientRequestService.cancelRequest(id, cancelReq, "patient-test"));
    }
}
