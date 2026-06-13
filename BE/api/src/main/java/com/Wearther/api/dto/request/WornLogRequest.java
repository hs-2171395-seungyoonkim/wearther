package com.Wearther.api.dto.request;

import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@NoArgsConstructor
public class WornLogRequest {
    private String date;
    private List<Long> closetItemIds;
}
