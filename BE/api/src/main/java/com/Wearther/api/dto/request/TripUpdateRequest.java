package com.Wearther.api.dto.request;

import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
public class TripUpdateRequest {
    private String destination;
    private LocalDate startDate;
    private LocalDate endDate;
    private String travelStyle;
    private List<String> activities;
    private String packingList;
}
