# Vendor Adapter Architecture — Final (CallHealth)

This document consolidates the vendor adapter design: MockVendorAdapter, vendor onboarding checklist, error & retry strategy, folder layout, class relationships, and operational notes.

## 1. MockVendorAdapter

Purpose: deterministic, controllable adapter used for local development, integration tests, staging pilots, and chaos testing.

Capabilities
- Implements the `AmbulanceVendor` contract and exposes `capabilities` metadata.
- Supports `createBooking`, `cancelBooking`, `getBookingStatus`, `pollTracking`.
- `pushTracking` disabled by default; can simulate webhook pushes.

Config
- `mode`: `deterministic | stochastic` (deterministic for CI, stochastic for chaos)
- `acceptanceRate`: 0..1 (probability of accepting bookings)
- `responseDelayMs`: fixed or distribution spec (mean, stddev)
- `simulateFailures`: presets (none, transient-timeout, http-5xx, duplicate-events)
- `fixtureSet`: path to fixture JSON files for test scenarios
- `routeProfiles`: pre-defined polyline and timing profiles for tracking generation

Behavior
- Deterministic mode returns predictable booking refs and ETA based on `requestId` hash.
- Stochastic mode injects failures and latencies per `simulateFailures` rules.
- Tracking generator: emits location points along a route profile at configured frequency; supports pause/resume and speed variation.
- Webhook simulator: posts events to `WebhookController` endpoint to verify ingestion and dedup behavior.

Testing and Integration
- Provide REST endpoints (dev-only) to control behavior: `/admin/mock/fixture/load`, `/admin/mock/simulate/failure`.
- Include `contract-tests` that the adapter must pass (see section 7).
- Use MockVendorAdapter in CI to validate orchestration, reconcilers, and UI behavior without external vendor dependencies.

Observability
- Emit metrics: `mock_booking_calls`, `mock_tracking_points`, `mock_failure_injections`.
- Logs include deterministic seed info for reproducibility.

Security
- Remove admin endpoints behind `NODE_ENV !== production` and basic auth.


## 2. Vendor Onboarding Process (Operational Checklist)

Pre-flight (Legal & Ops)
- Contract signed and SLAs documented (uptime, RTO, rate limits, webhook retry policy).
- Exchange sandbox & production credentials and webhook secrets.
- Agree on data retention and PII handling.

Technical Discovery
- Collect vendor API spec (endpoints, auth, payload samples, error codes).
- Vendor capability manifest: pushTracking, webhooks, cancelSupport, ETAAccuracy, ambulance types, region coverage.
- Sample payloads and schemas for booking and tracking.

Adapter Implementation
- Scaffold adapter using `src/vendor/adapters/adapter-template.md`.
- Implement `AmbulanceVendor` interface methods and `mapVendorToCanonical`.
- Implement webhook verification and signature validation.

Testing
- Run `contract-tests` locally against vendor sandbox.
- Validate idempotency by replaying booking create with same idempotencyKey.
- Validate dedupe by replaying webhook events (duplicate vendorEventId).
- Load & chaos tests for rate limits, timeouts, partial failures.

Security & Compliance
- Verify TLS and cert pinning if required.
- Secrets provisioned into secret manager; confirm minimal scopes.

Pilot & Rollout
- Enable via feature flag for single region and tenant.
- Monitor metrics for fallback rate, latency, booking success.
- Escalate or rollback based on SLO deviations.

Acceptance Criteria
- Passes all contract tests.
- Fallback rate < 1% during pilot.
- No unhandled exceptions or unverified webhook events.


## 3. Error Handling & Retry Strategy (Canonical)

Categories (VendorError.category):
- AUTH (non-retryable): invalid credentials, 401/403
- RATE_LIMIT (retryable): 429, with optional Retry-After
- TRANSIENT (retryable): 5xx, network timeouts
- PERMANENT (non-retryable): business rejections, invalid data
- UNKNOWN (treat as TRANSIENT by default)

Adapter Contract
- Adapters must return canonical `VendorError` objects with: `{ code, category, retryable, vendorCode, vendorMessage }`.
- Adapters should not throw raw vendor error types; map them first.

Retry Rules
- For TRANSIENT and RATE_LIMIT:
  - Immediate local retry: 1 attempt with short delay if operation is idempotent-safe.
  - If still failing, enqueue a BullMQ retry job with exponential backoff and jitter: base=2000ms, factor=2, jitter=0.2, maxAttempts=5.
  - For RATE_LIMIT with Retry-After header, schedule next attempt at `Retry-After`.
