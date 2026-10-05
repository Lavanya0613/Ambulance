package com.callhealth.ambulance.model.enums;

public enum AmbulanceRequestStatus {
    SCHEDULED,
    PENDING,
    REQUEST_RECEIVED,
    REQUEST_CREATED,
    SEARCHING,
    SEARCHING_DRIVER,
    VENDOR_ACCEPTED,
    DRIVER_ASSIGNED,
    EN_ROUTE,
    ARRIVED,
    TRIP_STARTED,
    PATIENT_ONBOARD,
    DESTINATION_REACHED,
    COMPLETED,
    CANCELLED,
    FAILED
}
