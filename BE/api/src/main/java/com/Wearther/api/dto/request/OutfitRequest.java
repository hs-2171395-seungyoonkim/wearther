package com.Wearther.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

import java.util.List;

@Getter
public class OutfitRequest {

    @NotBlank(message = "설명은 필수입니다.")
    private String description;

    private String weatherCondition;
    private Integer tempMin;
    private Integer tempMax;
    private List<Long> closetItemIds;
}