- For PERMANENT and AUTH:
  - Do not retry. For PERMANENT, try fallback vendor. For AUTH, alert ops & mark vendor degraded.

Dead Letter and Reconciliation
- After max retries, job moves to DLQ; create `retry_logs` record and emit alert.
- Reconciliation worker periodically polls vendor for unresolved bookings and attempts recovery.

Idempotency
- Every external intent must include `idempotency_key` persisted at `ambulance_requests` and passed in adapter call headers.
- Duplicate outbound attempts do not create duplicate bookings; adapter must detect duplicates and return canonical success.

Deduplication (incoming events)
- Persist `vendor_event_id` in `vendor_events` table; unique constraint prevents double-processing.

Observability & Alerts
- Track `vendor_retry_count`, `vendor_dlq_depth`, `fallback_rate`.
- Alert on spikes in `fallback_rate` or growing DLQ depth.


## 4. Folder Structure (Final)

- `src/vendor/`
  - `index.ts`
  - `interfaces/`
    - `ambulance-vendor.ts` (interface & capability types)
    - `vendor-types.ts`
  - `manager/`
    - `vendor-manager.ts`
    - `registry.ts`
    - `strategies/`
      - `selection-strategy.ts`
      - `sla-weighted.ts`
    - `policy/`
      - `circuit-breaker.ts`
      - `rate-limiter.ts`
    - `health/`
      - `health-scoring.ts`
    - `admin-controller.ts`
  - `adapters/`
    - `red-health/`
      - `red-health-adapter.ts`
      - `mapper.ts`
      - `auth.ts`
      - `webhook.ts`
      - `config.ts`
    - `mock/`
      - `mock-vendor-adapter.ts`
      - `fixtures/`
      - `admin-controller.ts`
  - `reconcile/`
    - `reconcile-worker.ts`
    - `polling.ts`
  - `tests/`
    - `contract-tests/`
    - `integration/`
  - `docs/`
    - `onboarding-checklist.md`
    - `adapter-template.md`


## 5. Class Relationships (High-level)

- `VendorManager` (singleton)
  - depends on `Registry` to list adapters
  - uses `selection-strategy` to pick adapter
  - consults `policy` (circuit-breaker, rate-limiter)
  - calls `AmbulanceVendor` implementations for operations
  - enqueues retries via `BullMQ` if needed

- `AmbulanceVendor` implementations
  - `RedHealthAdapter` and `MockVendorAdapter` implement interface and mapping helpers
  - expose `capabilities`, `healthCheck()`

- `WebhookController`
  - routes raw vendor webhooks to adapter-specific `webhook.verify()` and `webhook.mapToCanonical()`

- `ReconcileWorker`
  - calls `VendorManager.pollTracking()` or `adapter.getBookingStatus()` for ambiguous bookings

- `Orchestrator` (higher layer)
  - calls `VendorManager.orchestrateCreateBooking()` and receives canonical results


## 6. Contract Test Checklist (must pass for any adapter)

1. Idempotency: repeated createBooking with same idempotencyKey returns identical result.
2. Dedup: repeated webhook events with same `vendorEventId` are ignored.
3. Error mapping: vendor 5xx -> TRANSIENT, 401 -> AUTH, 429 -> RATE_LIMIT.
4. Webhook signature: invalid signature rejected; valid accepted.
5. Reconciliation: polling returns correct booking status and state updates are idempotent.
6. Rate-limit handling: adapter respects `rateLimitPerMin` and surfaces RATE_LIMIT errors.


## 7. Operational Playbooks (short)

- Vendor Degraded: Set vendor to `degraded` via admin API, VendorManager routes to fallback, run `reconcile` for ambiguous bookings, contact vendor.
- Webhook Flood: throttle webhooks per vendor and backpressure to queue; record `webhook_signature_failures` and block if attack suspected.
- Credential Rotation: rotate secret in secret manager, call `adapter.reloadCredentials()` and run smoke tests.


## 8. Next Steps

- Add `adapter-template.md` into `src/vendor/adapters/` (I can scaffold if you want).
- Create a `contract-tests` harness with deterministic scenarios using `MockVendorAdapter`.
- Generate sequence diagrams and sample mapping tables for Red Health's sample payloads.

---

File produced: `vendor-adapter-architecture.md`.
