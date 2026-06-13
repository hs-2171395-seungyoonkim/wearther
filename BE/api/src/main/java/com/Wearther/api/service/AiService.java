package com.Wearther.api.service;

import com.Wearther.api.dto.response.ClosetItemResponse;
import com.Wearther.api.dto.response.OutfitSuggestionResponse;
import com.Wearther.api.dto.response.TripDayResponse;
import com.Wearther.api.entity.ClosetItem;
import com.Wearther.api.entity.Trip;
import com.Wearther.api.entity.TripDay;
import com.Wearther.api.entity.User;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.ClosetItemRepository;
import com.Wearther.api.repository.TripDayRepository;
import com.Wearther.api.repository.TripRepository;
import com.Wearther.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiService {

    private final GeminiService geminiService;
    private final ClosetItemRepository closetItemRepository;
    private final TripRepository tripRepository;
    private final TripDayRepository tripDayRepository;
    private final UserRepository userRepository;

    @Transactional
    public ClosetItemResponse analyzeClosetItem(String email, Long itemId) {
        User user = findUserByEmail(email);
        ClosetItem item = closetItemRepository.findById(itemId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "아이템을 찾을 수 없습니다."));
        if (!item.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }

        String prompt = buildItemAnalysisPrompt(item);
        String aiNotes = geminiService.generate(prompt);
        item.setAiNotes(aiNotes);
        closetItemRepository.save(item);

        return ClosetItemResponse.from(item);
    }

    @Transactional
    public List<TripDayResponse> recommendTripOutfits(String email, Long tripId) {
        User user = findUserByEmail(email);
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "여행을 찾을 수 없습니다."));
        if (!trip.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }

        List<ClosetItem> closetItems = closetItemRepository.findByUserId(user.getId());
        List<TripDay> days = tripDayRepository.findByTripIdOrderByDayNumber(tripId);

        for (TripDay day : days) {
            String prompt = buildTripDayPrompt(trip, day, closetItems);
            String recommendation = geminiService.generate(prompt);
            day.setOutfitRecommendation(recommendation);
            tripDayRepository.save(day);
        }

        return days.stream().map(TripDayResponse::from).collect(Collectors.toList());
    }

    private String buildItemAnalysisPrompt(ClosetItem item) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 패션 전문가입니다. 다음 의류 아이템을 분석해주세요.\n\n");
        sb.append("아이템 정보:\n");
        sb.append("- 이름: ").append(item.getName()).append("\n");
        if (item.getBrand() != null) sb.append("- 브랜드: ").append(item.getBrand()).append("\n");
        sb.append("- 카테고리: ").append(item.getCategory()).append("\n");
        if (item.getSuitableTempMin() != null && item.getSuitableTempMax() != null) {
            sb.append("- 적합 온도: ").append(item.getSuitableTempMin())
              .append("~").append(item.getSuitableTempMax()).append("도\n");
        }
        if (item.getTags() != null) sb.append("- 태그: ").append(item.getTags()).append("\n");
        sb.append("\n이 아이템의 스타일 특징, 어울리는 코디 방법, 적합한 상황을 2~3문장으로 간결하게 한국어로 설명해주세요.");
        return sb.toString();
    }

    private String buildTripDayPrompt(Trip trip, TripDay day, List<ClosetItem> closetItems) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 여행 코디 전문가입니다. 다음 조건에 맞는 코디를 추천해주세요.\n\n");
        sb.append("여행 정보:\n");
        sb.append("- 목적지: ").append(trip.getDestination()).append("\n");
        if (trip.getTravelStyle() != null) sb.append("- 여행 스타일: ").append(trip.getTravelStyle()).append("\n");
        sb.append("- ").append(day.getDayNumber()).append("일차 (").append(day.getDate()).append(")\n");

        if (day.getTemperature() != null) {
            sb.append("- 날씨: ");
            if (day.getWeatherCondition() != null) sb.append(day.getWeatherCondition()).append(", ");
            sb.append("기온 ").append(day.getTemperature()).append("도");
            if (day.getFeelsLike() != null) sb.append(" (체감 ").append(day.getFeelsLike()).append("도)");
            if (day.getRainChance() != null) sb.append(", 강수확률 ").append(day.getRainChance()).append("%");
            sb.append("\n");
        } else {
            sb.append("- 날씨: 실측 데이터 없음. ")
              .append(trip.getDestination()).append(" ").append(day.getDate())
              .append(" 의 계절·기후를 직접 추정하여 코디를 추천해주세요.\n");
        }

        if (!closetItems.isEmpty()) {
            sb.append("\n보유 의류 목록:\n");
            closetItems.forEach(item -> {
                sb.append("- [").append(item.getCategory()).append("] ").append(item.getName());
                if (item.getBrand() != null) sb.append(" (").append(item.getBrand()).append(")");
                if (item.getSuitableTempMin() != null && item.getSuitableTempMax() != null) {
                    sb.append(" | 적합온도: ").append(item.getSuitableTempMin())
                      .append("~").append(item.getSuitableTempMax()).append("도");
                }
                sb.append("\n");
            });
        }

        sb.append("\n위 조건에 맞는 상의, 하의, 아우터, 신발 코디를 추천하고, 이유를 간략히 설명해주세요. 한국어로 답해주세요.");
        return sb.toString();
    }

    @Transactional(readOnly = true)
    public String recommendToday(String email, Integer temperature, String condition) {
        User user = findUserByEmail(email);
        List<ClosetItem> closetItems = closetItemRepository.findByUserId(user.getId());
        String prompt = buildTodayPrompt(temperature, condition, closetItems);
        return geminiService.generate(prompt);
    }

    private String buildTodayPrompt(Integer temperature, String condition, List<ClosetItem> items) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 패션 전문가입니다. 오늘 날씨에 맞는 코디를 추천해주세요.\n\n");
        sb.append("오늘 날씨:\n");
        sb.append("- 기온: ").append(temperature).append("°C\n");
        sb.append("- 날씨: ").append(condition).append("\n\n");

        if (!items.isEmpty()) {
            sb.append("보유 의류 목록:\n");
            items.forEach(item -> {
                sb.append("- [").append(item.getCategory()).append("] ").append(item.getName());
                if (item.getBrand() != null) sb.append(" (").append(item.getBrand()).append(")");
                if (item.getSuitableTempMin() != null && item.getSuitableTempMax() != null) {
                    sb.append(" | 적합온도: ").append(item.getSuitableTempMin())
                      .append("~").append(item.getSuitableTempMax()).append("도");
                }
                sb.append("\n");
            });
            sb.append("\n위 의류 중에서 오늘 날씨에 가장 잘 어울리는 코디를 '아이템1 + 아이템2 + 아이템3' 형식으로 한 줄 추천하고, 한 문장으로 이유를 설명해주세요. 한국어로 답해주세요.");
        } else {
            sb.append("기온 ").append(temperature).append("°C, ").append(condition)
              .append(" 날씨에 어울리는 코디를 '상의 + 하의 + 아우터' 형식으로 한 줄 추천하고, 한 문장으로 이유를 설명해주세요. 한국어로 답해주세요.");
        }
        return sb.toString();
    }

    @Transactional(readOnly = true)
    public List<OutfitSuggestionResponse> suggestOutfitsForCity(String email, Integer temperature, String condition) {
        User user = findUserByEmail(email);
        List<ClosetItem> allItems = closetItemRepository.findByUserId(user.getId());
        String prompt = buildCityOutfitPrompt(allItems, temperature, condition);
        String response = geminiService.generate(prompt);
        List<OutfitSuggestionResponse> suggestions = parseOutfitSuggestions(response, allItems);
        if (suggestions.isEmpty()) {
            suggestions = createCityFallbackSuggestions(allItems);
        }
        return suggestions;
    }

    private String buildCityOutfitPrompt(List<ClosetItem> allItems, Integer temperature, String condition) {
        Map<String, List<ClosetItem>> byCategory = allItems.stream()
                .collect(Collectors.groupingBy(item -> item.getCategory().name()));

        boolean needsOuterwear = temperature != null && temperature <= 15;

        StringBuilder sb = new StringBuilder();
        sb.append("당신은 패션 스타일리스트입니다. 오늘 날씨에 맞는 완성된 코디 3가지를 추천해주세요.\n\n");
        sb.append("오늘 날씨: 기온 ").append(temperature).append("°C, ").append(condition).append("\n\n");

        String[] cats     = {"TOP",      "BOTTOM",   "OUTERWEAR",    "SHOES"};
        String[] catNames = {"상의(TOP)", "하의(BOTTOM)", "아우터(OUTERWEAR)", "신발(SHOES)"};
        for (int ci = 0; ci < cats.length; ci++) {
            List<ClosetItem> catItems = byCategory.getOrDefault(cats[ci], new ArrayList<>());
            if (!catItems.isEmpty()) {
                sb.append("[").append(catNames[ci]).append("]\n");
                catItems.forEach(item -> {
                    sb.append("  ID:").append(item.getId()).append(" ").append(item.getName());
                    if (item.getSuitableTempMin() != null && item.getSuitableTempMax() != null) {
                        sb.append(" (적합온도 ").append(item.getSuitableTempMin())
                          .append("~").append(item.getSuitableTempMax()).append("°C)");
                    }
                    sb.append("\n");
                });
            }
        }

        sb.append("\n[출력 규칙 - 아래 형식 외 다른 텍스트는 절대 출력하지 마세요]\n");
        sb.append("OUTFIT1:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n");
        sb.append("OUTFIT2:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n");
        sb.append("OUTFIT3:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n\n");
        sb.append("[필수 조건]\n");
        sb.append("1. 각 코디에 상의(TOP) 1개, 하의(BOTTOM) 1개, 신발(SHOES) 1개를 반드시 포함하세요.\n");
        if (needsOuterwear) {
            sb.append("2. 기온이 낮으므로 아우터(OUTERWEAR) 1개를 반드시 포함하세요.\n");
        }
        sb.append("3. 3개의 코디는 서로 다른 조합으로 구성하세요.\n");
        sb.append("4. 같은 카테고리 아이템을 2개 이상 넣지 마세요.\n");
        sb.append("5. ID는 위 목록에 있는 숫자만 사용하세요.\n");
        sb.append("6. 코디 설명은 날씨에 맞는 이유와 스타일 포인트를 포함해 2~3문장 한국어로 작성하세요. '|' 문자는 사용하지 마세요.");
        return sb.toString();
    }

    private List<OutfitSuggestionResponse> createCityFallbackSuggestions(List<ClosetItem> allItems) {
        Map<String, List<ClosetItem>> byCategory = allItems.stream()
                .collect(Collectors.groupingBy(item -> item.getCategory().name()));

        List<ClosetItem> tops    = byCategory.getOrDefault("TOP",       new ArrayList<>());
        List<ClosetItem> bottoms = byCategory.getOrDefault("BOTTOM",    new ArrayList<>());
        List<ClosetItem> outers  = byCategory.getOrDefault("OUTERWEAR", new ArrayList<>());
        List<ClosetItem> shoes   = byCategory.getOrDefault("SHOES",     new ArrayList<>());
        List<String> catOrder = List.of("TOP", "BOTTOM", "OUTERWEAR", "SHOES");

        String[] descriptions = {"베이직 데일리 코디", "캐주얼 편안한 코디", "세련된 레이어드 코디"};
        List<OutfitSuggestionResponse> suggestions = new ArrayList<>();

        for (int i = 0; i < 3; i++) {
            Map<String, OutfitSuggestionResponse.ItemSummary> byCat = new java.util.LinkedHashMap<>();
            if (!tops.isEmpty())    byCat.put("TOP",       toSummary(tops.get(i % tops.size())));
            if (!bottoms.isEmpty()) byCat.put("BOTTOM",    toSummary(bottoms.get(i % bottoms.size())));
            if (!outers.isEmpty())  byCat.put("OUTERWEAR", toSummary(outers.get(i % outers.size())));
            if (!shoes.isEmpty())   byCat.put("SHOES",     toSummary(shoes.get(i % shoes.size())));

            List<OutfitSuggestionResponse.ItemSummary> items = catOrder.stream()
                    .filter(byCat::containsKey).map(byCat::get).collect(Collectors.toList());

            suggestions.add(OutfitSuggestionResponse.builder()
                    .description(descriptions[i]).items(items).build());
        }
        return suggestions;
    }

    @Transactional(readOnly = true)
    public List<OutfitSuggestionResponse> suggestOutfitsForItem(String email, Long itemId, Integer temperature, String condition) {
        User user = findUserByEmail(email);
        ClosetItem targetItem = closetItemRepository.findById(itemId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "아이템을 찾을 수 없습니다."));
        if (!targetItem.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }

        List<ClosetItem> allItems = closetItemRepository.findByUserId(user.getId());
        String prompt = buildOutfitSuggestionPrompt(targetItem, allItems, temperature, condition);
        String response = geminiService.generate(prompt);

        List<OutfitSuggestionResponse> suggestions = parseOutfitSuggestions(response, allItems);
        if (suggestions.isEmpty()) {
            suggestions = createFallbackSuggestions(targetItem, allItems);
        }
        return suggestions;
    }

    private String buildOutfitSuggestionPrompt(ClosetItem targetItem, List<ClosetItem> allItems, Integer temperature, String condition) {
        Map<String, List<ClosetItem>> byCategory = allItems.stream()
                .collect(Collectors.groupingBy(item -> item.getCategory().name()));

        boolean needsOuterwear = temperature != null && temperature <= 15;

        StringBuilder sb = new StringBuilder();
        sb.append("당신은 패션 스타일리스트입니다. 아래 기준 아이템을 포함해 오늘 날씨에 맞는 완성된 코디 3가지를 추천해주세요.\n\n");
        sb.append("기준 아이템: [").append(targetItem.getCategory()).append("] ID:").append(targetItem.getId()).append(" ").append(targetItem.getName()).append("\n");
        sb.append("오늘 날씨: 기온 ").append(temperature).append("°C, ").append(condition).append("\n\n");

        String[] cats     = {"TOP",      "BOTTOM",   "OUTERWEAR",    "SHOES"};
        String[] catNames = {"상의(TOP)", "하의(BOTTOM)", "아우터(OUTERWEAR)", "신발(SHOES)"};
        for (int ci = 0; ci < cats.length; ci++) {
            List<ClosetItem> catItems = byCategory.getOrDefault(cats[ci], new ArrayList<>());
            if (!catItems.isEmpty()) {
                sb.append("[").append(catNames[ci]).append("]\n");
                catItems.forEach(item -> {
                    sb.append("  ID:").append(item.getId()).append(" ").append(item.getName());
                    if (item.getSuitableTempMin() != null && item.getSuitableTempMax() != null) {
                        sb.append(" (적합온도 ").append(item.getSuitableTempMin())
                          .append("~").append(item.getSuitableTempMax()).append("°C)");
                    }
                    sb.append("\n");
                });
            }
        }

        sb.append("\n[출력 규칙 - 아래 형식 외 다른 텍스트는 절대 출력하지 마세요]\n");
        sb.append("OUTFIT1:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n");
        sb.append("OUTFIT2:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n");
        sb.append("OUTFIT3:TOP의ID,BOTTOM의ID,").append(needsOuterwear ? "OUTERWEAR의ID," : "").append("SHOES의ID|코디설명\n\n");
        sb.append("[필수 조건]\n");
        sb.append("1. 기준 아이템(ID:").append(targetItem.getId()).append(")을 3개 코디 모두에 포함하세요.\n");
        sb.append("2. 각 코디에 상의(TOP) 1개, 하의(BOTTOM) 1개, 신발(SHOES) 1개를 반드시 포함하세요.\n");
        if (needsOuterwear) {
            sb.append("3. 기온이 낮으므로 아우터(OUTERWEAR) 1개를 반드시 포함하세요.\n");
        }
        sb.append("4. 같은 카테고리 아이템을 2개 이상 넣지 마세요.\n");
        sb.append("5. ID는 위 목록에 있는 숫자만 사용하세요.\n");
        sb.append("6. 코디 설명은 날씨에 맞는 이유와 스타일 포인트를 포함해 2~3문장 한국어로 작성하세요. '|' 문자는 사용하지 마세요.");
        return sb.toString();
    }

    private List<OutfitSuggestionResponse> parseOutfitSuggestions(String response, List<ClosetItem> allItems) {
        Map<Long, ClosetItem> itemMap = allItems.stream()
                .collect(Collectors.toMap(ClosetItem::getId, i -> i));

        List<OutfitSuggestionResponse> suggestions = new ArrayList<>();
        List<String> catOrder = List.of("TOP", "BOTTOM", "OUTERWEAR", "SHOES");

        // Normalize: join continuation lines that don't start with OUTFIT back to previous
        StringBuilder normalized = new StringBuilder();
        for (String line : response.split("\n")) {
            if (line.startsWith("OUTFIT")) {
                if (normalized.length() > 0) normalized.append("\n");
                normalized.append(line.trim());
            } else if (normalized.length() > 0) {
                normalized.append(" ").append(line.trim());
            }
        }

        for (String line : normalized.toString().split("\n")) {
            if (!line.startsWith("OUTFIT")) continue;
            int colonIdx = line.indexOf(':');
            int pipeIdx = line.indexOf('|');
            if (colonIdx < 0 || pipeIdx < 0 || pipeIdx <= colonIdx) continue;

            String idsStr = line.substring(colonIdx + 1, pipeIdx).trim();
            String description = line.substring(pipeIdx + 1).trim();

            // Deduplicate by category: keep first item per category
            Map<String, OutfitSuggestionResponse.ItemSummary> byCat = new java.util.LinkedHashMap<>();
            for (String idStr : idsStr.split(",")) {
                try {
                    Long id = Long.parseLong(idStr.trim());
                    ClosetItem item = itemMap.get(id);
                    if (item != null && !byCat.containsKey(item.getCategory().name())) {
                        byCat.put(item.getCategory().name(), toSummary(item));
                    }
                } catch (NumberFormatException ignored) {}
            }

            // Sort by category order
            List<OutfitSuggestionResponse.ItemSummary> items = catOrder.stream()
                    .filter(byCat::containsKey)
                    .map(byCat::get)
                    .collect(Collectors.toList());

            if (!items.isEmpty()) {
                suggestions.add(OutfitSuggestionResponse.builder()
                        .description(description)
                        .items(items)
                        .build());
            }
        }

        return suggestions;
    }

    private List<OutfitSuggestionResponse> createFallbackSuggestions(ClosetItem targetItem, List<ClosetItem> allItems) {
        Map<String, List<ClosetItem>> byCategory = allItems.stream()
                .collect(Collectors.groupingBy(item -> item.getCategory().name()));

        List<ClosetItem> tops    = byCategory.getOrDefault("TOP",       new ArrayList<>());
        List<ClosetItem> bottoms = byCategory.getOrDefault("BOTTOM",    new ArrayList<>());
        List<ClosetItem> outers  = byCategory.getOrDefault("OUTERWEAR", new ArrayList<>());
        List<ClosetItem> shoes   = byCategory.getOrDefault("SHOES",     new ArrayList<>());
        String targetCat = targetItem.getCategory().name();

        // Remove target item from its category list to avoid duplication
        tops.removeIf(i -> i.getId().equals(targetItem.getId()));
        bottoms.removeIf(i -> i.getId().equals(targetItem.getId()));
        outers.removeIf(i -> i.getId().equals(targetItem.getId()));
        shoes.removeIf(i -> i.getId().equals(targetItem.getId()));

        List<String> catOrder = List.of("TOP", "BOTTOM", "OUTERWEAR", "SHOES");
        String[] descriptions = {"베이직 데일리 코디", "캐주얼 편안한 코디", "세련된 레이어드 코디"};
        List<OutfitSuggestionResponse> suggestions = new ArrayList<>();

        for (int i = 0; i < 3; i++) {
            Map<String, OutfitSuggestionResponse.ItemSummary> byCat = new java.util.LinkedHashMap<>();
            byCat.put(targetCat, toSummary(targetItem));

            if (!targetCat.equals("TOP")       && !tops.isEmpty())
                byCat.put("TOP",       toSummary(tops.get(i % tops.size())));
            if (!targetCat.equals("BOTTOM")    && !bottoms.isEmpty())
                byCat.put("BOTTOM",    toSummary(bottoms.get(i % bottoms.size())));
            if (!targetCat.equals("OUTERWEAR") && !outers.isEmpty())
                byCat.put("OUTERWEAR", toSummary(outers.get(i % outers.size())));
            if (!targetCat.equals("SHOES")     && !shoes.isEmpty())
                byCat.put("SHOES",     toSummary(shoes.get(i % shoes.size())));

            List<OutfitSuggestionResponse.ItemSummary> items = catOrder.stream()
                    .filter(byCat::containsKey)
                    .map(byCat::get)
                    .collect(Collectors.toList());

            suggestions.add(OutfitSuggestionResponse.builder()
                    .description(descriptions[i])
                    .items(items)
                    .build());
        }
        return suggestions;
    }

    private OutfitSuggestionResponse.ItemSummary toSummary(ClosetItem item) {
        return OutfitSuggestionResponse.ItemSummary.builder()
                .id(item.getId())
                .name(item.getName())
                .imageUrl(item.getImageUrl())
                .category(item.getCategory().name())
                .build();
    }

    @Transactional
    public void recommendTripOutfitsInternal(String email, Long tripId) {
        try {
            recommendTripOutfits(email, tripId);
        } catch (Exception e) {
            log.warn("AI 코디 추천 실패: tripId={}", tripId, e);
        }
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
