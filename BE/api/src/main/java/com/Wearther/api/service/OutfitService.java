package com.Wearther.api.service;

import com.Wearther.api.dto.request.OutfitRequest;
import com.Wearther.api.dto.response.OutfitResponse;
import com.Wearther.api.entity.ClosetItem;
import com.Wearther.api.entity.Outfit;
import com.Wearther.api.entity.User;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.ClosetItemRepository;
import com.Wearther.api.repository.OutfitRepository;
import com.Wearther.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OutfitService {

    private final OutfitRepository outfitRepository;
    private final ClosetItemRepository closetItemRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<OutfitResponse> getOutfits(String email) {
        User user = findUserByEmail(email);
        return outfitRepository.findByUserId(user.getId())
                .stream().map(OutfitResponse::from).collect(Collectors.toList());
    }

    @Transactional
    public OutfitResponse createOutfit(String email, OutfitRequest request) {
        User user = findUserByEmail(email);

        List<ClosetItem> items = new ArrayList<>();
        if (request.getClosetItemIds() != null) {
            for (Long itemId : request.getClosetItemIds()) {
                ClosetItem item = closetItemRepository.findById(itemId)
                        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                                "아이템을 찾을 수 없습니다: " + itemId));
                if (!item.getUser().getId().equals(user.getId())) {
                    throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
                }
                items.add(item);
            }
        }

        Outfit outfit = Outfit.builder()
                .user(user)
                .description(request.getDescription())
                .weatherCondition(request.getWeatherCondition())
                .temperatureMin(request.getTempMin())
                .temperatureMax(request.getTempMax())
                .items(items)
                .build();

        return OutfitResponse.from(outfitRepository.save(outfit));
    }

    @Transactional(readOnly = true)
    public OutfitResponse getOutfit(String email, Long outfitId) {
        return OutfitResponse.from(findOutfitByOwner(outfitId, email));
    }

    @Transactional
    public OutfitResponse toggleBookmark(String email, Long outfitId) {
        Outfit outfit = findOutfitByOwner(outfitId, email);
        outfit.setBookmarked(!outfit.isBookmarked());
        return OutfitResponse.from(outfitRepository.save(outfit));
    }

    @Transactional
    public OutfitResponse saveOutfit(String email, Long outfitId) {
        Outfit outfit = findOutfitByOwner(outfitId, email);
        outfit.setSaved(true);
        return OutfitResponse.from(outfitRepository.save(outfit));
    }

    @Transactional
    public void deleteOutfit(String email, Long outfitId) {
        Outfit outfit = findOutfitByOwner(outfitId, email);
        outfitRepository.delete(outfit);
    }

    private Outfit findOutfitByOwner(Long outfitId, String email) {
        User user = findUserByEmail(email);
        Outfit outfit = outfitRepository.findById(outfitId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "코디를 찾을 수 없습니다."));
        if (!outfit.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }
        return outfit;
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
