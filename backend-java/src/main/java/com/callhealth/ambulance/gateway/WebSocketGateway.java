package com.callhealth.ambulance.gateway;

import com.corundumstudio.socketio.AckRequest;
import com.corundumstudio.socketio.SocketIOClient;
import com.corundumstudio.socketio.SocketIOServer;
import com.corundumstudio.socketio.listener.ConnectListener;
import com.corundumstudio.socketio.listener.DataListener;
import com.corundumstudio.socketio.listener.DisconnectListener;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Component
public class WebSocketGateway {

    private static final Logger log = LoggerFactory.getLogger(WebSocketGateway.class);

    private final SocketIOServer server;
    private final Map<UUID, String> connectedClients = new ConcurrentHashMap<>();
    private final List<Map<String, Object>> emittedEventsLog = new CopyOnWriteArrayList<>();

    public WebSocketGateway(SocketIOServer server) {
        this.server = server;
    }

    @PostConstruct
    public void registerListeners() {
        if (server == null) return;

        server.addConnectListener(new ConnectListener() {
            @Override
            public void onConnect(SocketIOClient client) {
                String token = client.getHandshakeData().getSingleUrlParam("token");
                String userId = (token != null && !token.isBlank()) ? token : "dev-patient-01";
                connectedClients.put(client.getSessionId(), userId);
                log.info("[WEBSOCKET] Client connected: [{}] userId={}", client.getSessionId(), userId);

                client.joinRoom("user:" + userId);
                client.joinRoom("dispatcher-room");
            }
        });

        server.addDisconnectListener(new DisconnectListener() {
            @Override
            public void onDisconnect(SocketIOClient client) {
                String userId = connectedClients.remove(client.getSessionId());
                log.info("[WEBSOCKET] Client disconnected: [{}] userId={}", client.getSessionId(), userId);
            }
        });

        server.addEventListener("subscribe", Map.class, new DataListener<Map>() {
            @Override
            public void onData(SocketIOClient client, Map data, AckRequest ackSender) {
                if (data != null && data.containsKey("requestId")) {
                    String requestId = String.valueOf(data.get("requestId"));
                    client.joinRoom("request:" + requestId);
                    log.info("[WEBSOCKET] Client [{}] subscribed to request:{}", client.getSessionId(), requestId);
                }
            }
        });

        DataListener<Map> locationListener = new DataListener<Map>() {
            @Override
            public void onData(SocketIOClient client, Map data, AckRequest ackSender) {
                if (data == null) return;
                String requestId = data.containsKey("requestId") ? String.valueOf(data.get("requestId")) : null;
                String driverId = data.containsKey("driverId") ? String.valueOf(data.get("driverId")) : "drv-001";
                double lat = data.containsKey("lat") ? Double.parseDouble(String.valueOf(data.get("lat"))) : 0.0;
                double lng = data.containsKey("lng") ? Double.parseDouble(String.valueOf(data.get("lng"))) : 0.0;
                double speed = data.containsKey("speed") ? Double.parseDouble(String.valueOf(data.get("speed"))) : 0.0;
                double heading = data.containsKey("heading") ? Double.parseDouble(String.valueOf(data.get("heading"))) : 0.0;

                Map<String, Object> posData = new HashMap<>();
                posData.put("requestId", requestId);
                posData.put("driverId", driverId);
                posData.put("lat", lat);
                posData.put("lng", lng);
                posData.put("speedKmph", speed);
                posData.put("headingDeg", heading);
                posData.put("capturedAt", Instant.now().toString());

                if (requestId != null && !requestId.isBlank()) {
                    emitLocationUpdated(requestId, posData);
                } else {
                    server.getRoomOperations("dispatcher-room").sendEvent("tracking_updated", posData);
                }
            }
        };

        server.addEventListener("driver:location", Map.class, locationListener);
        server.addEventListener("location_update", Map.class, locationListener);
    }

    public int getConnectedClientsCount() {
        return connectedClients.size();
    }

    public List<Map<String, Object>> getEmittedEventsLog() {
        return Collections.unmodifiableList(emittedEventsLog);
    }

