package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.Driver;
import com.callhealth.ambulance.model.enums.DriverStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DriverRepository extends JpaRepository<Driver, UUID> {
    Optional<Driver> findByPhone(String phone);
    List<Driver> findByVendorId(String vendorId);
    List<Driver> findByVendorIdAndStatus(String vendorId, DriverStatus status);
}
