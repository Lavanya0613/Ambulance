# JAVA SPRING BOOT TARGET ARCHITECTURE DESIGN

> **Document Version**: 1.0  
> **Source Specification**: `JAVA_BACKEND_MIGRATION_SPEC.md`  
> **Target Technology**: Java 21, Spring Boot 3.3.x, Spring Data JPA, Spring Security, Spring Data Redis / Redisson, Netty-SocketIO, Flyway, Maven, JUnit 5  
> **Design Objective**: 1-to-1 functional, behavioral, and API contract mirror of the NestJS reference backend for zero-breakage compatibility with Flutter mobile and React web applications.

---

## 1. NESTJS MODULE TO SPRING BOOT PACKAGE MAPPING

| NestJS Module | Target Spring Boot Package | Key Purpose |
|---|---|---|
| `AppModule` | `com.callhealth.ambulance` | Application entry point (`AmbulanceApplication.java`), global configs |
| `AmbulanceModule` | `com.callhealth.ambulance.patient` | Patient booking, wallet benefits, geocoding, payment processing |
| `DispatcherModule` | `com.callhealth.ambulance.dispatcher` | Dispatcher dashboard, manual driver assignment, status overrides |
| `DriverModule` | `com.callhealth.ambulance.driver` | Driver app authentication, driver status, real-time location ingest |
| `FleetModule` | `com.callhealth.ambulance.fleet` | Ambulance vehicle inventory and status management |
| `VendorModule` | `com.callhealth.ambulance.vendor` | Vendor integration manager and `MockVendorAdapter` physics ticker |
| `AuditModule` | `com.callhealth.ambulance.audit` | `SystemAuditLog` persistence and AOP HTTP mutation interceptor |
| Infrastructure Queues | `com.callhealth.ambulance.queue` | Redisson/Redis queue producers, processors, and Dead-Letter Queue (DLQ) |
| WebSockets Gateway | `com.callhealth.ambulance.websocket` | Netty-SocketIO `/ws` namespace server & event dispatcher |
| Security & Middleware | `com.callhealth.ambulance.security` | JwtAuthenticationFilter, RBAC SecurityFilterChain, SecurityUtils |
| Common & Exception | `com.callhealth.ambulance.common` | GlobalExceptionHandler, Custom Exceptions, Idempotency Utilities |

---

## 2. CONTROLLER TO `@RestController` MAPPING

All controllers map 1-to-1 with existing HTTP endpoints, request bodies, and JSON responses.

| NestJS Controller | Target Spring `@RestController` | Base Path | Key Methods |
|---|---|---|---|
| `AmbulanceController` | `PatientRequestController` | `/patient/requests` | `requestAmbulance()`, `autocompletePlaces()`, `getPlaceDetails()`, `reverseGeocode()`, `getWallet()`, `initiatePayment()`, `processPayment()`, `trackAmbulance()`, `cancelAmbulance()` |
| `DispatcherController` | `DispatcherController` | `/dispatcher` | `getDashboardMetrics()`, `getActiveRequests()`, `getRequestDetails()`, `acceptRequest()`, `assignDriver()`, `cancelRequest()`, `completeRequest()`, `updateStatus()`, `updateDriverLocation()` |
| `VendorController` | `VendorController` | `/vendor` | `getDashboardMetrics()`, `getDrivers()`, `createDriver()`, `getAmbulances()`, `createAmbulance()` |
| `DriverController` | `DriverController` | `/driver-app` | `login()`, `updateLocation()`, `updateStatus()` |
| `AdminController` | `AdminController` | `/admin` | `getAuditLogs()`, `getSystemStats()`, `retryDlqJob()` |

---

## 3. SERVICE TO `@Service` MAPPING

| NestJS Service | Target Spring `@Service` | Responsibilities |
|---|---|---|
| `AmbulanceService` | `PatientRequestService` | Core booking logic, idempotency check, fare estimation, wallet application, payment processing |
| `GeocodingService` | `GeocodingService` | Google Places & OpenStreetMap (Nominatim) fallback geocoding |
| `DispatcherService` | `DispatcherService` | Dispatcher operations, request status overrides, manual driver/vehicle assignment |
| `DispatcherDashboardService` | `DispatcherDashboardService` | Metric aggregation for active requests and driver availability |
| `VendorManagerService` | `VendorManagerService` | Vendor abstraction layer, dispatch routing to primary/mock vendors |
| `MockVendorAdapter` | `MockVendorAdapter` | Physics simulation ticker for ambulance trip movement |
| `VendorDashboardService` | `VendorDashboardService` | Vendor dashboard analytics and resource counts |
| `AuditService` | `AuditService` | Asynchronous system audit log insertion |
| `DlqService` | `DlqService` | Dead-letter queue job storage and retry handling |

