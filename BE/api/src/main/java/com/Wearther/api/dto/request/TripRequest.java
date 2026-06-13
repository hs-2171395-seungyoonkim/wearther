package com.Wearther.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
public class TripRequest {

    @NotBlank(message = "목적지는 필수입니다.")
    private String destination;

    @NotNull(message = "출발일은 필수입니다.")
    private LocalDate startDate;

    @NotNull(message = "종료일은 필수입니다.")
    private LocalDate endDate;

    private String travelStyle;
    private List<String> activities;
}
