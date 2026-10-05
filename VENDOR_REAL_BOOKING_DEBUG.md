# Vendor Dashboard Real Booking Debug & Audit Report (`VENDOR_REAL_BOOKING_DEBUG.md`)

## Executive Summary
This read-only audit identifies the root cause of `AR-DEMO-104` appearing in the Vendor Dashboard, why real patient bookings were omitted or obscured by demo data, and the precise architecture required to enforce single-source-of-truth real booking display and tracking between the Patient App, Java Spring Boot Backend, PostgreSQL Database, Netty Socket.IO Gateway, and Vendor Dashboard.

---

## 1. Audit Findings: Source of `AR-DEMO-104`

| Question / Metric | Findings |
| :--- | :--- |
| **Exact Location of `AR-DEMO-104`** | Defined in Java Backend: `DemoSeedService.java` lines 76–84. |
| **Does PostgreSQL contain `AR-DEMO-104`?** | **YES.** `AR-DEMO-104` is persisted in PostgreSQL `ambulance_requests` (`id: eb949fa2-1d79-4dff-bf3f-985403fa5456`, status `ARRIVED`). |
| **Why is `AR-DEMO-104` in PostgreSQL?** | `DemoDataInitializer.java` executes on Spring Boot startup and invokes `demoSeedService.seedDemoData("demo-patient-uuid")`. |
| **API Endpoint Called by Vendor Dashboard** | `GET /dispatcher/requests?limit=100` in `VendorProvider.dart`. |
| **Does `GET /dispatcher/requests` return real patient bookings?** | **YES.** The API returns both real patient bookings (e.g. `AR-1791211696164` for **Kavitha Reddy**) AND the 6 demo seed records (`AR-DEMO-101` through `AR-DEMO-106`). |
| **Is the API response received by Flutter?** | **YES.** HTTP 200 with complete JSON array. |
| **Why was `Unknown Patient` / `Unknown Location` displayed?** | Prior to the JSON mapping fix, `VendorRequestCard` attempted to extract nested maps (`request['patient']['name']`) which were `null`. Java returns flat root-level fields (`patientName`, `pickupAddress`, `dropAddress`). |
| **Why is there a "Simulate Live GPS" button?** | `VendorProvider.dart` contained a frontend periodic timer (`_gpsTimer`) that artificially posted fake GPS coordinates to `/dispatcher/requests/{id}/location`. This bypassed the Java backend's `TrackingQueueWorker`. |

---

## 2. API Response Verification (`GET /dispatcher/requests?limit=100`)

Direct verification of the backend endpoint confirms that **real patient bookings exist in PostgreSQL**:

```json
[
  {
    "id": "0c224129-48c0-4354-a2d9-cf49e8c362d3",
    "requestNumber": "AR-1791211696164",
    "status": "EN_ROUTE",
    "pickupAddress": "Plot 42, Jubilee Hills, Hyderabad",
    "pickupLat": 17.4325,
    "pickupLng": 78.4071,
    "dropAddress": "Apollo Hospital, Jubilee Hills, Hyderabad",
    "dropLat": 17.4262,
    "dropLng": 78.4116,
    "patientName": "Kavitha Reddy",
    "patientPhone": "+919123456789"
  },
  {
    "id": "eb949fa2-1d79-4dff-bf3f-985403fa5456",
    "requestNumber": "AR-DEMO-104",
    "status": "ARRIVED",
    "pickupAddress": "Madhapur Metro Station, Hyderabad",
    "dropAddress": "Medicover Hospital, Madhapur, Hyderabad",
    "patientName": "Demo Patient",
    "patientPhone": "+919876543210"
  }
]
```

---

## 3. Core Problems Identified

1. **Database Seed Contamination**: `DemoDataInitializer.java` populates `AR-DEMO-101` .. `106` into PostgreSQL on startup, causing demo records to pollute real vendor views.
2. **Hardcoded Summary Endpoint**: `GET /vendor/dashboard` in `VendorController.java` returns empty lists (`latestRequests: []`, `activeTrips: []`), causing summary widgets to show empty states or rely on un-filtered arrays.
3. **Frontend Simulation Coupling**: `VendorDashboardScreen.dart` contains a `Simulate Live GPS` button that runs a local Dart timer. Live movement must come solely from Java `TrackingQueueWorker` broadcast over Netty Socket.IO (`/ws/socket.io`).
4. **Lack of Connection Error Feedback**: In case of network error, Flutter caught exceptions silently without notifying the vendor user with an explicit error banner.

---

## 4. Phase 2 Recommended Fix Plan

1. **Purge / Exclude Demo Seed Records**:
   - Reset demo seed data via `POST /patient/requests/reset-demo-data` or filter out `AR-DEMO-%` records so the Vendor Dashboard strictly displays real patient bookings.
2. **Remove Frontend "Simulate Live GPS" UI & Timer**:
   - Remove the `Simulate Live GPS` button from `VendorDashboardScreen.dart`.
   - Remove `toggleGpsSimulation()` and local Dart `_gpsTimer` from `VendorProvider.dart`.
   - Connect Vendor Dashboard live tracking strictly to backend `TrackingQueueWorker` via Netty Socket.IO events (`location_update`).
3. **Update Summary Controller**:
   - Update `VendorController.java` `getDashboard()` to fetch real active requests from `AmbulanceRequestRepository`.
4. **Explicit API Failure State**:
   - Add error banner in `VendorBookingsScreen` and `VendorDashboardScreen` when API fails ("Unable to load bookings. Check backend connection.").
5. **Real Booking End-to-End Verification**:
   - Create a fresh booking from Patient App.
   - Verify presence in PostgreSQL.
   - Confirm identical display in Vendor Dashboard (ID, Patient Name, Pickup/Drop addresses, Coordinates, Status).
   - Confirm synchronized Socket.IO location updates between Patient App and Vendor Dashboard.
