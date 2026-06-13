package com.Wearther.api.service;

import com.Wearther.api.dto.request.UpdateProfileRequest;
import com.Wearther.api.dto.response.UserProfileResponse;
import com.Wearther.api.entity.User;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.ClosetItemRepository;
import com.Wearther.api.repository.OutfitRepository;
import com.Wearther.api.repository.TripRepository;
import com.Wearther.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final ClosetItemRepository closetItemRepository;
    private final TripRepository tripRepository;
    private final OutfitRepository outfitRepository;

    @Transactional(readOnly = true)
    public UserProfileResponse getProfile(String email) {
        User user = findByEmail(email);
        return buildProfile(user);
    }

    @Transactional
    public UserProfileResponse updateProfile(String email, UpdateProfileRequest request) {
        User user = findByEmail(email);
        if (request.getName() != null) user.setName(request.getName());
        if (request.getDefaultLocation() != null) user.setDefaultLocation(request.getDefaultLocation());
        if (request.getStylePreference() != null) user.setStylePreference(request.getStylePreference());
        if (request.getNotificationTime() != null) user.setNotificationTime(request.getNotificationTime());
        userRepository.save(user);
        return buildProfile(user);
    }

    private UserProfileResponse buildProfile(User user) {
        return UserProfileResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .defaultLocation(user.getDefaultLocation())
                .stylePreference(user.getStylePreference())
                .notificationTime(user.getNotificationTime())
                .stats(UserProfileResponse.Stats.builder()
                        .savedOutfits(outfitRepository.countByUserId(user.getId()))
                        .tripCount(tripRepository.countByUserId(user.getId()))
                        .closetItemCount(closetItemRepository.countByUserId(user.getId()))
                        .build())
                .build();
    }

    private User findByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
