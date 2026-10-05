package com.callhealth.ambulance.model.entity;

import com.callhealth.ambulance.model.enums.AmbulanceRequestStatus;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcType;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "ambulance_requests")
public class AmbulanceRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "requestNumber", nullable = false, unique = true)
    private String requestNumber;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false)
    private AmbulanceRequestStatus status = AmbulanceRequestStatus.REQUEST_RECEIVED;

    @Column(name = "pickupAddress")
    private String pickupAddress;

    @Column(name = "pickupLat", nullable = false)
    private double pickupLat;

    @Column(name = "pickupLng", nullable = false)
    private double pickupLng;

    @Column(name = "dropAddress")
    private String dropAddress;

    @Column(name = "dropLat", nullable = false)
    private double dropLat;

    @Column(name = "dropLng", nullable = false)
    private double dropLng;

    @Column(name = "patientId")
    private String patientId;

    @Column(name = "patientName", nullable = false)
    private String patientName;

    @Column(name = "patientPhone", nullable = false)
    private String patientPhone;

    @Column(name = "notes")
    private String notes;

    @Column(name = "priority")
    private String priority;

    @Column(name = "scheduledFor")
    private Instant scheduledFor;

    @Column(name = "idempotencyKey")
    private String idempotencyKey;

    @Column(name = "assignedVendorId")
    private String assignedVendorId;

    @Column(name = "vendorBookingRef")
    private String vendorBookingRef;

    @Column(name = "vendorDriverRef")
    private String vendorDriverRef;

    @Column(name = "vendorDriverName")
    private String vendorDriverName;

    @Column(name = "vendorDriverPhone")
    private String vendorDriverPhone;

    @Column(name = "vendorVehicleNumber")
    private String vendorVehicleNumber;

    @Column(name = "vendorAmbulanceType")
    private String vendorAmbulanceType;

    @Column(name = "etaSeconds")
    private Integer etaSeconds;

    @Column(name = "cancelReason")
    private String cancelReason;

    @Column(name = "baseFare")
    private Integer baseFare;

    @Column(name = "walletDiscount")
    private Integer walletDiscount = 0;

    @Column(name = "totalPayable")
    private Integer totalPayable;

    @Column(name = "paymentRef")
    private String paymentRef;

    @Column(name = "paymentStatus")
    private String paymentStatus;

    @CreationTimestamp
    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updatedAt", nullable = false)
    private LocalDateTime updatedAt;

    @JsonIgnore
    @OneToMany(mappedBy = "ambulanceRequest", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<TrackingPosition> trackingPositions = new ArrayList<>();

    public AmbulanceRequest() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getRequestNumber() { return requestNumber; }
    public void setRequestNumber(String requestNumber) { this.requestNumber = requestNumber; }

    public AmbulanceRequestStatus getStatus() { return status; }
    public void setStatus(AmbulanceRequestStatus status) { this.status = status; }

    public String getPickupAddress() { return pickupAddress; }
    public void setPickupAddress(String pickupAddress) { this.pickupAddress = pickupAddress; }

    public double getPickupLat() { return pickupLat; }
    public void setPickupLat(double pickupLat) { this.pickupLat = pickupLat; }

    public double getPickupLng() { return pickupLng; }
    public void setPickupLng(double pickupLng) { this.pickupLng = pickupLng; }

    public String getDropAddress() { return dropAddress; }
    public void setDropAddress(String dropAddress) { this.dropAddress = dropAddress; }

    public double getDropLat() { return dropLat; }
    public void setDropLat(double dropLat) { this.dropLat = dropLat; }

    public double getDropLng() { return dropLng; }
    public void setDropLng(double dropLng) { this.dropLng = dropLng; }

    public String getPatientId() { return patientId; }
    public void setPatientId(String patientId) { this.patientId = patientId; }

    public String getPatientName() { return patientName; }
    public void setPatientName(String patientName) { this.patientName = patientName; }

    public String getPatientPhone() { return patientPhone; }
    public void setPatientPhone(String patientPhone) { this.patientPhone = patientPhone; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getPriority() { return priority; }
    public void setPriority(String priority) { this.priority = priority; }

    public Instant getScheduledFor() { return scheduledFor; }
    public void setScheduledFor(Instant scheduledFor) { this.scheduledFor = scheduledFor; }

    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }

    public String getAssignedVendorId() { return assignedVendorId; }
    public void setAssignedVendorId(String assignedVendorId) { this.assignedVendorId = assignedVendorId; }

    public String getVendorBookingRef() { return vendorBookingRef; }
    public void setVendorBookingRef(String vendorBookingRef) { this.vendorBookingRef = vendorBookingRef; }

    public String getVendorDriverRef() { return vendorDriverRef; }
    public void setVendorDriverRef(String vendorDriverRef) { this.vendorDriverRef = vendorDriverRef; }

    public String getVendorDriverName() { return vendorDriverName; }
    public void setVendorDriverName(String vendorDriverName) { this.vendorDriverName = vendorDriverName; }

    public String getVendorDriverPhone() { return vendorDriverPhone; }
    public void setVendorDriverPhone(String vendorDriverPhone) { this.vendorDriverPhone = vendorDriverPhone; }

    public String getVendorVehicleNumber() { return vendorVehicleNumber; }
    public void setVendorVehicleNumber(String vendorVehicleNumber) { this.vendorVehicleNumber = vendorVehicleNumber; }

    public String getVendorAmbulanceType() { return vendorAmbulanceType; }
    public void setVendorAmbulanceType(String vendorAmbulanceType) { this.vendorAmbulanceType = vendorAmbulanceType; }

    public Integer getEtaSeconds() { return etaSeconds; }
    public void setEtaSeconds(Integer etaSeconds) { this.etaSeconds = etaSeconds; }

    public String getCancelReason() { return cancelReason; }
    public void setCancelReason(String cancelReason) { this.cancelReason = cancelReason; }

    public Integer getBaseFare() { return baseFare; }
    public void setBaseFare(Integer baseFare) { this.baseFare = baseFare; }

    public Integer getWalletDiscount() { return walletDiscount; }
    public void setWalletDiscount(Integer walletDiscount) { this.walletDiscount = walletDiscount; }

    public Integer getTotalPayable() { return totalPayable; }
    public void setTotalPayable(Integer totalPayable) { this.totalPayable = totalPayable; }

    public String getPaymentRef() { return paymentRef; }
    public void setPaymentRef(String paymentRef) { this.paymentRef = paymentRef; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public List<TrackingPosition> getTrackingPositions() { return trackingPositions; }
    public void setTrackingPositions(List<TrackingPosition> trackingPositions) { this.trackingPositions = trackingPositions; }
}