    private void recordEvent(String eventName, String targetRoom, Object payload) {
        Map<String, Object> entry = new HashMap<>();
        entry.put("event", eventName);
        entry.put("room", targetRoom);
        entry.put("payload", payload);
        entry.put("timestamp", Instant.now().toString());
        emittedEventsLog.add(entry);

        // Keep log size capped at 100
        if (emittedEventsLog.size() > 100) {
            emittedEventsLog.remove(0);
        }
    }

    public void emitNewRequest(Object payload) {
        recordEvent("request_created", "dispatcher-room", payload);
        if (server != null) {
            server.getRoomOperations("dispatcher-room").sendEvent("request_created", payload);
            server.getRoomOperations("dispatcher-room").sendEvent("new_request", payload);
        }
    }

    public void emitAmbulanceAssigned(String requestId, Object payload) {
        recordEvent("driver_assigned", "request:" + requestId, payload);
        if (server != null) {
            server.getRoomOperations("request:" + requestId).sendEvent("driver_assigned", payload);
            server.getRoomOperations("request:" + requestId).sendEvent("ambulance_assigned", payload);
            server.getRoomOperations("dispatcher-room").sendEvent("driver_assigned", payload);
        }
    }

    public void emitLocationUpdated(String requestId, Object position) {
        recordEvent("tracking_updated", "request:" + requestId, position);
        if (server != null) {
            server.getRoomOperations("request:" + requestId).sendEvent("tracking_updated", position);
            server.getRoomOperations("request:" + requestId).sendEvent("location_updated", position);
            server.getRoomOperations("dispatcher-room").sendEvent("tracking_updated", position);
        }
    }

    public void emitEtaUpdated(String requestId, Integer etaSeconds) {
        Map<String, Object> payload = Map.of("requestId", requestId, "etaSeconds", etaSeconds != null ? etaSeconds : 0);
        recordEvent("eta_updated", "request:" + requestId, payload);
        if (server != null) {
            server.getRoomOperations("request:" + requestId).sendEvent("eta_updated", payload);
            server.getRoomOperations("dispatcher-room").sendEvent("eta_updated", payload);
        }
    }

    public void emitRideCompleted(String requestId, Object payload) {
        recordEvent("request_completed", "request:" + requestId, payload);
        if (server != null) {
            server.getRoomOperations("request:" + requestId).sendEvent("request_completed", payload);
            server.getRoomOperations("request:" + requestId).sendEvent("ride_completed", payload);
            server.getRoomOperations("request:" + requestId).sendEvent("trip_completed", payload);
            server.getRoomOperations("dispatcher-room").sendEvent("request_completed", payload);
        }
    }

    public void emitAuditEvent(Object payload) {
        recordEvent("audit_event", "dispatcher-room", payload);
        if (server != null) {
            server.getRoomOperations("dispatcher-room").sendEvent("audit_event", payload);
        }
    }

    public void emitStatusUpdated(String requestId, String status, Object extraPayload) {
        Map<String, Object> payload = new HashMap<>();
        payload.put("requestId", requestId);
        payload.put("status", status);
        if (extraPayload instanceof Map map) {
            payload.putAll(map);
        }

        recordEvent("status_updated", "request:" + requestId, payload);
        if (server != null) {
            server.getRoomOperations("request:" + requestId).sendEvent("status_updated", payload);
            server.getRoomOperations("dispatcher-room").sendEvent("status_updated", payload);

            String statusUpper = status != null ? status.toUpperCase() : "";
            if ("EN_ROUTE".equals(statusUpper)) {
                server.getRoomOperations("request:" + requestId).sendEvent("en_route", payload);
                server.getRoomOperations("request:" + requestId).sendEvent("trip_updated", payload);
            } else if ("ARRIVED".equals(statusUpper)) {
                server.getRoomOperations("request:" + requestId).sendEvent("arrived", payload);
                server.getRoomOperations("request:" + requestId).sendEvent("trip_updated", payload);
            } else if ("COMPLETED".equals(statusUpper)) {
                emitRideCompleted(requestId, payload);
            } else {
                server.getRoomOperations("request:" + requestId).sendEvent("trip_updated", payload);
            }
        }
    }
}
