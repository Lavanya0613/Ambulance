package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.AmbulanceVehicle;
import com.callhealth.ambulance.model.enums.VehicleStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AmbulanceVehicleRepository extends JpaRepository<AmbulanceVehicle, UUID> {
    Optional<AmbulanceVehicle> findByVehicleNumber(String vehicleNumber);
    List<AmbulanceVehicle> findByVendorId(String vendorId);
    List<AmbulanceVehicle> findByVendorIdAndStatus(String vendorId, VehicleStatus status);
}
