package com.callhealth.ambulance.model.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "patient_wallet")
public class PatientWallet {

    @Id
    @Column(name = "patientId", nullable = false)
    private String patientId;

    @Column(name = "ambulanceBenefitUsed", nullable = false)
    private boolean ambulanceBenefitUsed = false;

    @CreationTimestamp
    @Column(name = "createdAt", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updatedAt", nullable = false)
    private LocalDateTime updatedAt;

    public PatientWallet() {}

    public PatientWallet(String patientId, boolean ambulanceBenefitUsed) {
        this.patientId = patientId;
        this.ambulanceBenefitUsed = ambulanceBenefitUsed;
    }

    public String getPatientId() { return patientId; }
    public void setPatientId(String patientId) { this.patientId = patientId; }

    public boolean isAmbulanceBenefitUsed() { return ambulanceBenefitUsed; }
    public void setAmbulanceBenefitUsed(boolean ambulanceBenefitUsed) { this.ambulanceBenefitUsed = ambulanceBenefitUsed; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
