# 🚑 Ambulance Booking Platform — Internal Architecture & Code Flow

---

## 📐 System Overview

This is a **full-stack, real-time ambulance dispatching platform** composed of three separate applications that work together:

| Application | Tech | Purpose |
|---|---|---|
| **Backend API** (`/src`) | NestJS + TypeScript | Core business logic, REST API, WebSocket gateway, queues |
| **Web Dashboard** (`/web`) | React + TypeScript | Admin, dispatcher, and patient-facing web interface |
| **Mobile App** (`/mobile`) | Flutter + Dart | Patient and driver mobile experience |

All three connect via a **shared PostgreSQL database**, **Redis** for queues, and **WebSockets** for real-time events.

---

## 🗂️ Project Directory Structure

```
Ambulance/
├── src/                          # NestJS Backend
│   ├── app.module.ts             # Root module — wires everything together
│   ├── main.ts                   # Entry point: CORS, Swagger, port 3000
│   ├── common/                   # Guards, filters, pipes (shared utilities)
│   ├── config/                   # TypeORM, Redis, JWT config providers
│   ├── gateway/                  # WebSocket gateway (Socket.IO)
│   ├── infrastructure/           # Bull queue setup
│   ├── migrations/               # TypeORM database migrations
│   └── modules/                  # Feature modules (see below)
│       ├── ambulance/            # Core booking logic ← HEART OF SYSTEM
│       ├── driver/               # Driver auth, status, GPS
│       ├── vendor/               # Vendor management, booking acceptance
│       ├── admin/                # Admin-only APIs
│       ├── dispatcher/           # Dispatcher dashboard service
│       ├── dashboard/            # Real-time summary stats
│       ├── fleet/                # Vehicle management
│       └── audit/                # Immutable audit logging
├── web/                          # React Web Dashboard
│   └── src/
│       ├── App.tsx               # Routes + auth guards
│       ├── pages/                # Page components
│       ├── components/           # Reusable UI (map, timeline, etc.)
│       ├── context/              # React context (auth state)
│       └── layouts/              # Admin sidebar shell
├── mobile/                       # Flutter Mobile App
│   └── lib/
│       ├── main.dart             # App entry + Provider setup
│       └── src/
│           ├── routes/           # Named route map
│           └── features/         # Feature screens + providers
└── docker-compose.yml            # PostgreSQL + Redis containers
```

---

## 🔷 Backend Deep Dive (`/src`)

### Entry Point — `main.ts`
- Bootstraps the NestJS app
- Enables **CORS** for the web frontend
- Mounts **Swagger UI** at `/api/docs`
- Attaches global **validation pipes** and **exception filters**
- Listens on port **3000**

---

## 🚨 `ambulance` Module — Core Business Logic

This module owns the entire lifecycle of a booking.

**Key Files:**
- `ambulance.service.ts` — All business rules
- `ambulance.controller.ts` — Patient + internal REST endpoints
- `eta.service.ts` — ETA calculation (Haversine formula)
- `geocoding.service.ts` — Address → lat/lng via OpenStreetMap Nominatim
- `entities/` — TypeORM entities (`AmbulanceRequest`, etc.)
- `repositories/` — Custom DB query methods
- `dto/` — Input/output data shapes (class-validator)

### Booking Status Lifecycle

```
Patient creates booking
        ↓
   PENDING  (saved to DB)
        ↓
   Queue job pushed to Bull (Redis)
        ↓
   SEARCHING_DRIVER  (dispatcher worker running)
        ↓
   VENDOR_ACCEPTED  (vendor accepts via web portal)
        ↓
   DRIVER_ASSIGNED  (vendor assigns a driver)
        ↓
   EN_ROUTE  (driver moving towards patient)
        ↓
   ARRIVED  (driver at pickup)
        ↓
   PATIENT_ONBOARD  (patient in ambulance)
        ↓
   TRIP_STARTED  (en route to hospital)
        ↓
   DESTINATION_REACHED  (at hospital)
        ↓
   COMPLETED ✅   OR   CANCELLED ❌ (at any point)
```

Each status transition:
1. Updates `AmbulanceRequest` in **PostgreSQL**
2. Emits a **WebSocket event** to the request's subscriber room
3. Writes an entry to the **audit log**

---

## 📡 `gateway` Module — WebSocket Real-Time Events