---

## 4. ENTITY TO `@Entity` MAPPING

All entities map directly to PostgreSQL tables in schema `public` database `ambulance`.

### JPA Entity Definitions

1. **`AmbulanceRequest`** (`@Entity`, `@Table(name = "ambulance_requests")`)
   - `UUID id` (`@Id`, `@GeneratedValue(strategy = GenerationType.UUID)`)
   - `String requestNumber` (`@Column(name = "request_number", nullable = false, unique = true)`)
   - `String patientId`, `patientName`, `patientPhone`
   - `String pickupAddress`, `double pickupLat`, `double pickupLng`
   - `String dropAddress`, `double dropLat`, `double dropLng`
   - `@Enumerated(EnumType.STRING) Priority priority` (`NORMAL`, `HIGH`, `CRITICAL`)
   - `@Enumerated(EnumType.STRING) AmbulanceType ambulanceType` (`BLS`, `ALS`, `ICU`)
   - `Instant scheduledFor`, `String notes`, `String idempotencyKey`
   - `@Enumerated(EnumType.STRING) RequestStatus status` (`REQUEST_RECEIVED`, `SEARCHING_DRIVER`, `DRIVER_ASSIGNED`, `EN_ROUTE`, `ARRIVED`, `TRIP_STARTED`, `COMPLETED`, `CANCELLED`, etc.)
   - `Double baseFare`, `Double walletDiscount`, `Double totalPayable`
   - `@Enumerated(EnumType.STRING) PaymentStatus paymentStatus` (`PENDING`, `SUCCESS`, `FAILED`)
   - `Instant createdAt`, `Instant updatedAt`
   - `@OneToMany(mappedBy = "ambulanceRequest", cascade = CascadeType.ALL) List<TrackingPosition> trackingPositions`

2. **`TrackingPosition`** (`@Entity`, `@Table(name = "tracking_positions")`)
   - `UUID id`
   - `@ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "request_id", nullable = false) AmbulanceRequest ambulanceRequest`
   - `String vendorEventId`, `double lat`, `double lng`, `Double speedKmph`, `Double headingDeg`, `Instant capturedAt`

3. **`PatientWallet`** (`@Entity`, `@Table(name = "patient_wallet")`)
   - `UUID id`
   - `String patientId` (`unique = true`), `boolean ambulanceBenefitUsed`, `Instant updatedAt`

4. **`PaymentTransaction`** (`@Entity`, `@Table(name = "payment_transactions")`)
   - `UUID id`
   - `@ManyToOne @JoinColumn(name = "request_id") AmbulanceRequest ambulanceRequest`
   - `String patientId`, `Double amount`, `@Enumerated(EnumType.STRING) PaymentStatus status`, `String method`, `String transactionRef`, `String failureReason`, `Instant createdAt`

5. **`Driver`** (`@Entity`, `@Table(name = "drivers")`)
   - `UUID id`, `String vendorId`, `String name`, `String phoneE164` (`unique = true`)
   - `@Enumerated(EnumType.STRING) DriverStatus status` (`AVAILABLE`, `ON_TRIP`, `OFFLINE`)
   - `Double currentLat`, `Double currentLng`, `Instant createdAt`

6. **`AmbulanceVehicle`** (`@Entity`, `@Table(name = "ambulance_vehicles")`)
   - `UUID id`, `String vendorId`, `String vehicleNumber` (`unique = true`)
   - `@Enumerated(EnumType.STRING) AmbulanceType ambulanceType`, `@Enumerated(EnumType.STRING) VehicleStatus status`, `Instant createdAt`

7. **`SystemAuditLog`** (`@Entity`, `@Table(name = "system_audit_logs")`)
   - `UUID id`, `String action`, `String bookingId`, `String description`, `String performedBy`, `String performedByRole`, `String performedById`, `String patientName`, `String previousStatus`, `String newStatus`, `String requestSource`, `String apiEndpoint`, `boolean success`, `@JdbcTypeCode(SqlTypes.JSON) String metadata`, `Instant timestamp`

8. **`DlqJob`** (`@Entity`, `@Table(name = "dead_letter_jobs")`)
   - `UUID id`, `String originalQueue`, `String originalJobId`, `@JdbcTypeCode(SqlTypes.JSON) String payload`, `String failedReason`, `int attemptsMade`, `Instant failedAt`

---

