package com.Wearther.api.repository;

import com.Wearther.api.entity.Trip;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface TripRepository extends JpaRepository<Trip, Long> {
    List<Trip> findByUserId(Long userId);
    long countByUserId(Long userId);
}
