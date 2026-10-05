package com.callhealth.ambulance.repository;

import com.callhealth.ambulance.model.entity.DlqJob;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

import java.util.List;

@Repository
public interface DlqJobRepository extends JpaRepository<DlqJob, UUID> {
    Page<DlqJob> findAllByOrderByFailedAtDesc(Pageable pageable);
    List<DlqJob> findAllByOrderByFailedAtDesc();
}
