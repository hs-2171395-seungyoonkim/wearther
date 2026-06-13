package com.Wearther.api.repository;

import com.Wearther.api.entity.Outfit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface OutfitRepository extends JpaRepository<Outfit, Long> {
    List<Outfit> findByUserId(Long userId);
    long countByUserIdAndSaved(Long userId, boolean saved);
    long countByUserId(Long userId);

    @Modifying
    @Query(value = "DELETE FROM outfit_items WHERE closet_item_id = :itemId", nativeQuery = true)
    void deleteByClosetItemId(@Param("itemId") Long itemId);
}
