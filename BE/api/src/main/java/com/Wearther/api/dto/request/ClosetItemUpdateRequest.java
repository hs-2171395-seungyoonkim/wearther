package com.Wearther.api.dto.request;

import com.Wearther.api.entity.Category;
import lombok.Getter;

@Getter
public class ClosetItemUpdateRequest {
    private String name;
    private String brand;
    private Category category;
    private String tags;
    private Integer suitableTempMin;
    private Integer suitableTempMax;
}
