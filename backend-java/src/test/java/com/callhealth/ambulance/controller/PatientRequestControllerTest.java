package com.callhealth.ambulance.controller;

import com.callhealth.ambulance.dto.PaymentInitiateResponse;
import com.callhealth.ambulance.dto.PaymentStatusResponse;
import com.callhealth.ambulance.dto.ProcessPaymentResponse;
import com.callhealth.ambulance.dto.WalletBenefitResponse;
import com.callhealth.ambulance.model.enums.PaymentStatus;
import com.callhealth.ambulance.service.PatientRequestService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(PatientRequestController.class)
class PatientRequestControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private PatientRequestService patientRequestService;

    @MockBean
    private com.callhealth.ambulance.seed.DemoSeedService demoSeedService;

    @Test
    void getWallet_shouldReturnWalletBenefit() throws Exception {
        Mockito.when(patientRequestService.getWallet("demo-patient"))
                .thenReturn(new WalletBenefitResponse(true, 50));

        mockMvc.perform(get("/patient/requests/wallet").param("patientId", "demo-patient"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ambulanceBenefitEligible").value(true))
                .andExpect(jsonPath("$.ambulanceBenefitAmount").value(50));
    }

    @Test
    void initiatePayment_shouldReturnPendingStatus() throws Exception {
        UUID requestId = UUID.randomUUID();
        Mockito.when(patientRequestService.initiatePayment(ArgumentMatchers.eq(requestId), ArgumentMatchers.any()))
                .thenReturn(new PaymentInitiateResponse("tx-123", PaymentStatus.PENDING));

        mockMvc.perform(post("/patient/requests/" + requestId + "/payment/initiate"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.transactionId").value("tx-123"))
                .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void processPayment_shouldReturnSuccess() throws Exception {
        UUID requestId = UUID.randomUUID();
        Mockito.when(patientRequestService.processPayment(ArgumentMatchers.eq(requestId), ArgumentMatchers.any(), ArgumentMatchers.any()))
                .thenReturn(new ProcessPaymentResponse(PaymentStatus.SUCCESS, "SUCCESS", "tx-ref-123", "tx-ref-123", 1200, "MOCK_PAYMENT", "Payment successful. Ambulance dispatching."));

        mockMvc.perform(post("/patient/requests/" + requestId + "/payment/process")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"simulateFail\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("SUCCESS"))
                .andExpect(jsonPath("$.paymentStatus").value("SUCCESS"))
                .andExpect(jsonPath("$.transactionRef").value("tx-ref-123"));
    }

    @Test
    void getPaymentStatus_shouldReturnStatusDetails() throws Exception {
        UUID requestId = UUID.randomUUID();
        Mockito.when(patientRequestService.getPaymentStatus(ArgumentMatchers.eq(requestId), ArgumentMatchers.any()))
                .thenReturn(new PaymentStatusResponse(requestId, "SUCCESS", "MOCK_TXN_001", 1250, 50, 1200, null));

        mockMvc.perform(get("/patient/requests/" + requestId + "/payment/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paymentStatus").value("SUCCESS"))
                .andExpect(jsonPath("$.transactionRef").value("MOCK_TXN_001"))
                .andExpect(jsonPath("$.totalPayable").value(1200));
    }
}
