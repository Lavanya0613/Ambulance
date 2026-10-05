package com.callhealth.ambulance.model.entity;

import com.callhealth.ambulance.model.enums.VehicleGpsStatus;
import com.callhealth.ambulance.model.enums.VehicleStatus;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ambulance_vehicles")
public class AmbulanceVehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "vendorId", nullable = false)
    private String vendorId;

    @Column(name = "vehicleNumber", nullable = false)
    private String vehicleNumber;

    @Column(name = "ambulanceType", nullable = false)
    private String ambulanceType;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false)
    private VehicleStatus status = VehicleStatus.AVAILABLE;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "gpsStatus", nullable = false)
    private VehicleGpsStatus gpsStatus = VehicleGpsStatus.OFFLINE;

    @Column(name = "assignedDriverId")
    private String assignedDriverId;

    @Column(name = "assignedDriverName")
    private String assignedDriverName;

    @CreationTimestamp
    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updatedAt", nullable = false)
    private LocalDateTime updatedAt;

    public AmbulanceVehicle() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getVendorId() { return vendorId; }
    public void setVendorId(String vendorId) { this.vendorId = vendorId; }

    public String getVehicleNumber() { return vehicleNumber; }
    public void setVehicleNumber(String vehicleNumber) { this.vehicleNumber = vehicleNumber; }

    public String getAmbulanceType() { return ambulanceType; }
    public void setAmbulanceType(String ambulanceType) { this.ambulanceType = ambulanceType; }

    public VehicleStatus getStatus() { return status; }
    public void setStatus(VehicleStatus status) { this.status = status; }

    public VehicleGpsStatus getGpsStatus() { return gpsStatus; }
    public void setGpsStatus(VehicleGpsStatus gpsStatus) { this.gpsStatus = gpsStatus; }

    public String getAssignedDriverId() { return assignedDriverId; }
    public void setAssignedDriverId(String assignedDriverId) { this.assignedDriverId = assignedDriverId; }

    public String getAssignedDriverName() { return assignedDriverName; }
    public void setAssignedDriverName(String assignedDriverName) { this.assignedDriverName = assignedDriverName; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