## 5. REPOSITORY MAPPING (Spring Data JPA)

Each TypeORM custom repository maps directly to a Spring Data `JpaRepository`:

```java
public interface AmbulanceRequestRepository extends JpaRepository<AmbulanceRequest, UUID> {
    Optional<AmbulanceRequest> findByIdempotencyKey(String idempotencyKey);
    Optional<AmbulanceRequest> findByRequestNumber(String requestNumber);
    List<AmbulanceRequest> findByPatientIdOrderByCreatedAtDesc(String patientId);
    List<AmbulanceRequest> findByStatusIn(List<RequestStatus> statuses);
    long countByStatus(RequestStatus status);
}

public interface TrackingPositionRepository extends JpaRepository<TrackingPosition, UUID> {
    List<TrackingPosition> findByAmbulanceRequestIdOrderByCapturedAtAsc(UUID requestId);
    Optional<TrackingPosition> findTopByAmbulanceRequestIdOrderByCapturedAtDesc(UUID requestId);
}

public interface PatientWalletRepository extends JpaRepository<PatientWallet, UUID> {
    Optional<PatientWallet> findByPatientId(String patientId);
}

public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, UUID> {
    List<PaymentTransaction> findByAmbulanceRequestId(UUID requestId);
}

public interface DriverRepository extends JpaRepository<Driver, UUID> {
    Optional<Driver> findByPhoneE164(String phoneE164);
    List<Driver> findByVendorIdAndStatus(String vendorId, DriverStatus status);
}

public interface AmbulanceVehicleRepository extends JpaRepository<AmbulanceVehicle, UUID> {
    Optional<AmbulanceVehicle> findByVehicleNumber(String vehicleNumber);
    List<AmbulanceVehicle> findByVendorIdAndStatus(String vendorId, VehicleStatus status);
}

public interface SystemAuditLogRepository extends JpaRepository<SystemAuditLog, UUID> {
    Page<SystemAuditLog> findAllByOrderByTimestampDesc(Pageable pageable);
}

public interface DlqJobRepository extends JpaRepository<DlqJob, UUID> {
    Page<DlqJob> findAllByOrderByFailedAtDesc(Pageable pageable);
}
```

---

## 6. DTO & REQUEST/RESPONSE MAPPING

Java 21 `record`s with Bean Validation annotations (`jakarta.validation.constraints.*`) and `@JsonProperty` guarantee exact JSON field naming:

```java
// Request DTO for Ambulance Booking
public record RequestAmbulanceRequest(
    String idempotencyKey,
    @NotNull Priority priority,
    AmbulanceType ambulanceType,
    Boolean applyWallet,
    @NotNull LocationDto pickup,
    @NotNull LocationDto drop,
    @NotNull PatientInfoDto patient,
    String notes,
    Instant scheduledFor
) {}

// Response DTO
public record RequestAmbulanceResponse(
    UUID requestId,
    String requestNumber,
    RequestStatus status,
    Instant createdAt,
    Double baseFare,
    Double walletDiscount,
    Double totalPayable,
    PaymentStatus paymentStatus
) {}
```

---

## 7. SECURITY & GUARDS MAPPING (Spring Security)

The NestJS `JwtMiddleware` extracts JWT metadata from the `Authorization: Bearer <token>` header or legacy header `x-jwt-payload`.

### Spring Security Architecture
1. **`JwtAuthenticationFilter`** (`OncePerRequestFilter`):
   - Extracts Token / `x-jwt-payload`.
   - Decodes claims (`sub`, `name`, `phone`, `role`).
   - Populates `SecurityContextHolder.getContext().setAuthentication(...)` with `UsernamePasswordAuthenticationToken` containing granted authorities (`ROLE_PATIENT`, `ROLE_DISPATCHER`, `ROLE_ADMIN`, `ROLE_DRIVER`).

2. **`SecurityConfig`** (`SecurityFilterChain` bean):
   ```java
   @Bean
   public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
       http
           .csrf(AbstractHttpConfigurer::disable)
           .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
           .authorizeHttpRequests(auth -> auth
               .requestMatchers("/driver-app/auth/login", "/actuator/health", "/docs/**").permitAll()
               .requestMatchers("/patient/**").hasAnyRole("PATIENT", "DISPATCHER", "ADMIN")
               .requestMatchers("/dispatcher/**").hasAnyRole("DISPATCHER", "ADMIN")
               .requestMatchers("/vendor/**").hasAnyRole("VENDOR", "ADMIN")
               .requestMatchers("/driver-app/**").hasAnyRole("DRIVER", "ADMIN")
               .requestMatchers("/admin/**").hasRole("ADMIN")
               .anyRequest().authenticated()
           )
           .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
       return http.build();
   }
   ```

