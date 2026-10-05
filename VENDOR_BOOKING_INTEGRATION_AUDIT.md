# Vendor Booking Integration Audit & Architecture Analysis

## 1. Current Booking Creation Flow
1. **Patient Flutter App**: User fills pickup/destination, patient details, and submits via `POST /patient/requests`.
2. **Java Backend Controller**: [`PatientRequestController.java`](file:///c:/Users/lavanya/Desktop/Ambulance/backend-java/src/main/java/com/callhealth/ambulance/controller/PatientRequestController.java) receives `RequestAmbulanceRequest`.
3. **Service & Repository**: [`PatientRequestService.java`](file:///c:/Users/lavanya/Desktop/Ambulance/backend-java/src/main/java/com/callhealth/ambulance/service/PatientRequestService.java) creates a `com.callhealth.ambulance.model.entity.AmbulanceRequest` entity and saves it to PostgreSQL table `ambulance_requests`.
4. **Redis Queue**: `PatientRequestService` enqueues a `create-booking` job into `QueueConstants.BOOKING_QUEUE`.
5. **Worker**: `BookingQueueWorker` sets request status to `DRIVER_ASSIGNED`, assigns mock driver details, emits Socket.IO real-time events, and enqueues `poll-tracking` to `QueueConstants.TRACKING_QUEUE`.
6. **Real-time Tracking**: `TrackingQueueWorker` updates mock GPS positions in PostgreSQL and broadcasts `location_updated` / `tracking_updated` via Netty Socket.IO on port 8085.

---

## 2. Current Database Entity
- **Class**: `com.callhealth.ambulance.model.entity.AmbulanceRequest`
- **Table**: `ambulance_requests` in PostgreSQL
- **Key Fields**:
  - `id`: `UUID` (Primary key)
  - `requestNumber`: `String` (e.g., `AR-1791209976534`)
  - `status`: `AmbulanceRequestStatus` (`REQUEST_RECEIVED`, `SEARCHING`, `DRIVER_ASSIGNED`, `EN_ROUTE`, `ARRIVED`, `TRIP_STARTED`, `COMPLETED`, `CANCELLED`)
  - `patientId`, `patientName`, `patientPhone`, `notes`, `priority`
  - `pickupAddress`, `pickupLat`, `pickupLng`
  - `dropAddress`, `dropLat`, `dropLng`
  - `vendorDriverName`, `vendorDriverPhone`, `vendorVehicleNumber`, `vendorAmbulanceType`, `etaSeconds`
  - `baseFare`, `walletDiscount`, `totalPayable`, `paymentRef`, `paymentStatus`

---

## 3. Current Vendor Booking API
- **All Bookings API**: `GET /dispatcher/requests?limit=100&page=1`
- **Controller**: [`DispatcherController.java`](file:///c:/Users/lavanya/Desktop/Ambulance/backend-java/src/main/java/com/callhealth/ambulance/controller/DispatcherController.java)
- **Service**: `DispatcherService.listRequests(...)`
- **Return Type**: `PaginatedResponse<AmbulanceRequest>`
- **Response JSON Structure**:
  ```json
  {
    "data": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "requestNumber": "AR-1791209976534",
        "status": "SEARCHING",
        "pickupAddress": "SR Nagar, Hyderabad",
        "pickupLat": 17.4436,
        "pickupLng": 78.4463,
        "dropAddress": "Yashoda Hospitals, Secunderabad",
        "dropLat": 17.4399,
        "dropLng": 78.4983,
        "patientName": "Ramesh Kumar",
        "patientPhone": "+919876543210",
        "notes": "Emergency BLS",
        "priority": "normal",
        "createdAt": "2026-10-05T19:30:00"
      }
    ]
  }
  ```

---

## 4. Current Vendor Model & UI Mismatch
- **Flutter Widget**: [`VendorRequestCard`](file:///c:/Users/lavanya/Desktop/Ambulance/mobile/lib/src/features/vendor/vendor_dashboard_screen.dart#L259) in `mobile/lib/src/features/vendor/vendor_dashboard_screen.dart`
- **Mismatch**:
  The UI code was attempting to read nested objects:
  - `request['patient']['name']`
  - `request['pickup']['address']`
  - `request['destination']['address']`
  
  Because Java returns flat root properties (`patientName`, `pickupAddress`, `dropAddress`), the extraction resulted in `null`, causing fallback to defaults:
  - `patient['name'] ?? 'Unknown Patient'` $\rightarrow$ **"Unknown Patient"**
  - `pickup['address'] ?? 'Unknown Location'` $\rightarrow$ **"Unknown Location"**
  - `dest['address'] ?? 'Unknown Location'` $\rightarrow$ **"Unknown Location"**

---

## 5. Current WebSocket Implementation
- **Java Technology**: Netty Socket.IO (`com.corundumstudio.socketio.SocketIOServer`)
- **Port**: `8085`
- **Context Path**: `/ws` (set via `config.setContext("/ws")` in [`SocketIOConfig.java`](file:///c:/Users/lavanya/Desktop/Ambulance/backend-java/src/main/java/com/callhealth/ambulance/config/SocketIOConfig.java))
- **Expected Client Request Path**: `/ws/socket.io/`

---

## 6. Root Causes of Issues Identified

### A. Exact Cause of "Unknown Patient"
In `VendorRequestCard`, the widget extracted `final patient = request['patient'] ?? {};` and evaluated `patient['name']`. Since Java outputs `patientName` at the root JSON level, `patient['name']` was `null`, displaying "Unknown Patient".

### B. Exact Cause of "Unknown Location"
In `VendorRequestCard`, the widget extracted `final pickup = request['pickup'] ?? {};` and `final dest = request['destination'] ?? {};`. Since Java outputs `pickupAddress` and `dropAddress` (or `destinationAddress`) at the root level, `pickup['address']` and `dest['address']` evaluated to `null`, displaying "Unknown Location".

### C. Exact Cause of WebSocket 400
The Java backend configures Netty Socket.IO with context path `/ws`. By default, `socket_io_client` sends connection handshakes to `ws://localhost:8085/socket.io/...` (without `/ws`). Because the backend expects `/ws/socket.io/...`, Netty rejected the connection with `HTTP 400 Bad Request`.

---

## 7. Audit Answers to 22 Specific Questions

1. **Vendor API for Bookings**: `GET /dispatcher/requests?limit=100`
2. **Endpoint for "All Bookings"**: `GET /dispatcher/requests`
3. **Returns PostgreSQL Bookings?**: Yes, queries `AmbulanceRequestRepository`.
4. **Hardcoded/Mock Bookings?**: No, actual PostgreSQL `AmbulanceRequest` entities are returned.
5. **Different API/Model/Schema?**: Patient API saves `AmbulanceRequest`; vendor API reads `AmbulanceRequest`. But Flutter vendor UI assumed nested JSON keys instead of reading root properties (`patientName`, `pickupAddress`, `dropAddress`).
6. **Entity Name**: `AmbulanceRequest` (`ambulance_requests` table).
7. **Primary / Request ID**: Primary key is `id` (UUID). Display ID is `requestNumber` (e.g., `AR-1791209976534`).
8. **Pickup Coords**: `pickupLat` and `pickupLng` columns.
9. **Destination Coords**: `dropLat` and `dropLng` columns.
10. **Addresses Stored?**: Yes, `pickupAddress` and `dropAddress`.
11. **Patient Info Stored?**: Yes, `patientName`, `patientPhone`, `patientId`, `notes`.
12. **Vendor API Field Mapping**: Java returns `patientName`, `patientPhone`, `pickupAddress`, `dropAddress`, `pickupLat`, `pickupLng`, `dropLat`, `dropLng`.
13. **Flutter Model Field Matching**: Flutter looked for `patient.name`, `pickup.address`, `destination.address`.
14. **DTO Mapping Problem**: Yes, field key extraction mismatch in `VendorRequestCard`.
15. **Auth/Filtering Issue**: No, `GET /dispatcher/requests` returns all requests.
16. **Vendor ID Filtering Issue**: No, all bookings are listed.
17. **WebSocket Technology**: Netty Socket.IO (`com.corundumstudio.socketio.SocketIOServer`).
18. **WebSocket Port**: `8085` with context `/ws`.
19. **Why `ws://localhost:8085/socket.io/` failed**: Missing `.setPath('/ws/socket.io')` in `socket_io_client` OptionBuilder.
20. **Patient App WebSocket**: Connects to `ws://localhost:8085` with path `/ws/socket.io` and subscribes to room `request:{requestId}`.
21. **Patient vs Vendor WebSocket**: Both use Netty Socket.IO port 8085. Vendor subscribes to `dispatcher-room` and `request:{requestId}`.
22. **Shared Architecture**: Both apps observe the same Netty Socket.IO stream; backend `WebSocketGateway` broadcasts `status_updated`, `driver_assigned`, and `location_updated` to both `request:{requestId}` and `dispatcher-room`.

---

## 8. Recommended Minimal Fix
1. **Flutter Vendor Request Card (`VendorRequestCard`)**:
   Support both flat root properties (`patientName`, `pickupAddress`, `dropAddress`, `dropLat`, `dropLng`) and nested map formats gracefully:
   ```dart
   final patientName = request['patientName'] ?? request['patient']?['name'] ?? 'Patient';
   final patientPhone = request['patientPhone'] ?? request['patient']?['phone'] ?? '';
   final pickupAddr = request['pickupAddress'] ?? request['pickup']?['address'] ?? 'Pickup Location';
   final dropAddr = request['dropAddress'] ?? request['destinationAddress'] ?? request['drop']?['address'] ?? request['destination']?['address'] ?? 'Destination Location';
   ```
2. **WebSocket Path Standardization**:
   Ensure both `VendorProvider` and `TrackingProvider` use `.setPath('/ws/socket.io')` in `OptionBuilder()`.
3. **No Database Schema or Backend Architecture Changes Required**.
