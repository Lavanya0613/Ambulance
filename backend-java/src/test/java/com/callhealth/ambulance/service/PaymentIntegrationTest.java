package com.callhealth.ambulance.service;

import com.callhealth.ambulance.dto.*;
import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.entity.PatientWallet;
import com.callhealth.ambulance.model.entity.PaymentTransaction;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.callhealth.ambulance.model.enums.PaymentMethod;
import com.callhealth.ambulance.model.enums.PaymentStatus;
import com.callhealth.ambulance.repository.AmbulanceRequestRepository;
import com.callhealth.ambulance.repository.PatientWalletRepository;
import com.callhealth.ambulance.repository.PaymentTransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class PaymentIntegrationTest {

    @Autowired
    private PatientRequestService patientRequestService;

    @Autowired
    private AmbulanceRequestRepository requestRepository;

    @Autowired
    private PaymentTransactionRepository paymentTransactionRepository;

    @Autowired
    private PatientWalletRepository walletRepository;

    private RequestAmbulanceRequest createTestBookingRequest(boolean applyWallet, String patientName) {
        return new RequestAmbulanceRequest(
                "IDEM-PAY-" + System.nanoTime(),
                new LocationDto(17.43088, 78.43373, "Pickup A"),
                new LocationDto(17.44088, 78.44373, "Drop B"),
                "normal",
                new PatientInfoDto(patientName, "+919876543210", 30, null),
                "Payment test notes",
                null,
                applyWallet,
                "BLS"
        );
    }

    @Test
    @DisplayName("1. Successful Payment Flow")
    void testSuccessfulPayment() {
        String patientId = "patient-success-01";
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(false, "Alice"), patientId);

        // Initiate payment
        PaymentInitiateResponse initResp = patientRequestService.initiatePayment(booking.requestId(), patientId);
        assertNotNull(initResp.transactionId());
        assertEquals(PaymentStatus.PENDING, initResp.status());

        // Process payment with simulateFail = false
        ProcessPaymentResponse processResp = patientRequestService.processPayment(
                booking.requestId(),
                new ProcessPaymentRequest(false),
                patientId
        );

        assertEquals(PaymentStatus.SUCCESS, processResp.status());
        assertEquals("SUCCESS", processResp.paymentStatus());
        assertNotNull(processResp.transactionRef());
        assertTrue(processResp.transactionRef().startsWith("MOCK_TXN_"));
        assertEquals(1250, processResp.amount());
        assertEquals("MOCK_PAYMENT", processResp.paymentMethod());

        // Verify Payment Status endpoint
        PaymentStatusResponse statusResp = patientRequestService.getPaymentStatus(booking.requestId(), patientId);
        assertEquals("SUCCESS", statusResp.paymentStatus());
        assertEquals(processResp.transactionRef(), statusResp.transactionRef());
        assertNotNull(statusResp.tx());
        assertEquals(PaymentStatus.SUCCESS, statusResp.tx().status());
    }

    @Test
    @DisplayName("2. Failed Payment Flow")
    void testFailedPayment() {
        String patientId = "patient-fail-01";
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(false, "Bob"), patientId);

        patientRequestService.initiatePayment(booking.requestId(), patientId);

        // Process payment with simulateFail = true
        ProcessPaymentResponse processResp = patientRequestService.processPayment(
                booking.requestId(),
                new ProcessPaymentRequest(true),
                patientId
        );

        assertEquals(PaymentStatus.FAILED, processResp.status());
        assertEquals("FAILED", processResp.paymentStatus());

        // Verify AmbulanceRequest paymentStatus is FAILED
        AmbulanceRequest reqEntity = requestRepository.findById(booking.requestId()).orElseThrow();
        assertEquals("FAILED", reqEntity.getPaymentStatus());

        // Verify PaymentTransaction status is FAILED
        PaymentTransaction txEntity = paymentTransactionRepository
                .findTopByRequestIdOrderByCreatedAtDesc(booking.requestId().toString()).orElseThrow();
        assertEquals(PaymentStatus.FAILED, txEntity.getStatus());
        assertEquals("Mock payment failure (simulate_fail=true)", txEntity.getFailureReason());
    }

    @Test
    @DisplayName("3. Duplicate Payment Attempt Prevention")
    void testDuplicatePaymentAttempt() {
        String patientId = "patient-dup-01";
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(false, "Charlie"), patientId);

        // First initiate
        PaymentInitiateResponse firstInit = patientRequestService.initiatePayment(booking.requestId(), patientId);

        // Second initiate should reuse the existing transaction
        PaymentInitiateResponse secondInit = patientRequestService.initiatePayment(booking.requestId(), patientId);

        assertEquals(firstInit.transactionId(), secondInit.transactionId());
        List<PaymentTransaction> txList = paymentTransactionRepository.findByRequestId(booking.requestId().toString());
        assertEquals(1, txList.size(), "Should not create duplicate payment transactions");

        // Complete the payment
        patientRequestService.processPayment(booking.requestId(), new ProcessPaymentRequest(false), patientId);

        // Subsequent initiate after success returns 'Payment already completed'
        PaymentInitiateResponse completedInit = patientRequestService.initiatePayment(booking.requestId(), patientId);
        assertEquals(PaymentStatus.SUCCESS, completedInit.status());
        assertEquals("Payment already completed", completedInit.message());

        // Subsequent process after success returns 'Payment already completed'
        ProcessPaymentResponse completedProcess = patientRequestService.processPayment(booking.requestId(), new ProcessPaymentRequest(false), patientId);
        assertEquals(PaymentStatus.SUCCESS, completedProcess.status());
        assertTrue(completedProcess.message().contains("Payment already completed"));
    }

    @Test
    @DisplayName("4. Wallet Applied Successfully on Booking & Consumed on Payment Success")
    void testWalletAppliedAndConsumedOnSuccess() {
        String patientId = "patient-wallet-success-01";

        // Initial wallet check - should be eligible
        WalletBenefitResponse initialWallet = patientRequestService.getWallet(patientId);
        assertTrue(initialWallet.ambulanceBenefitEligible());

        // Create booking with wallet
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(true, "David"), patientId);
        assertEquals(1250, booking.baseFare());
        assertEquals(50, booking.walletDiscount());
        assertEquals(1200, booking.totalPayable());

        // Wallet should NOT be consumed yet before successful payment
        PatientWallet walletBeforePayment = walletRepository.findByPatientId(patientId).orElseThrow();
        assertFalse(walletBeforePayment.isAmbulanceBenefitUsed());

        // Initiate and Process payment
        patientRequestService.initiatePayment(booking.requestId(), patientId);
        patientRequestService.processPayment(booking.requestId(), new ProcessPaymentRequest(false), patientId);

        // Wallet should NOW be consumed
        PatientWallet walletAfterPayment = walletRepository.findByPatientId(patientId).orElseThrow();
        assertTrue(walletAfterPayment.isAmbulanceBenefitUsed());

        // Subsequent wallet query shows not eligible
        WalletBenefitResponse updatedWallet = patientRequestService.getWallet(patientId);
        assertFalse(updatedWallet.ambulanceBenefitEligible());
    }

    @Test
    @DisplayName("5. Wallet Not Consumed on Failed Payment")
    void testWalletNotConsumedOnFailedPayment() {
        String patientId = "patient-wallet-fail-01";

        // Create booking with wallet
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(true, "Eve"), patientId);
        assertEquals(1200, booking.totalPayable());

        // Initiate payment
        patientRequestService.initiatePayment(booking.requestId(), patientId);

        // Process payment with simulateFail = true
        patientRequestService.processPayment(booking.requestId(), new ProcessPaymentRequest(true), patientId);

        // Wallet MUST NOT be consumed on failure
        PatientWallet walletAfterFailure = walletRepository.findByPatientId(patientId).orElseThrow();
        assertFalse(walletAfterFailure.isAmbulanceBenefitUsed(), "Wallet benefit should remain unconsumed on failed payment");

        WalletBenefitResponse walletCheck = patientRequestService.getWallet(patientId);
        assertTrue(walletCheck.ambulanceBenefitEligible());
    }

    @Test
    @DisplayName("6. Payment Transaction Persistence")
    void testPaymentTransactionPersistence() {
        String patientId = "patient-persist-01";
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(false, "Frank"), patientId);

        PaymentInitiateResponse initResp = patientRequestService.initiatePayment(booking.requestId(), patientId);

        // Verify in DB
        PaymentTransaction tx = paymentTransactionRepository.findTopByRequestIdOrderByCreatedAtDesc(booking.requestId().toString()).orElse(null);
        assertNotNull(tx);
        assertEquals(initResp.transactionId(), tx.getId().toString());
        assertEquals(booking.requestId().toString(), tx.getRequestId());
        assertEquals(patientId, tx.getPatientId());
        assertEquals(1250, tx.getAmount());
        assertEquals(PaymentMethod.MOCK, tx.getMethod());
        assertEquals(PaymentStatus.PENDING, tx.getStatus());
    }

    @Test
    @DisplayName("7. Booking State After Successful Payment")
    void testBookingStateAfterSuccessfulPayment() {
        String patientId = "patient-booking-state-01";
        RequestAmbulanceResponse booking = patientRequestService.createRequest(createTestBookingRequest(false, "Grace"), patientId);

        assertEquals(AmbulanceRequestStatus.REQUEST_RECEIVED, booking.status());
        assertEquals("PENDING", booking.paymentStatus());

        patientRequestService.initiatePayment(booking.requestId(), patientId);
        patientRequestService.processPayment(booking.requestId(), new ProcessPaymentRequest(false), patientId);

        AmbulanceRequest updatedBooking = requestRepository.findById(booking.requestId()).orElseThrow();
        assertEquals(AmbulanceRequestStatus.SEARCHING, updatedBooking.getStatus());
        assertEquals("SUCCESS", updatedBooking.getPaymentStatus());
        assertNotNull(updatedBooking.getPaymentRef());
    }
}