---

## 8. QUEUE STRATEGY (BullMQ $\rightarrow$ Redisson / Redis Queues)

To replace BullMQ without requiring an external RabbitMQ/Kafka message broker, we use **Redisson** (`org.redisson:redisson-spring-boot-starter`). Redisson provides native Redis-backed Delayed Queues, Blocking Queues, and Retry Executors matching BullMQ functionality.

### Queue Definitions
1. **`bookingQueue`** (`RBlockingQueue<BookingJobPayload>` + `RDelayedQueue`):
   - **Producer**: `PatientRequestService.processPayment()` enqueues job upon payment success.
   - **Consumer**: `@Scheduled` worker thread pool reading `bookingQueue.take()`. Calls `VendorManagerService.dispatchBooking()`.
   - **Retries**: Max 5 attempts with 1000ms exponential backoff.
2. **`trackingQueue`** (`RBlockingQueue<TrackingJobPayload>`):
   - **Producer**: Enqueued when vendor accepts dispatch.
   - **Consumer**: Polls vendor position updates every 2 seconds.
3. **`deadLetterQueue`** (`DlqService`):
   - When job attempts exceed max retries, `DlqService.persist()` writes payload and error details into table `dead_letter_jobs`.

---

## 9. WEBSOCKET STRATEGY (Socket.IO $\rightarrow$ Netty-SocketIO)

Flutter mobile app relies on `socket_io_client` connecting to namespace `/ws`. Standard Spring STOMP WebSockets are not protocol-compatible with Socket.IO.

### Implementation: Netty-SocketIO (`com.corundumstudio.socketio:netty-socketio:2.0.12`)

```java
@Component
public class SocketIOServerRunner implements CommandLineRunner {
    
    private final SocketIOServer server;

    @Autowired
    public SocketIOServerRunner(SocketIOServer server) {
        this.server = server;
    }

    @Override
    public run(String... args) {
        SocketIONamespace ns = server.addNamespace("/ws");
        ns.addEventListener("subscribe", SubscribeDto.class, (client, data, ack) -> {
            client.joinRoom(data.requestId().toString());
        });
        ns.addEventListener("driver:location", DriverLocationDto.class, (client, data, ack) -> {
            // Process real-time location update
        });
        server.start();
    }
}
```

This guarantees **zero modifications required in the Flutter mobile application or Web portal**.

---

## 10. EXCEPTION HANDLING (`@ControllerAdvice`)

The global exception handler mirrors NestJS default HTTP exception JSON response format:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(CustomBusinessException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessException(CustomBusinessException ex) {
        Map<String, Object> body = Map.of(
            "statusCode", ex.getStatus().value(),
            "message", ex.getMessage(),
            "error", ex.getStatus().getReasonPhrase(),
            "timestamp", Instant.now().toString()
        );
        return ResponseEntity.status(ex.getStatus()).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult().getFieldErrors().stream()
            .map(err -> err.getField() + ": " + err.getDefaultMessage())
            .toList();
        Map<String, Object> body = Map.of(
            "statusCode", 400,
            "message", errors,
            "error", "Bad Request",
            "timestamp", Instant.now().toString()
        );
        return ResponseEntity.badRequest().body(body);
    }
}
```

---

## 11. CONFIGURATION & ENVIRONMENT VARIABLES (`application.yml`)

```yaml
server:
  port: ${PORT:3000}

spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:127.0.0.1}:${DB_PORT:5433}/${DB_NAME:ambulance}
    username: ${DB_USER:postgres}
    password: ${DB_PASS:letsgo}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
  data:
    redis:
      host: ${REDIS_HOST:127.0.0.1}
      port: ${REDIS_PORT:6379}
  flyway:
    enabled: true
    baseline-on-migrate: true

jwt:
  secret: ${JWT_SECRET:supersecret_jwt_key_for_dev_environment_only_change_in_production_12345}

socketio:
  port: ${SOCKET_PORT:3001}
  namespace: "/ws"

google:
  maps:
    api-key: ${GOOGLE_MAPS_API_KEY:mock-key}
