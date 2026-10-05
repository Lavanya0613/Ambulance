# JAVA SPRING BOOT BACKEND MIGRATION SPECIFICATION

> **Document Version**: 1.0  
> **Source Reference Architecture**: NestJS 11 TypeScript Backend (`ambulance-backend`)  
> **Target Architecture**: Java 21 / Spring Boot 3.x Enterprise Backend  
> **Purpose**: Complete functional, data, and architectural specification for reproducing the CallHealth Ambulance Backend in Java Spring Boot.

---

## 1. ARCHITECTURAL OVERVIEW

The reference backend is a microservice-ready NestJS monolithic application handling real-time emergency ambulance bookings, payment processing, driver dispatching, vendor integration, and live vehicle location tracking via WebSockets and BullMQ asynchronous queues.

### Component Mapping: NestJS $\rightarrow$ Spring Boot

| NestJS Reference Component | Spring Boot Target Equivalent | Role & Description |
|---|---|---|
| `@nestjs/core` + Express | `spring-boot-starter-web` | REST API Routing, HTTP Servlet Handling |
| TypeORM + `pg` | `spring-boot-starter-data-jpa` (Hibernate) | PostgreSQL ORM, Entities, Repositories |
| `@nestjs/jwt` + `passport-jwt` | `spring-boot-starter-security` | Role-Based Access Control (RBAC), JWT Parsing |
| `socket.io` + `@nestjs/websockets` | `netty-socketio` / Spring WebSocket | Real-time WebSocket streaming (`/ws` namespace) |
| `bullmq` + `ioredis` | Spring AMQP / Redisson / Spring Data Redis | Asynchronous Job Queues (`booking`, `tracking`, `dlq`) |
| `@nestjs/throttler` | Resilience4j / Bucket4j | Rate limiting API endpoints |
| Swagger `@nestjs/swagger` | `springdoc-openapi-starter-webmvc-ui` | OpenAPI 3.0 documentation (`/docs`) |

---

## 2. DATABASE ENTITY SCHEMAS & RELATIONSHIPS

All tables reside in PostgreSQL database `ambulance` under `public` schema.

### 2.1 Entity Catalog