- Uses **Socket.IO** via NestJS `@WebSocketGateway`
- JWT is validated on socket handshake (`handshake.auth.token`)
- Clients subscribe to a request room: `socket.emit('subscribe', { requestId })`

### Events Emitted by Server

| Event | When Triggered | Payload |
|---|---|---|
| `ambulance_assigned` | Driver assigned to booking | `{ driver, etaSeconds }` |
| `location_updated` | Driver sends GPS ping | `{ lat, lng, heading }` |
| `tracking_updated` | Alternative location update | Same as above |
| `eta_updated` | ETA recalculated from GPS | `{ etaSeconds }` |
| `status_updated` | Booking status changes | `{ status }` |
| `request_created` | New booking acknowledged | `{ status }` |
| `request_cancelled` | Booking cancelled | `{ status }` |

---

## ⚙️ `infrastructure` — Bull Queue (Async Dispatch)

- Uses **Bull** (backed by Redis) for non-blocking job processing
- When a booking is created, a **dispatch job** is queued
- A background worker picks it up and searches for an available vendor
- Decouples booking creation from vendor assignment (fully async)
- Queue name: `ambulance-dispatch` (defined in `infrastructure/bull/queues.ts`)

---

## 🚗 `driver` Module

**API (driver mobile app):**
- `POST /driver/auth/login` → phone-based login, returns JWT
- `POST /driver/status` → update status + current GPS coordinates
- `GET /driver/active-request` → fetch currently assigned trip

**On each GPS update from driver:**
1. `lastLocation` on `AmbulanceRequest` updated in DB
2. WebSocket emits `location_updated` to patient's room
3. ETA recalculated → emits `eta_updated`

---

## 🏢 `vendor` Module

Vendors are ambulance companies that own fleets and drivers.

**Adapter Pattern:** The `ambulance-vendor.interface.ts` defines a contract any real vendor API must implement. Currently:
- `mock-vendor.adapter.ts` — used in development
- `red-health.adapter.ts` — stub for Red Health API integration

Swap adapters without touching core booking logic.

---

## 📋 `audit` Module

Every major action is logged to `SystemAuditLog`:
- Booking created / status changed / driver assigned / cancelled
- Provides a full immutable trail for debugging and compliance
- Viewable in the admin web dashboard

---

## 🌐 Web Dashboard (`/web`)

### Routing (`App.tsx`)
- Admin routes guarded by admin JWT in localStorage
- Patient routes open (or guarded by patient session)

### Pages

| Page | Purpose |
|---|---|
| `AdminDashboardPage` | Summary cards, recent activity |
| `AdminLiveMonitoringPage` | Real-time map of all active ambulances |
| `AdminRequestsManagementPage` | Filter/search all bookings |
| `AdminRequestDetailsPage` | Full detail view of a single booking |
| `AdminAuditLogsPage` | Full audit log browser |
| `AdminDriversPage` | Driver list and management |
| `AdminVendorsPage` | Vendor management |
| `AdminSystemMonitoringPage` | Queue stats, server health |
| `AdminSettingsPage` | Platform configuration |
| `BookingPage` | Patient-facing booking form |
| `TrackingPage` | Live tracking with real-time map |
| `HistoryPage` | Patient's completed/cancelled bookings |
| `ActiveRequestsPage` | Currently in-progress bookings |

### Reusable Components

| Component | Purpose |
|---|---|
| `LiveMap.tsx` | Leaflet map — driver position + route |
| `AddressAutocomplete.tsx` | OSM-powered address search input |
| `DriverCard.tsx` | Driver info display |
| `NotificationCenter.tsx` | Toast and alert system |
| `TimelineComponent.tsx` | Visual booking status timeline |
| `UIStates.tsx` | Loading / empty / error state components |

---

## 📱 Flutter Mobile App (`/mobile`)

### Entry — `main.dart`
- Wires all **ChangeNotifier Providers** at root
- Routes: `/splash` → detects login → patient shell or driver shell

### Screen Map

```
main.dart
├── SplashScreen           — checks token, routes patient/driver
│
├── AmbulanceShell         — Patient shell (4-tab bottom nav)
│   ├── BookingScreen      — New booking form
│   ├── MyRequestsScreen   — Order history with status tabs
│   ├── Support            — (stub)
│   └── Profile            — (stub)
│
├── TrackingScreen         — Real-time map for active trip
├── OrderDetailsScreen     — Detailed booking view
│
└── Driver Shell
    ├── DriverDashboard    — Active trip info
    ├── DriverNavScreen    — Live map navigation (OSRM road routing)
    ├── DriverTripHistory  — Past trips
    ├── DriverProfile      — Driver profile
    └── DriverSettings     — Settings
```

