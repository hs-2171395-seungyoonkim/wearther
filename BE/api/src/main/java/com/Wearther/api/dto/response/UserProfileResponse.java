package com.Wearther.api.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class UserProfileResponse {
    private Long id;
    private String name;
    private String email;
    private String defaultLocation;
    private String stylePreference;
    private String notificationTime;
    private Stats stats;

    @Getter
    @Builder
    public static class Stats {
        private long savedOutfits;
        private long tripCount;
        private long closetItemCount;
    }
}
