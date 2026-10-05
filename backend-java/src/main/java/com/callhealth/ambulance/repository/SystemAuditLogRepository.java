package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.SystemAuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface SystemAuditLogRepository extends JpaRepository<SystemAuditLog, UUID> {
    Page<SystemAuditLog> findAllByOrderByTimestampDesc(Pageable pageable);
}