#### 1. `AmbulanceRequest` (`table: ambulance_requests`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `requestNumber`: `VARCHAR(50)` (NOT NULL, UNIQUE, e.g., `AR-1789230192`)
  - `patientId`: `VARCHAR(100)` (NOT NULL)
  - `patientName`: `VARCHAR(100)` (NOT NULL)
  - `patientPhone`: `VARCHAR(30)` (NOT NULL)
  - `pickupAddress`: `TEXT` (NOT NULL)
  - `pickupLat`: `DOUBLE PRECISION` (NOT NULL)
  - `pickupLng`: `DOUBLE PRECISION` (NOT NULL)
  - `dropAddress`: `TEXT` (NOT NULL)
  - `dropLat`: `DOUBLE PRECISION` (NOT NULL)
  - `dropLng`: `DOUBLE PRECISION` (NOT NULL)
  - `priority`: `VARCHAR(20)` (NOT NULL, default: `'normal'`, values: `normal`, `high`, `critical`)
  - `ambulanceType`: `VARCHAR(20)` (NULLABLE, values: `BLS`, `ALS`, `ICU`)
  - `scheduledFor`: `TIMESTAMP WITH TIME ZONE` (NULLABLE)
  - `notes`: `TEXT` (NULLABLE)
  - `idempotencyKey`: `VARCHAR(100)` (NULLABLE, UNIQUE index)
  - `status`: `VARCHAR(30)` (NOT NULL, default: `'REQUEST_RECEIVED'`, Enum: `SCHEDULED`, `PENDING`, `REQUEST_RECEIVED`, `REQUEST_CREATED`, `SEARCHING`, `SEARCHING_DRIVER`, `VENDOR_ACCEPTED`, `DRIVER_ASSIGNED`, `EN_ROUTE`, `ARRIVED`, `TRIP_STARTED`, `PATIENT_ONBOARD`, `DESTINATION_REACHED`, `COMPLETED`, `CANCELLED`, `FAILED`)
  - `cancelReason`: `VARCHAR(255)` (NULLABLE)
  - `assignedVendorId`: `VARCHAR(50)` (NULLABLE)
  - `vendorBookingRef`: `VARCHAR(100)` (NULLABLE)
  - `vendorDriverRef`: `VARCHAR(100)` (NULLABLE)
  - `vendorDriverName`: `VARCHAR(100)` (NULLABLE)
  - `vendorDriverPhone`: `VARCHAR(30)` (NULLABLE)
  - `vendorVehicleNumber`: `VARCHAR(50)` (NULLABLE)
  - `vendorAmbulanceType`: `VARCHAR(50)` (NULLABLE)
  - `etaSeconds`: `INTEGER` (NULLABLE)
  - `baseFare`: `DOUBLE PRECISION` (NOT NULL, default: `1250.0`)
  - `walletDiscount`: `DOUBLE PRECISION` (NOT NULL, default: `0.0`)
  - `totalPayable`: `DOUBLE PRECISION` (NOT NULL, default: `1250.0`)
  - `paymentStatus`: `VARCHAR(20)` (NOT NULL, default: `'PENDING'`, Enum: `PENDING`, `PROCESSING`, `SUCCESS`, `FAILED`, `CANCELLED`)
  - `paymentRef`: `VARCHAR(100)` (NULLABLE)
  - `createdAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)
  - `updatedAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 2. `TrackingPosition` (`table: tracking_positions`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Foreign Key**: `requestId` $\rightarrow$ `ambulance_requests(id)` (ON DELETE CASCADE)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `requestId`: `UUID` (FK, NOT NULL)
  - `vendorEventId`: `VARCHAR(100)` (NULLABLE)
  - `lat`: `DOUBLE PRECISION` (NOT NULL)
  - `lng`: `DOUBLE PRECISION` (NOT NULL)
  - `speedKmph`: `DOUBLE PRECISION` (NULLABLE)
  - `headingDeg`: `DOUBLE PRECISION` (NULLABLE)
  - `capturedAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 3. `PatientWallet` (`table: patient_wallet`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `patientId`: `VARCHAR(100)` (NOT NULL, UNIQUE)
  - `ambulanceBenefitUsed`: `BOOLEAN` (NOT NULL, default: `false`)
  - `updatedAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 4. `PaymentTransaction` (`table: payment_transactions`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Foreign Key**: `requestId` $\rightarrow$ `ambulance_requests(id)`
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `requestId`: `UUID` (FK, NOT NULL)
  - `patientId`: `VARCHAR(100)` (NOT NULL)
  - `amount`: `DOUBLE PRECISION` (NOT NULL)
  - `status`: `VARCHAR(20)` (NOT NULL, default: `'PENDING'`, Enum: `PENDING`, `PROCESSING`, `SUCCESS`, `FAILED`)
  - `method`: `VARCHAR(50)` (NOT NULL, default: `'MOCK'`)
  - `transactionRef`: `VARCHAR(100)` (NULLABLE)
  - `failureReason`: `VARCHAR(255)` (NULLABLE)
  - `createdAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 5. `Driver` (`table: drivers`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `vendorId`: `VARCHAR(50)` (NOT NULL)
  - `name`: `VARCHAR(100)` (NOT NULL)
  - `phoneE164`: `VARCHAR(30)` (NOT NULL, UNIQUE)
  - `status`: `VARCHAR(20)` (NOT NULL, default: `'AVAILABLE'`, Enum: `AVAILABLE`, `ON_TRIP`, `OFFLINE`)
  - `currentLat`: `DOUBLE PRECISION` (NULLABLE)
  - `currentLng`: `DOUBLE PRECISION` (NULLABLE)
  - `createdAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 6. `AmbulanceVehicle` (`table: ambulance_vehicles`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `vendorId`: `VARCHAR(50)` (NOT NULL)
  - `vehicleNumber`: `VARCHAR(50)` (NOT NULL, UNIQUE)
  - `ambulanceType`: `VARCHAR(20)` (NOT NULL, values: `BLS`, `ALS`, `ICU`)
  - `status`: `VARCHAR(20)` (NOT NULL, default: `'AVAILABLE'`, Enum: `AVAILABLE`, `IN_USE`, `MAINTENANCE`)
  - `createdAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 7. `SystemAuditLog` (`table: system_audit_logs`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `action`: `VARCHAR(100)` (NOT NULL)
  - `bookingId`: `VARCHAR(100)` (NULLABLE)
  - `description`: `TEXT` (NOT NULL)
  - `performedBy`: `VARCHAR(100)` (NOT NULL)
  - `performedByRole`: `VARCHAR(50)` (NOT NULL)
  - `performedById`: `VARCHAR(100)` (NULLABLE)
  - `patientName`: `VARCHAR(100)` (NULLABLE)
  - `previousStatus`: `VARCHAR(50)` (NULLABLE)
  - `newStatus`: `VARCHAR(50)` (NULLABLE)
  - `requestSource`: `VARCHAR(50)` (NOT NULL, default: `'SYSTEM'`)
  - `apiEndpoint`: `VARCHAR(255)` (NULLABLE)
  - `success`: `BOOLEAN` (NOT NULL, default: `true`)
  - `metadata`: `JSONB` (NULLABLE)
  - `timestamp`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

#### 8. `DlqJob` (`table: dead_letter_jobs`)
* **Primary Key**: `id` (`UUID`, generated v4)
* **Columns**:
  - `id`: `UUID` (PK, NOT NULL)
  - `originalQueue`: `VARCHAR(100)` (NOT NULL)
  - `originalJobId`: `VARCHAR(100)` (NOT NULL)
  - `payload`: `JSONB` (NOT NULL)
  - `failedReason`: `TEXT` (NOT NULL)
  - `attemptsMade`: `INTEGER` (NOT NULL)
  - `failedAt`: `TIMESTAMP WITH TIME ZONE` (NOT NULL, default: `CURRENT_TIMESTAMP`)

---

## 3. COMPLETE API ENDPOINT MATRIX

### 3.1 Patient Module (`/patient/requests`)

#### `GET /patient/requests/places/autocomplete`
* **Controller / Method**: `AmbulanceController.autocompletePlaces`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Query Params**: `input` (`string`, min 3 chars)
* **Response**: `{ status: "OK", predictions: [ { description: string, place_id: string } ] }`
* **Business Rules**: Tries Google Places API first. If unbilled/failed, queries OpenStreetMap (Nominatim). Returns live predictions with embedded coordinates in `place_id` (`osm_<lat>_<lng>`).
* **Frontend Consumer**: Flutter `BookingProvider.searchPickup`, `searchDrop`, Web `AddressAutocomplete.tsx`.

#### `GET /patient/requests/places/details`
* **Controller / Method**: `AmbulanceController.getPlaceDetails`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Query Params**: `place_id` (`string`)
* **Response**: `{ status: "OK", result: { geometry: { location: { lat: number, lng: number } } } }`
* **Business Rules**: Parses `osm_<lat>_<lng>` or fetches Google Place Details.
* **Frontend Consumer**: Flutter `BookingProvider.selectPickup`, `selectDrop`.

#### `GET /patient/requests/places/reverse`
* **Controller / Method**: `AmbulanceController.reverseGeocode`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Query Params**: `lat` (`number`), `lng` (`number`)
* **Response**: `{ address: string }`
* **Business Rules**: Geocodes GPS coordinates to human-readable address.
* **Frontend Consumer**: Flutter `BookingProvider.getCurrentLocation`.

#### `GET /patient/requests/wallet`
* **Controller / Method**: `AmbulanceController.getWallet`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Response**: `{ ambulanceBenefitAmount: 50, ambulanceBenefitEligible: boolean }`
* **Business Rules**: Checks if `patient_wallet.ambulanceBenefitUsed` is true for `patientId`. If false, returns `ambulanceBenefitEligible = true`.
* **Frontend Consumer**: Flutter `BookingProvider.fetchWalletBenefit`, `ReviewBookingScreen`.

#### `POST /patient/requests`
* **Controller / Method**: `AmbulanceController.requestAmbulance`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Request Body**:
  ```json
  {
    "idempotencyKey": "string (UUID)",
    "priority": "normal | high | critical",
    "ambulanceType": "BLS | ALS | ICU",
    "applyWallet": boolean,
    "pickup": { "lat": number, "lng": number, "address": string },
    "drop": { "lat": number, "lng": number, "address": string },
    "patient": { "name": string, "phoneE164": string },
    "notes": "string",
    "scheduledFor": "ISO-8601 string (optional)"
  }
  ```
* **Response**:
  ```json
  {
    "requestId": "UUID",
    "requestNumber": "AR-1789230192",
    "status": "REQUEST_RECEIVED | SCHEDULED",
    "createdAt": "ISO-8601",
    "baseFare": 1250.0,
    "walletDiscount": 50.0,
    "totalPayable": 1200.0,
    "paymentStatus": "PENDING"
  }
  ```
* **Business Rules**:
  - Idempotency check: Returns existing booking if `idempotencyKey` matched.
  - Base fare: `BLS` = ₹1250, `ALS` = ₹2500, `ICU` = ₹3500.
  - Wallet discount: If `applyWallet=true` and benefit not used, applies ₹50 discount.
  - Atomic database transaction creates `ambulance_requests` record with status `PENDING` payment.
  - Emits WebSocket event `request_created` via `WebsocketGateway`.
* **Frontend Consumer**: Flutter `ReviewBookingScreen`, Web `BookingPage.tsx`.

#### `POST /patient/requests/:requestId/payment/initiate`
* **Controller / Method**: `AmbulanceController.initiatePayment`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Response**: `{ transactionId: "UUID", status: "PENDING" }`
* **Business Rules**: Creates a `payment_transactions` record in `PENDING` status.
* **Frontend Consumer**: Flutter `PaymentScreen`.

#### `POST /patient/requests/:requestId/payment/process`
* **Controller / Method**: `AmbulanceController.processPayment`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Request Body**: `{ "simulateFail": false }`
* **Response**:
  ```json
  {
    "status": "SUCCESS",
    "paymentStatus": "SUCCESS",
    "transactionRef": "MOCK_TXN_1789230192",
    "amount": 1200.0,
    "message": "Payment successful. Ambulance dispatching."
  }
  ```
* **Business Rules**:
  - Marks `payment_transactions` as `SUCCESS`.
  - Consumes wallet benefit in `patient_wallet` (`ambulanceBenefitUsed = true`).
  - Updates request status to `SEARCHING` (or `SCHEDULED` if scheduled for future).
  - Enqueues job to BullMQ `bookingQueue`.
  - Emits WebSocket event `status_updated`.
* **Frontend Consumer**: Flutter `PaymentScreen`.

#### `GET /patient/requests/:requestId/track`
* **Controller / Method**: `AmbulanceController.trackAmbulance`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Response**: Complete `TrackingSnapshotDto` (request details, driver info, last location, ETA).
* **Frontend Consumer**: Flutter `TrackingScreen`, Web `TrackingPage.tsx`.

#### `POST /patient/requests/:requestId/cancel`
* **Controller / Method**: `AmbulanceController.cancelAmbulance`
* **Auth / Role**: Allowed Roles: `patient`, `dispatcher`, `admin`
* **Request Body**: `{ "reasonCode": "patient_cancelled" }`
* **Response**: `{ requestId: "UUID", status: "CANCELLED" }`
* **Business Rules**: Transitions status to `CANCELLED`, notifies queues & WebSockets.
* **Frontend Consumer**: Flutter `TrackingScreen`.

---

### 3.2 Dispatcher Module (`/dispatcher`)

* `GET /dispatcher/dashboard`: Returns summary counts of requests grouped by status.
* `GET /dispatcher/requests`: Returns paginated active requests.
* `GET /dispatcher/requests/:id`: Returns complete request details.
* `POST /dispatcher/requests/:id/accept`: Accepts vendor dispatch assignment.
* `POST /dispatcher/requests/:id/assign-driver`: Assigns driver & vehicle (`AssignDriverDto`).
* `POST /dispatcher/requests/:id/cancel`: Cancels request.
* `POST /dispatcher/requests/:id/complete`: Marks request as `COMPLETED`.
* `PATCH /dispatcher/requests/:id/status`: Updates request status directly.
* `POST /dispatcher/requests/:id/location`: Manually posts simulated driver coordinates.

---

### 3.3 Vendor & Driver Modules (`/vendor` & `/driver-app`)

* `GET /vendor/dashboard`: Metrics for vendor (pending, assigned, active, completed today, driver/vehicle availability).
* `GET /vendor/drivers` & `POST /vendor/drivers`: Driver roster management.
* `GET /vendor/ambulances` & `POST /vendor/ambulances`: Fleet management.
* `POST /driver-app/auth/login`: Driver login endpoint.
* `POST /driver-app/location`: Driver app posts live GPS location updates.

---

## 4. REDIS & BULLMQ ASYNCHRONOUS QUEUES

### 4.1 Queue Catalog

| Queue Name | Purpose | Producer | Worker / Consumer | Retry Strategy |
|---|---|---|---|---|
| **`bookingQueue`** | Dispatches paid bookings to vendor adapters | `AmbulanceService.processPayment` | `QueueProviders.BOOKING_WORKER` | 5 attempts, Exponential backoff (1000ms) |
| **`trackingQueue`** | Polls vendor adapter for vehicle position updates | `BOOKING_WORKER` | `QueueProviders.TRACKING_WORKER` | 3 attempts, Exponential backoff (500ms) |
| **`deadLetterQueue`** | Stores exhausted failed jobs | `Worker.on('failed')` | `DlqService.storeFailedJob` | Manual retry via `/queues/dlq/:id/retry` |

---

## 5. WEBSOCKET GATEWAY EVENTS

* **Namespace**: `/ws` (Socket.IO / Netty SocketIO)
* **Client Actions**:
  - `subscribe`: Client emits `{ "requestId": "UUID" }` to join socket room.
  - `driver:location`: Driver app emits `{ "requestId": "UUID", "lat": number, "lng": number }`.
* **Server Broadcast Events**:
  - `request_created`: Emits new booking payload to room.
  - `status_updated`: Emits `{ "requestId": "UUID", "status": "SEARCHING | DRIVER_ASSIGNED | EN_ROUTE | ARRIVED | TRIP_STARTED | COMPLETED" }`.
  - `ambulance_assigned`: Emits `{ "requestId": "UUID", "driver": DriverInfo, "etaSeconds": number }`.
  - `location_updated`: Emits `{ "requestId": "UUID", "lat": number, "lng": number, "speedKmph": number, "headingDeg": number }`.
  - `eta_updated`: Emits `{ "requestId": "UUID", "etaSeconds": number }`.

---

## 6. MOCK VENDOR SIMULATION PHYSICS

The `MockVendorAdapter` simulates real-time vehicle movement when external vendor APIs are omitted:
1. **Ticker Loop**: Ticks every 2 seconds (`TICK_MS = 2000`).
2. **Phase Progression**:
   - `WAIT_ACCEPT` (6s) $\rightarrow$ `WAIT_ASSIGN` (6s, assigns driver `Ravi Kumar`) $\rightarrow$ `TO_PICKUP` (Interpolates lat/lng towards pickup) $\rightarrow$ `AT_PICKUP` (Arrived at patient) $\rightarrow$ `TO_DROP` (Interpolates lat/lng towards destination) $\rightarrow$ `AT_DROP` $\rightarrow$ `COMPLETED`.
3. **Speed & Bearing Calculation**:
   - Computes Haversine distance and forward bearing ($\theta = \text{atan2}(y, x)$) per tick to update `headingDeg` and `speedKmph` ($\approx 30\text{--}40\text{ km/h}$).

---

## 7. MIGRATION DIRECTIVES FOR JAVA DEVELOPER

1. **Spring Boot Version**: Use **Spring Boot 3.3+** with **Java 21**.
2. **Database Migration**: Create Liquibase or Flyway migration scripts matching PostgreSQL schemas detailed in Section 2.
3. **Asynchronous Processing**: Replace BullMQ with **Spring AMQP / RabbitMQ** or **Redisson / Spring Data Redis** reactive queues.
4. **WebSocket Implementation**: Use `netty-socketio` or Spring WebSocket with Socket.IO protocol compatibility to seamlessly interface with existing Flutter mobile app socket client (`socket_io_client`).
5. **Preserve Endpoint Signatures**: All HTTP endpoint paths, query parameters, request bodies, and JSON response keys must match 1-to-1 with this specification to guarantee zero breakages on Flutter mobile and React web apps.
