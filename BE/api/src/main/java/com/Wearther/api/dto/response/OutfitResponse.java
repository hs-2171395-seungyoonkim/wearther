package com.Wearther.api.dto.response;

import com.Wearther.api.entity.Outfit;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Builder
public class OutfitResponse {
    private Long id;
    private String description;
    private String weatherCondition;
    private Integer temperatureMin;
    private Integer temperatureMax;
    private Integer compatibilityScore;
    private boolean saved;
    private boolean bookmarked;
    private LocalDateTime createdAt;
    private List<ClosetItemResponse> items;

    public static OutfitResponse from(Outfit outfit) {
        return OutfitResponse.builder()
                .id(outfit.getId())
                .description(outfit.getDescription())
                .weatherCondition(outfit.getWeatherCondition())
                .temperatureMin(outfit.getTemperatureMin())
                .temperatureMax(outfit.getTemperatureMax())
                .compatibilityScore(outfit.getCompatibilityScore())
                .saved(outfit.isSaved())
                .bookmarked(outfit.isBookmarked())
                .createdAt(outfit.getCreatedAt())
                .items(outfit.getItems().stream().map(ClosetItemResponse::from).collect(Collectors.toList()))
                .build();
    }
}