### State Management (Provider Pattern)

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Patient JWT + login/logout |
| `BookingProvider` | Booking form state + API submission |
| `RequestsProvider` | Paginated order history |
| `TrackingProvider` | WebSocket live tracking state |
| `DriverAuthProvider` | Driver JWT + sends GPS pings + status |

---

## 📍 Real-Time Tracking Flow (Mobile)

```
TrackingProvider.init()
  ├── fetchData()    → GET /patient/requests/:id/track  (initial DB snapshot)
  ├── fetchRoute()   → OSRM API → road polyline (pickup to drop)
  └── _connectSocket()
        ├── Socket.IO handshake with JWT
        ├── emit 'subscribe' → joins requestId room
        ├── on 'location_updated' → moves driver marker on map
        ├── on 'status_updated'   → updates status display, re-fetches route
        ├── on 'eta_updated'      → updates countdown timer
        └── on 'ambulance_assigned' → shows driver info card
```

---

## 🗺️ Driver Navigation Flow (OSRM Road Routing)

```
DriverNavigationScreen
  ├── Geolocator.getPositionStream()  → real GPS from device
  ├── _recalculateRoute()
  │     ├── if status == EN_ROUTE       → route: currentPos → pickup
  │     └── if status == TRIP_STARTED  → route: currentPos → hospital
  │     └── calls OSRM API for real road polyline
  ├── DriverAuthProvider.sendLocationUpdate()  → POST /driver/status
  └── FlutterMap renders actual road route (not straight line)
```

---

## 🔗 Full End-to-End Data Flow

```
PATIENT (mobile)
    │  POST /patient/requests
    ▼
BACKEND
    │  Creates AmbulanceRequest (PENDING) → PostgreSQL
    │  Pushes job → Bull queue (Redis)
    ▼
QUEUE WORKER (dispatcher)
    │  Finds available vendor
    │  Updates status: SEARCHING → VENDOR_ACCEPTED
    ▼
VENDOR (web portal)
    │  Assigns a driver
    │  PATCH /vendor/bookings/:id/assign
    ▼
BACKEND
    │  Status → DRIVER_ASSIGNED
    │  Emits socket: ambulance_assigned
    ▼
PATIENT (tracking screen)
    │  Receives event → shows driver card + ETA
    ▼
DRIVER (flutter app)
    │  POST /driver/status  (EN_ROUTE + GPS)
    ▼
BACKEND
    │  Saves lastLocation
    │  Recalculates ETA
    │  Emits: location_updated + eta_updated
    ▼
PATIENT
    │  Map marker moves in real time, ETA updates
    ▼
    [ARRIVED → PATIENT_ONBOARD → TRIP_STARTED → DESTINATION_REACHED → COMPLETED]
```

---

## 🗄️ Database Schema (Key Tables)

| Table | Purpose |
|---|---|
| `ambulance_request` | Core booking — status, pickup/drop, patient, driver link |
| `driver` | Driver profile, phone, availability status |
| `vendor` | Ambulance company record |
| `fleet` | Vehicles belonging to a vendor |
| `system_audit_log` | Immutable action log |

Migrations are in `src/migrations/` and auto-run on startup.

---

## 🔧 Infrastructure Stack

| Service | Role | Port |
|---|---|---|
| PostgreSQL (Docker) | Primary database | 5432 |
| Redis (Docker) | Bull queue broker | 6379 |
| OSRM (external) | Real road routing polylines | HTTPS |
| OpenStreetMap Nominatim (external) | Address geocoding | HTTPS |
| Socket.IO | Real-time bidirectional events | WS on 3000 |

---

## 🧹 Cleaned Up Files

The following development/temporary files were removed (zero production impact):

| File | Reason Removed |
|---|---|
| `test_db.js` | One-off DB connectivity check script |
| `test-api.ps1` | Manual PowerShell API test script |
| `insert_driver.sql` | One-time SQL seed statement |
| `scratch/test_e2e.ts` | Scratch E2E integration test runner |
