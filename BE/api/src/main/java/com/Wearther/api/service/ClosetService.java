package com.Wearther.api.service;

import com.Wearther.api.dto.request.ClosetItemUpdateRequest;
import com.Wearther.api.dto.response.ClosetItemResponse;
import com.Wearther.api.entity.Category;
import com.Wearther.api.entity.ClosetItem;
import com.Wearther.api.entity.User;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.ClosetItemRepository;
import com.Wearther.api.repository.OutfitRepository;
import com.Wearther.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ClosetService {

    private final ClosetItemRepository closetItemRepository;
    private final OutfitRepository outfitRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    @Transactional(readOnly = true)
    public List<ClosetItemResponse> getItems(String email, Category category) {
        User user = findUserByEmail(email);
        List<ClosetItem> items = (category != null)
                ? closetItemRepository.findByUserIdAndCategory(user.getId(), category)
                : closetItemRepository.findByUserId(user.getId());
        return items.stream().map(ClosetItemResponse::from).collect(Collectors.toList());
    }

    @Transactional
    public ClosetItemResponse createItem(String email, String name, String brand, Category category,
                                          String tags, Integer suitableTempMin, Integer suitableTempMax,
                                          MultipartFile image) {
        User user = findUserByEmail(email);
        String imageUrl = (image != null && !image.isEmpty()) ? fileStorageService.store(image) : null;

        ClosetItem item = ClosetItem.builder()
                .user(user)
                .name(name)
                .brand(brand)
                .category(category)
                .tags(tags)
                .imageUrl(imageUrl)
                .suitableTempMin(suitableTempMin)
                .suitableTempMax(suitableTempMax)
                .build();

        return ClosetItemResponse.from(closetItemRepository.save(item));
    }

    @Transactional(readOnly = true)
    public ClosetItemResponse getItem(String email, Long id) {
        return ClosetItemResponse.from(findItemByOwner(id, email));
    }

    @Transactional
    public ClosetItemResponse updateItem(String email, Long id, ClosetItemUpdateRequest request) {
        ClosetItem item = findItemByOwner(id, email);
        if (request.getName() != null) item.setName(request.getName());
        if (request.getBrand() != null) item.setBrand(request.getBrand());
        if (request.getCategory() != null) item.setCategory(request.getCategory());
        if (request.getTags() != null) item.setTags(request.getTags());
        if (request.getSuitableTempMin() != null) item.setSuitableTempMin(request.getSuitableTempMin());
        if (request.getSuitableTempMax() != null) item.setSuitableTempMax(request.getSuitableTempMax());
        return ClosetItemResponse.from(closetItemRepository.save(item));
    }

    @Transactional
    public ClosetItemResponse updateItemImage(String email, Long id, MultipartFile image) {
        ClosetItem item = findItemByOwner(id, email);
        fileStorageService.delete(item.getImageUrl());
        item.setImageUrl(fileStorageService.store(image));
        return ClosetItemResponse.from(closetItemRepository.save(item));
    }

    @Transactional
    public void deleteItem(String email, Long id) {
        ClosetItem item = findItemByOwner(id, email);
        outfitRepository.deleteByClosetItemId(id); // outfit_items FK 선 제거
        fileStorageService.delete(item.getImageUrl());
        closetItemRepository.delete(item);
    }

    @Transactional
    public ClosetItemResponse wearItem(String email, Long id) {
        ClosetItem item = findItemByOwner(id, email);
        item.setWearCount(item.getWearCount() + 1);
        item.setLastWorn(LocalDate.now());
        return ClosetItemResponse.from(closetItemRepository.save(item));
    }

    @Transactional
    public ClosetItemResponse toggleFavorite(String email, Long id) {
        ClosetItem item = findItemByOwner(id, email);
        item.setFavorite(!item.isFavorite());
        return ClosetItemResponse.from(closetItemRepository.save(item));
    }

    private ClosetItem findItemByOwner(Long itemId, String email) {
        User user = findUserByEmail(email);
        ClosetItem item = closetItemRepository.findById(itemId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "아이템을 찾을 수 없습니다."));
        if (!item.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }
        return item;
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
