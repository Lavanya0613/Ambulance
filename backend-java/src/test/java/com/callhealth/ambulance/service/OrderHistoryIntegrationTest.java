package com.callhealth.ambulance.service;

import com.callhealth.ambulance.dto.OrderListItemResponse;
import com.callhealth.ambulance.dto.PaginatedResponse;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class OrderHistoryIntegrationTest {

    @Autowired
    private PatientRequestService patientRequestService;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    private AmbulanceRequest createTestRequest(String patientId, AmbulanceRequestStatus status, String reqNumber) {
        AmbulanceRequest req = new AmbulanceRequest();
        req.setRequestNumber(reqNumber);
        req.setStatus(status);
        req.setPatientId(patientId);
        req.setPatientName("History Patient");
        req.setPatientPhone("+919876543210");
        req.setPickupLat(17.4300);
        req.setPickupLng(78.4300);
        req.setPickupAddress("Apollo Hospital Pickup");
        req.setDropLat(17.4500);
        req.setDropLng(78.4500);
        req.setDropAddress("Yashoda Hospital Drop");
        req.setBaseFare(1500);
        req.setWalletDiscount(200);
        req.setTotalPayable(1300);
        req.setPaymentStatus("SUCCESS");
        return requestRepository.save(req);
    }

    @Test
    @DisplayName("1. Fetch Order History Pagination & Structure")
    void testFetchOrderHistoryPaginationAndStructure() {
        String patientId = "patient-hist-01";
        createTestRequest(patientId, AmbulanceRequestStatus.REQUEST_CREATED, "AR-HIST-001");
        createTestRequest(patientId, AmbulanceRequestStatus.DRIVER_ASSIGNED, "AR-HIST-002");
        createTestRequest(patientId, AmbulanceRequestStatus.COMPLETED, "AR-HIST-003");

        PaginatedResponse<OrderListItemResponse> response = patientRequestService.listRequests(
                patientId, null, null, null, 1, 10, "createdAt", "DESC"
        );

        assertNotNull(response);
        assertNotNull(response.data());
        assertEquals(3, response.meta().total());
        assertEquals(3, response.data().size());
        assertEquals(1, response.meta().page());

        OrderListItemResponse item = response.data().get(0);
        assertNotNull(item.requestId());
        assertNotNull(item.requestNumber());
        assertNotNull(item.status());
        assertEquals(1500, item.baseFare());
        assertEquals(200, item.walletDiscount());
        assertEquals(1300, item.totalPayable());
    }

    @Test
    @DisplayName("2. Filter Order History by Patient ID")
    void testFilterByPatientId() {
        createTestRequest("patient-A", AmbulanceRequestStatus.COMPLETED, "AR-PAT-A-01");
        createTestRequest("patient-B", AmbulanceRequestStatus.COMPLETED, "AR-PAT-B-01");

        PaginatedResponse<OrderListItemResponse> responseA = patientRequestService.listRequests(
                "patient-A", null, null, null, 1, 10, "createdAt", "DESC"
        );
        assertEquals(1, responseA.meta().total());
        assertEquals("AR-PAT-A-01", responseA.data().get(0).requestNumber());

        PaginatedResponse<OrderListItemResponse> responseB = patientRequestService.listRequests(
                "patient-B", null, null, null, 1, 10, "createdAt", "DESC"
        );
        assertEquals(1, responseB.meta().total());
        assertEquals("AR-PAT-B-01", responseB.data().get(0).requestNumber());
    }

    @Test
    @DisplayName("3. Filter Order History by Status (ACTIVE vs COMPLETED)")
    void testFilterByStatusActiveAndCompleted() {
        String patientId = "patient-status-filter";
        createTestRequest(patientId, AmbulanceRequestStatus.EN_ROUTE, "AR-ACT-01");
        createTestRequest(patientId, AmbulanceRequestStatus.COMPLETED, "AR-CMP-01");

        // Filter ACTIVE
        PaginatedResponse<OrderListItemResponse> activeRes = patientRequestService.listRequests(
                patientId, "ACTIVE", null, null, 1, 10, "createdAt", "DESC"
        );
        assertEquals(1, activeRes.meta().total());
        assertEquals(AmbulanceRequestStatus.EN_ROUTE, activeRes.data().get(0).status());

        // Filter COMPLETED
        PaginatedResponse<OrderListItemResponse> completedRes = patientRequestService.listRequests(
                patientId, "COMPLETED", null, null, 1, 10, "createdAt", "DESC"
        );
        assertEquals(1, completedRes.meta().total());
        assertEquals(AmbulanceRequestStatus.COMPLETED, completedRes.data().get(0).status());
    }

    @Test
    @DisplayName("4. Driver Info Guardrail: null when SEARCHING, populated when DRIVER_ASSIGNED")
    void testDriverInfoGuardrails() {
        String patientId = "patient-driver-guard";

        // 1. Searching Request
        AmbulanceRequest searchingReq = createTestRequest(patientId, AmbulanceRequestStatus.SEARCHING, "AR-DRV-SEARCH");
        searchingReq.setVendorDriverRef("DRV-UNASSIGNED"); // Should be ignored by service guardrail
        requestRepository.save(searchingReq);

        // 2. Assigned Request
        AmbulanceRequest assignedReq = createTestRequest(patientId, AmbulanceRequestStatus.DRIVER_ASSIGNED, "AR-DRV-ASSIGN");
        assignedReq.setVendorDriverRef("DRV-999");
        assignedReq.setVendorDriverName("Vikram Driver");
        assignedReq.setVendorDriverPhone("+919999988888");
        assignedReq.setVendorVehicleNumber("TS-08-XY-9999");
        assignedReq.setVendorAmbulanceType("ALS");
        requestRepository.save(assignedReq);

        PaginatedResponse<OrderListItemResponse> response = patientRequestService.listRequests(
                patientId, null, null, null, 1, 10, "createdAt", "DESC"
        );

        assertEquals(2, response.data().size());

        OrderListItemResponse assignedItem = response.data().stream()
                .filter(i -> i.requestNumber().equals("AR-DRV-ASSIGN"))
                .findFirst().orElseThrow();
        assertNotNull(assignedItem.driver(), "DRIVER_ASSIGNED status must include driver DTO");
        assertEquals("DRV-999", assignedItem.driver().vendorDriverRef());
        assertEquals("Vikram Driver", assignedItem.driver().name());

        OrderListItemResponse searchingItem = response.data().stream()
                .filter(i -> i.requestNumber().equals("AR-DRV-SEARCH"))
                .findFirst().orElseThrow();
        assertNull(searchingItem.driver(), "SEARCHING status must suppress driver DTO");
    }

    @Test
    @DisplayName("5. Date Range Filtering")
    void testDateRangeFiltering() {
        String patientId = "patient-date-filter";
        createTestRequest(patientId, AmbulanceRequestStatus.COMPLETED, "AR-DATE-01");

        String fromDate = LocalDateTime.now().minusDays(1).toString();
        String toDate = LocalDateTime.now().plusDays(1).toString();

        PaginatedResponse<OrderListItemResponse> response = patientRequestService.listRequests(
                patientId, null, fromDate, toDate, 1, 10, "createdAt", "DESC"
        );

        assertEquals(1, response.meta().total());
        assertEquals("AR-DATE-01", response.data().get(0).requestNumber());
    }
}
