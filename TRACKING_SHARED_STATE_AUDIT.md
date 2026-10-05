# Tracking Shared State Audit

## Current Architecture
The application uses a unified Java Spring Boot backend with PostgreSQL, Redis Queues, and a Netty Socket.IO server running on port `8085` (`/ws` namespace).

- **Backend**: Java 21, Spring Boot, JPA/Hibernate, PostgreSQL database `ambulance_db`, Redis queue manager.
- **WebSocket Gateway**: `WebSocketGateway.java` (Netty Socket.IO server on port 8085). Clients automatically join `dispatcher-room` and subscribe to `request:{requestId}` rooms.
- **Frontend**: Flutter Web / Mobile app with Customer and Vendor views connected to Java REST (`http://localhost:8081`) and Netty Socket.IO (`http://localhost:8085/ws`).

---

## 15-Point Audit Findings

| Audit Point | Finding & Source of Truth |
|---|---|
| **1. Unique Request ID** | UUID `id` of `AmbulanceRequest` entity (e.g. `c5935552-0515-43c7-bd09-fc7fd1a2d957`) and user-facing `requestNumber` (`AR-...`). |
| **2. Java Request Entity** | `com.callhealth.ambulance.model.entity.AmbulanceRequest` in `ambulance_requests` table. |
| **3. Authoritative Status** | `AmbulanceRequest.status` column mapped to `AmbulanceRequestStatus` enum. |
| **4. Driver Storage** | `vendorDriverRef`, `vendorDriverName`, `vendorDriverPhone` in `AmbulanceRequest`. |
| **5. Ambulance Storage** | `vendorVehicleNumber`, `vendorAmbulanceType` in `AmbulanceRequest`. |
| **6. Current Location** | `TrackingPosition` table queried via `findTopByAmbulanceRequestIdOrderByCapturedAtDesc`. |
| **7. Destination Location** | `dropLat`, `dropLng` (Pickup in `pickupLat`, `pickupLng`) in `AmbulanceRequest`. |
| **8. ETA Calculation** | `AmbulanceRequest.etaSeconds` calculated by `GeoUtil` / `EtaService` in `TrackingQueueWorker`. |
| **9. WebSocket Events Emitted** | `request_created`, `driver_assigned`, `status_updated`, `tracking_updated`, `location_updated`, `eta_updated`, `request_completed`. |
| **10. Customer Listeners** | `TrackingProvider` listens to `driver_assigned`, `location_updated`, `tracking_updated`, `eta_updated`, `status_updated`, `ride_completed`. |
| **11. Vendor Listeners** | `VendorProvider` listens to `request_created`, `status_updated`. |
| **12. Vendor Request Discovery** | REST `GET /dispatcher/requests` and real-time Socket.IO `request_created` event on `dispatcher-room`. |
| **13. Backend Assignment API** | `POST /dispatcher/requests/{id}/assign-driver` updates `AmbulanceRequest` entity in database. |
| **14. Tracking Trigger** | Redis queue job `poll-tracking` processed by `TrackingQueueWorker` on status transition to `DRIVER_ASSIGNED` / `EN_ROUTE`. |
| **15. Status Alignment** | Both Customer & Vendor consume the authoritative `AmbulanceRequestStatus` enum string from backend. |

---

## Shared Tracking Lifecycle

```
REQUEST_RECEIVED / SEARCHING
            ↓ (Vendor accepts & assigns driver)
    DRIVER_ASSIGNED
            ↓ (En route to pickup)
        EN_ROUTE
            ↓ (Arrived at pickup)
        ARRIVED
            ↓ (Patient onboard & trip started)
      TRIP_STARTED / PATIENT_ONBOARD
            ↓ (Destination reached)
       COMPLETED / DESTINATION_REACHED
```

---

## Implementation Plan

1. **Java Backend**:
   - Ensure `DispatcherService.assignDriver(...)` enqueues the `poll-tracking` job into Redis `TRACKING_QUEUE` if not already present, triggering `TrackingQueueWorker` to immediately start emitting position updates.
   - Expose `GET /patient/requests/{requestId}/track` (or `GET /dispatcher/requests/{requestId}/track`) returning tracking snapshot for both Customer and Vendor.

2. **Flutter Unified Vendor Tracking**:
   - Add a **"Track Request"** action button on `VendorRequestCard` in `VendorBookingsScreen` and `VendorHomeScreen`.
   - When tapped, navigate to the unified tracking screen (`TrackingScreen`) initialized with the SAME `requestId`.
   - Ensure both Customer and Vendor view the exact same map markers, polyline route, live moving ambulance marker, status stepper, driver details, and ETA.

3. **WebSocket Real-Time Synchronization**:
   - Both Customer and Vendor subscribe to `request:{requestId}` and `dispatcher-room`.
   - Real-time `tracking_updated` and `status_updated` events update both Customer and Vendor UI simultaneously.
