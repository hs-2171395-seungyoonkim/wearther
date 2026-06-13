package com.Wearther.api.dto.response;

import com.Wearther.api.entity.TripDay;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;

@Getter
@Builder
public class TripDayResponse {
    private Long id;
    private Long tripId;
    private int dayNumber;
    private LocalDate date;
    private String locationName;
    private Double temperature;
    private String weatherCondition;
    private Double feelsLike;
    private Integer rainChance;
    private String outfitRecommendation;
    private String weatherNotes;

    public static TripDayResponse from(TripDay day) {
        return TripDayResponse.builder()
                .id(day.getId())
                .tripId(day.getTrip().getId())
                .dayNumber(day.getDayNumber())
                .date(day.getDate())
                .locationName(day.getLocationName())
                .temperature(day.getTemperature())
                .weatherCondition(day.getWeatherCondition())
                .feelsLike(day.getFeelsLike())
                .rainChance(day.getRainChance())
                .outfitRecommendation(day.getOutfitRecommendation())
                .weatherNotes(day.getWeatherNotes())
                .build();
    }
}
