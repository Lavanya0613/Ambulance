package com.callhealth.ambulance.gateway;

import com.callhealth.ambulance.dto.DriverInfoDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class WebSocketIntegrationTest {

    @Autowired
    private WebSocketGateway webSocketGateway;

    @Test
    @DisplayName("1. Verify New Request Event Emission to Dispatcher Room")
    void testNewRequestEmission() {
        String reqId = UUID.randomUUID().toString();
        Map<String, Object> reqData = Map.of("requestId", reqId, "patientName", "Test Patient", "status", "REQUEST_RECEIVED");

        webSocketGateway.emitNewRequest(reqData);

        List<Map<String, Object>> log = webSocketGateway.getEmittedEventsLog();
        assertFalse(log.isEmpty(), "Event log should record emitted WebSocket events");

        Map<String, Object> lastEvent = log.get(log.size() - 1);
        assertEquals("request_created", lastEvent.get("event"));
        assertEquals("dispatcher-room", lastEvent.get("room"));
    }

    @Test
    @DisplayName("2. Verify Driver Assigned Event Emission")
    void testDriverAssignedEmission() {
        String reqId = UUID.randomUUID().toString();
        DriverInfoDto driver = new DriverInfoDto("DRV-777", "Ramesh", "+919876543210", "TS-09-AB-1234", "ALS");
        Map<String, Object> payload = Map.of("requestId", reqId, "driver", driver);

        webSocketGateway.emitAmbulanceAssigned(reqId, payload);

        List<Map<String, Object>> log = webSocketGateway.getEmittedEventsLog();
        Map<String, Object> assignedEvent = log.stream()
                .filter(e -> "driver_assigned".equals(e.get("event")) && ("request:" + reqId).equals(e.get("room")))
                .findFirst()
                .orElse(null);

        assertNotNull(assignedEvent, "Must record driver_assigned event targeting request room");
    }

    @Test
    @DisplayName("3. Verify Location and ETA Live Updates")
    void testLocationAndEtaUpdates() {
        String reqId = UUID.randomUUID().toString();
        Map<String, Object> pos = Map.of("requestId", reqId, "lat", 17.43, "lng", 78.43, "speedKmph", 35.0);

        webSocketGateway.emitLocationUpdated(reqId, pos);
        webSocketGateway.emitEtaUpdated(reqId, 240);

        List<Map<String, Object>> log = webSocketGateway.getEmittedEventsLog();

        boolean locationEmitted = log.stream().anyMatch(e -> "tracking_updated".equals(e.get("event")) && ("request:" + reqId).equals(e.get("room")));
        boolean etaEmitted = log.stream().anyMatch(e -> "eta_updated".equals(e.get("event")) && ("request:" + reqId).equals(e.get("room")));

        assertTrue(locationEmitted, "tracking_updated event must be logged");
        assertTrue(etaEmitted, "eta_updated event must be logged");
    }

    @Test
    @DisplayName("4. Verify Status Updated and Ride Completed Events")
    void testStatusUpdatedAndRideCompleted() {
        String reqId = UUID.randomUUID().toString();

        webSocketGateway.emitStatusUpdated(reqId, "ARRIVED", Map.of("requestId", reqId));
        webSocketGateway.emitRideCompleted(reqId, Map.of("requestId", reqId, "status", "COMPLETED"));

        List<Map<String, Object>> log = webSocketGateway.getEmittedEventsLog();

        boolean statusEmitted = log.stream().anyMatch(e -> "status_updated".equals(e.get("event")) && ("request:" + reqId).equals(e.get("room")));
        boolean completedEmitted = log.stream().anyMatch(e -> "request_completed".equals(e.get("event")) && ("request:" + reqId).equals(e.get("room")));

        assertTrue(statusEmitted, "status_updated event must be logged");
        assertTrue(completedEmitted, "request_completed event must be logged");
    }
}
