package com.callhealth.ambulance.model.entity;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "tracking_positions")
public class TrackingPosition {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "vendorEventId", nullable = false, unique = true)
    private String vendorEventId;

    @Column(name = "lat", nullable = false)
    private double lat;

    @Column(name = "lng", nullable = false)
    private double lng;

    @Column(name = "speedKmph")
    private Double speedKmph;

    @Column(name = "headingDeg")
    private Double headingDeg;

    @Column(name = "capturedAt", nullable = false)
    private Instant capturedAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requestId")
    private AmbulanceRequest ambulanceRequest;

    public TrackingPosition() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getVendorEventId() { return vendorEventId; }
    public void setVendorEventId(String vendorEventId) { this.vendorEventId = vendorEventId; }

    public double getLat() { return lat; }
    public void setLat(double lat) { this.lat = lat; }

    public double getLng() { return lng; }
    public void setLng(double lng) { this.lng = lng; }

    public Double getSpeedKmph() { return speedKmph; }
    public void setSpeedKmph(Double speedKmph) { this.speedKmph = speedKmph; }

    public Double getHeadingDeg() { return headingDeg; }
    public void setHeadingDeg(Double headingDeg) { this.headingDeg = headingDeg; }

    public Instant getCapturedAt() { return capturedAt; }
    public void setCapturedAt(Instant capturedAt) { this.capturedAt = capturedAt; }

    public AmbulanceRequest getAmbulanceRequest() { return ambulanceRequest; }
    public void setAmbulanceRequest(AmbulanceRequest ambulanceRequest) { this.ambulanceRequest = ambulanceRequest; }
}
