package com.Wearther.api.dto.request;

import lombok.Getter;

@Getter
public class UpdateProfileRequest {
    private String name;
    private String defaultLocation;
    private String stylePreference;
    private String notificationTime;
}
