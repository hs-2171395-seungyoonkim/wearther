package com.Wearther.api.dto.response;

import com.Wearther.api.entity.Trip;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Getter
@Builder
public class TripResponse {
    private Long id;
    private String destination;
    private LocalDate startDate;
    private LocalDate endDate;
    private String travelStyle;
    private List<String> activities;
    private String packingList;
    private LocalDateTime createdAt;

    public static TripResponse from(Trip trip) {
        List<String> actList = (trip.getActivities() != null && !trip.getActivities().isBlank())
                ? Arrays.asList(trip.getActivities().split(","))
                : Collections.emptyList();

        return TripResponse.builder()
                .id(trip.getId())
                .destination(trip.getDestination())
                .startDate(trip.getStartDate())
                .endDate(trip.getEndDate())
                .travelStyle(trip.getTravelStyle())
                .activities(actList)
                .packingList(trip.getPackingList())
                .createdAt(trip.getCreatedAt())
                .build();
    }
}
