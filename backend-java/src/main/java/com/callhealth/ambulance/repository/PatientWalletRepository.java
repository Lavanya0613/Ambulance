package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.PatientWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PatientWalletRepository extends JpaRepository<PatientWallet, String> {
    Optional<PatientWallet> findByPatientId(String patientId);
}
