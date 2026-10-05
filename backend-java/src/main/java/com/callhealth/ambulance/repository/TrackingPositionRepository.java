package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.TrackingPosition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TrackingPositionRepository extends JpaRepository<TrackingPosition, UUID> {
    Optional<TrackingPosition> findByVendorEventId(String vendorEventId);
    List<TrackingPosition> findByAmbulanceRequestIdOrderByCapturedAtAsc(UUID requestId);
    Optional<TrackingPosition> findTopByAmbulanceRequestIdOrderByCapturedAtDesc(UUID requestId);
}
