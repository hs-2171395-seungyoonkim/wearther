package com.Wearther.api.repository;

import com.Wearther.api.entity.WornLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface WornLogRepository extends JpaRepository<WornLog, Long> {
    List<WornLog> findByUserIdAndDateBetweenOrderByDate(Long userId, LocalDate from, LocalDate to);
    Optional<WornLog> findByUserIdAndDate(Long userId, LocalDate date);
}
