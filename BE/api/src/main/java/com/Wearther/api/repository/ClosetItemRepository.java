package com.Wearther.api.repository;

import com.Wearther.api.entity.Category;
import com.Wearther.api.entity.ClosetItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClosetItemRepository extends JpaRepository<ClosetItem, Long> {
    List<ClosetItem> findByUserId(Long userId);
    List<ClosetItem> findByUserIdAndCategory(Long userId, Category category);
    long countByUserId(Long userId);
}