```

---

## 12. DATABASE MIGRATION STRATEGY (Flyway)

Flyway migration script `src/main/resources/db/migration/V1__initial_schema.sql` creates all tables, primary keys, foreign keys, and indexes matching PostgreSQL 18.

---

## 13. PROPOSED JAVA PROJECT DIRECTORY STRUCTURE

```
ambulance-backend-java/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/
    │   │   └── com/
    │   │       └── callhealth/
    │   │           └── ambulance/
    │   │               ├── AmbulanceApplication.java
    │   │               ├── audit/
    │   │               │   ├── aspect/
    │   │               │   │   └── AuditLogAspect.java
    │   │               │   ├── controller/
    │   │               │   │   └── AuditController.java
    │   │               │   ├── entity/
    │   │               │   │   └── SystemAuditLog.java
    │   │               │   ├── repository/
    │   │               │   │   └── SystemAuditLogRepository.java
    │   │               │   └── service/
    │   │               │       └── AuditService.java
    │   │               ├── common/
    │   │               │   ├── exception/
    │   │               │   │   ├── CustomBusinessException.java
    │   │               │   │   └── GlobalExceptionHandler.java
    │   │               │   └── util/
    │   │               │       └── IdempotencyUtil.java
    │   │               ├── dispatcher/
    │   │               │   ├── controller/
    │   │               │   │   └── DispatcherController.java
    │   │               │   ├── dto/
    │   │               │   │   └── AssignDriverRequest.java
    │   │               │   └── service/
    │   │               │       ├── DispatcherDashboardService.java
    │   │               │       └── DispatcherService.java
    │   │               ├── driver/
    │   │               │   ├── controller/
    │   │               │   │   └── DriverController.java
    │   │               │   ├── entity/
    │   │               │   │   └── Driver.java
    │   │               │   └── repository/
    │   │               │       └── DriverRepository.java
    │   │               ├── fleet/
    │   │               │   ├── entity/
    │   │               │   │   └── AmbulanceVehicle.java
    │   │               │   └── repository/
    │   │               │       └── AmbulanceVehicleRepository.java
    │   │               ├── patient/
    │   │               │   ├── controller/
    │   │               │   │   └── PatientRequestController.java
    │   │               │   ├── dto/
    │   │               │   │   ├── LocationDto.java
    │   │               │   │   ├── RequestAmbulanceRequest.java
    │   │               │   │   ├── RequestAmbulanceResponse.java
    │   │               │   │   └── TrackingSnapshotResponse.java
    │   │               │   ├── entity/
    │   │               │   │   ├── AmbulanceRequest.java
    │   │               │   │   ├── PatientWallet.java
    │   │               │   │   ├── PaymentTransaction.java
    │   │               │   │   └── TrackingPosition.java
    │   │               │   ├── repository/
    │   │               │   │   ├── AmbulanceRequestRepository.java
    │   │               │   │   ├── PatientWalletRepository.java
    │   │               │   │   ├── PaymentTransactionRepository.java
    │   │               │   │   └── TrackingPositionRepository.java
    │   │               │   └── service/
    │   │               │       ├── GeocodingService.java
    │   │               │       └── PatientRequestService.java
    │   │               ├── queue/
    │   │               │   ├── entity/
    │   │               │   │   └── DlqJob.java
    │   │               │   ├── processor/
    │   │               │   │   ├── BookingQueueProcessor.java
    │   │               │   │   └── TrackingQueueProcessor.java
    │   │               │   ├── repository/
    │   │               │   │   └── DlqJobRepository.java
    │   │               │   └── service/
    │   │               │       └── DlqService.java
    │   │               ├── security/
    │   │               │   ├── config/
    │   │               │   │   └── SecurityConfig.java
    │   │               │   ├── filter/
    │   │               │   │   └── JwtAuthenticationFilter.java
    │   │               │   └── util/
    │   │               │       └── JwtTokenProvider.java
    │   │               ├── vendor/
    │   │               │   ├── adapter/
    │   │               │   │   ├── AmbulanceVendor.java
    │   │               │   │   └── MockVendorAdapter.java
    │   │               │   ├── controller/
    │   │               │   │   └── VendorController.java
    │   │               │   └── service/
    │   │               │       ├── VendorDashboardService.java
    │   │               │       └── VendorManagerService.java
    │   │               └── websocket/
    │   │                   ├── config/
    │   │                   │   └── SocketIOConfig.java
    │   │                   └── server/
    │   │                       └── SocketIOServerRunner.java
    │   └── resources/
    │       ├── application.yml
    │       └── db/
    │           └── migration/
    │               └── V1__initial_schema.sql
    └── test/
        └── java/
            └── com/
                └── callhealth/
                    └── ambulance/
                        ├── patient/
                        │   └── PatientRequestControllerTest.java
                        └── vendor/
                            └── MockVendorAdapterTest.java
```
