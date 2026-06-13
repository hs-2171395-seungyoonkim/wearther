package com.Wearther.api.service;

import com.Wearther.api.dto.request.WornLogRequest;
import com.Wearther.api.dto.response.WornLogResponse;
import com.Wearther.api.entity.ClosetItem;
import com.Wearther.api.entity.User;
import com.Wearther.api.entity.WornLog;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.ClosetItemRepository;
import com.Wearther.api.repository.UserRepository;
import com.Wearther.api.repository.WornLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WornLogService {

    private final WornLogRepository wornLogRepository;
    private final ClosetItemRepository closetItemRepository;
    private final UserRepository userRepository;

    @Transactional
    public WornLogResponse logWorn(String email, WornLogRequest request) {
        User user = findUser(email);
        LocalDate date = LocalDate.parse(request.getDate());

        WornLog log = wornLogRepository.findByUserIdAndDate(user.getId(), date)
                .orElse(WornLog.builder().user(user).date(date).build());

        String ids = request.getClosetItemIds().stream()
                .map(String::valueOf).collect(Collectors.joining(","));
        log.setClosetItemIds(ids);
        wornLogRepository.save(log);

        // Update lastWorn + wearCount for each item
        for (Long itemId : request.getClosetItemIds()) {
            closetItemRepository.findById(itemId).ifPresent(item -> {
                if (item.getUser().getId().equals(user.getId())) {
                    item.setLastWorn(date);
                    item.setWearCount(item.getWearCount() + 1);
                    closetItemRepository.save(item);
                }
            });
        }

        return buildResponse(log, request.getClosetItemIds());
    }

    @Transactional(readOnly = true)
    public List<WornLogResponse> getWornLogs(String email, int year, int month) {
        User user = findUser(email);
        LocalDate from = LocalDate.of(year, month, 1);
        LocalDate to = from.withDayOfMonth(from.lengthOfMonth());

        return wornLogRepository.findByUserIdAndDateBetweenOrderByDate(user.getId(), from, to)
                .stream()
                .map(log -> {
                    List<Long> ids = parseIds(log.getClosetItemIds());
                    return buildResponse(log, ids);
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public WornLogResponse getWornLogByDate(String email, String dateStr) {
        User user = findUser(email);
        LocalDate date = LocalDate.parse(dateStr);
        return wornLogRepository.findByUserIdAndDate(user.getId(), date)
                .map(log -> buildResponse(log, parseIds(log.getClosetItemIds())))
                .orElse(WornLogResponse.builder().date(dateStr).items(List.of()).build());
    }

    private WornLogResponse buildResponse(WornLog log, List<Long> ids) {
        List<ClosetItem> items = closetItemRepository.findAllById(ids);
        List<WornLogResponse.ItemSummary> summaries = items.stream()
                .map(i -> WornLogResponse.ItemSummary.builder()
                        .id(i.getId())
                        .name(i.getName())
                        .imageUrl(i.getImageUrl())
                        .category(i.getCategory() != null ? i.getCategory().name() : "")
                        .build())
                .collect(Collectors.toList());
        return WornLogResponse.builder().date(log.getDate().toString()).items(summaries).build();
    }

    private List<Long> parseIds(String idsStr) {
        if (idsStr == null || idsStr.isBlank()) return List.of();
        return Arrays.stream(idsStr.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Long::parseLong)
                .collect(Collectors.toList());
    }

    private User findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
