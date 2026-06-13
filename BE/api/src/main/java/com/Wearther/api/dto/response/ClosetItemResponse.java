package com.Wearther.api.dto.response;

import com.Wearther.api.entity.Category;
import com.Wearther.api.entity.ClosetItem;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Getter
@Builder
public class ClosetItemResponse {
    private Long id;
    private String name;
    private String brand;
    private Category category;
    private List<String> tags;
    private String imageUrl;
    private int wearCount;
    private LocalDate lastWorn;
    private boolean favorite;
    private Integer suitableTempMin;
    private Integer suitableTempMax;
    private String aiNotes;
    private LocalDateTime createdAt;

    public static ClosetItemResponse from(ClosetItem item) {
        List<String> tagList = (item.getTags() != null && !item.getTags().isBlank())
                ? Arrays.asList(item.getTags().split(","))
                : Collections.emptyList();

        return ClosetItemResponse.builder()
                .id(item.getId())
                .name(item.getName())
                .brand(item.getBrand())
                .category(item.getCategory())
                .tags(tagList)
                .imageUrl(item.getImageUrl())
                .wearCount(item.getWearCount())
                .lastWorn(item.getLastWorn())
                .favorite(item.isFavorite())
                .suitableTempMin(item.getSuitableTempMin())
                .suitableTempMax(item.getSuitableTempMax())
                .aiNotes(item.getAiNotes())
                .createdAt(item.getCreatedAt())
                .build();
    }
}
