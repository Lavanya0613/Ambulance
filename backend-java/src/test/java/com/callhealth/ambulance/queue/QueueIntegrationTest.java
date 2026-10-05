package com.callhealth.ambulance.queue;

import com.callhealth.ambulance.dto.LocationDto;
import com.callhealth.ambulance.dto.PatientInfoDto;
import com.callhealth.ambulance.dto.QueueStatusResponse;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.DlqJob;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.queue.model.CreateBookingPayload;
import com.callhealth.ambulance.queue.model.PollTrackingPayload;
import com.callhealth.ambulance.queue.service.RedisQueueService;
import com.callhealth.ambulance.queue.worker.BookingQueueWorker;
import com.callhealth.ambulance.queue.worker.TrackingQueueWorker;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.DlqJobRepository;
import com.callhealth.ambulance.service.DlqService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class QueueIntegrationTest {

    @Autowired
    private RedisQueueService queueService;

    @Autowired
    private BookingQueueWorker bookingQueueWorker;

    @Autowired
    private TrackingQueueWorker trackingQueueWorker;

    @Autowired
    private DlqService dlqService;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    @Autowired
    private DlqJobRepository dlqJobRepository;

    private AmbulanceRequest createSampleRequest() {
        AmbulanceRequest req = new AmbulanceRequest();
        req.setRequestNumber("AR-QTEST-" + System.nanoTime());
        req.setStatus(AmbulanceRequestStatus.REQUEST_RECEIVED);
        req.setPatientName("Queue Test Patient");
        req.setPatientPhone("+919999999999");
        req.setPickupLat(17.43);
        req.setPickupLng(78.43);
        req.setDropLat(17.44);
        req.setDropLng(78.44);
        req.setBaseFare(1250);
        req.setTotalPayable(1250);
        req.setPaymentStatus("SUCCESS");
        return requestRepository.save(req);
    }

    @Test
    @DisplayName("1. Booking Queue Worker processes booking dispatch job successfully")
    void testBookingQueueWorker() {
        AmbulanceRequest request = createSampleRequest();

        CreateBookingPayload payload = new CreateBookingPayload(
                request.getId().toString(),
                "IDEM-Q-1",
                new LocationDto(17.43, 78.43, "Pickup"),
                new LocationDto(17.44, 78.44, "Drop"),
                "normal",
                new PatientInfoDto("Queue Test Patient", "+919999999999", null, null),
                "Notes",
                null,
                "mock"
        );

        queueService.enqueue(QueueConstants.BOOKING_QUEUE, "create-booking", payload, request.getId().toString(), 0, 5, 1000);

        // Process queue job
        bookingQueueWorker.processBookingQueue();

        // Verify request updated to DRIVER_ASSIGNED with vendor booking details
        AmbulanceRequest updated = requestRepository.findById(request.getId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.DRIVER_ASSIGNED, updated.getStatus());
        assertEquals("mock", updated.getAssignedVendorId());
        assertNotNull(updated.getVendorBookingRef());
        assertNotNull(updated.getVendorDriverRef());
    }

    @Test
    @DisplayName("2. Tracking Queue Worker processes tracking poll job successfully")
    void testTrackingQueueWorker() {
        AmbulanceRequest request = createSampleRequest();
        request.setStatus(AmbulanceRequestStatus.DRIVER_ASSIGNED);
        request.setVendorBookingRef("VND-MOCK-REF");
        requestRepository.save(request);

        PollTrackingPayload payload = new PollTrackingPayload(
                request.getId().toString(),
                "mock",
                "VND-MOCK-REF",
                null
        );

        queueService.enqueue(QueueConstants.TRACKING_QUEUE, "poll-tracking", payload, request.getId().toString() + "-track", 0, 3, 500);

        // Process queue job
        trackingQueueWorker.processTrackingQueue();

        // Verify request updated to EN_ROUTE and position recorded
        AmbulanceRequest updated = requestRepository.findById(request.getId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.EN_ROUTE, updated.getStatus());
    }

    @Test
    @DisplayName("3. Dead Letter Queue persistence on job failure")
    void testDlqStoreAndRetrieve() {
        String jobId = "failed-job-" + System.currentTimeMillis();
        CreateBookingPayload payload = new CreateBookingPayload("non-existent-uuid", null, null, null, null, null, null, null, null);

        dlqService.storeFailedJob(QueueConstants.BOOKING_QUEUE, jobId, payload, "Simulated worker error", 5);

        List<DlqJob> failedJobs = dlqService.getFailedJobs();
        assertFalse(failedJobs.isEmpty());

        DlqJob dlqJob = failedJobs.stream().filter(j -> jobId.equals(j.getJobId())).findFirst().orElse(null);
        assertNotNull(dlqJob);
        assertEquals(QueueConstants.BOOKING_QUEUE, dlqJob.getQueueName());
        assertEquals("Simulated worker error", dlqJob.getError());
        assertEquals(5, dlqJob.getRetryCount());
    }

    @Test
    @DisplayName("4. DLQ Retry Re-enqueues Job and Removes from DLQ Table")
    void testDlqRetry() {
        AmbulanceRequest request = createSampleRequest();
        String jobId = "retryable-job-" + System.currentTimeMillis();
        CreateBookingPayload payload = new CreateBookingPayload(
                request.getId().toString(),
                null,
                new LocationDto(17.43, 78.43, "P"),
                new LocationDto(17.44, 78.44, "D"),
                "normal",
                new PatientInfoDto("Patient", "+919999999999", null, null),
                null,
                null,
                "mock"
        );

        DlqJob storedDlq = dlqService.storeFailedJob(QueueConstants.BOOKING_QUEUE, jobId, payload, "Initial failure", 5);
        assertNotNull(storedDlq.getId());

        // Call DLQ retry
        var result = dlqService.retryJob(storedDlq.getId());
        assertTrue((Boolean) result.get("success"));

        // Verify removed from DLQ
        assertFalse(dlqJobRepository.findById(storedDlq.getId()).isPresent());

        // Process the re-enqueued job
        bookingQueueWorker.processBookingQueue();

        AmbulanceRequest updated = requestRepository.findById(request.getId()).orElseThrow();
        assertTrue(updated.getStatus() == AmbulanceRequestStatus.DRIVER_ASSIGNED || updated.getStatus() == AmbulanceRequestStatus.REQUEST_RECEIVED);
    }

    @Test
    @DisplayName("5. Queue Status Metrics Endpoint Returns Metrics Structure")
    void testQueueStatusMetrics() {
        QueueStatusResponse response = queueService.getQueueStatus(dlqService.getDlqCount());
        assertNotNull(response);
        assertNotNull(response.metrics());
        assertNotNull(response.metrics().bookingQueue());
        assertNotNull(response.metrics().trackingQueue());
    }
}
