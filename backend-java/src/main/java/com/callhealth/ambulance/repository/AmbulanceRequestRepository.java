package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.AmbulanceRequest;
import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AmbulanceRequestRepository extends JpaRepository<AmbulanceRequest, UUID>, JpaSpecificationExecutor<AmbulanceRequest> {
    Optional<AmbulanceRequest> findByRequestNumber(String requestNumber);
    Optional<AmbulanceRequest> findByIdempotencyKey(String idempotencyKey);
    List<AmbulanceRequest> findByPatientIdOrderByCreatedAtDesc(String patientId);
    List<AmbulanceRequest> findByStatusIn(List<AmbulanceRequestStatus> statuses);
    long countByStatus(AmbulanceRequestStatus status);
}
