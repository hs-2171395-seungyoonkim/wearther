package com.Wearther.api.repository;

import com.Wearther.api.entity.TripDay;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TripDayRepository extends JpaRepository<TripDay, Long> {
    List<TripDay> findByTripIdOrderByDayNumber(Long tripId);
    Optional<TripDay> findByTripIdAndDayNumber(Long tripId, int dayNumber);

    @Modifying
    @Query("DELETE FROM TripDay t WHERE t.trip.id = :tripId")
    void deleteByTripId(@Param("tripId") Long tripId);
}
