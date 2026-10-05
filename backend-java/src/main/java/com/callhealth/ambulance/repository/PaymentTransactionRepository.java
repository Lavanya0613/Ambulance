package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.PaymentTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

import java.util.Optional;

@Repository
public interface PaymentTransactionRepository extends JpaRepository<PaymentTransaction, UUID> {
    List<PaymentTransaction> findByRequestId(String requestId);
    List<PaymentTransaction> findByPatientId(String patientId);
    Optional<PaymentTransaction> findTopByRequestIdOrderByCreatedAtDesc(String requestId);
}
