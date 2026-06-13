package com.Wearther.api.controller;

import com.Wearther.api.dto.response.ApiResponse;
import com.Wearther.api.dto.response.ClosetItemResponse;
import com.Wearther.api.dto.response.OutfitSuggestionResponse;
import com.Wearther.api.dto.response.TripDayResponse;
import com.Wearther.api.service.AiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
@Tag(name = "AI", description = "Gemini AI 분석/추천 API")
@SecurityRequirement(name = "bearerAuth")
public class AiController {

    private final AiService aiService;

    @PostMapping("/closet/items/{id}/analyze")
    @Operation(
        summary = "의류 AI 분석",
        description = "Gemini가 의류 아이템을 분석해 ai_notes(스타일 특징·코디 팁)를 저장합니다."
    )
    public ResponseEntity<ApiResponse<ClosetItemResponse>> analyzeItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(
                aiService.analyzeClosetItem(userDetails.getUsername(), id)));
    }

    @PostMapping("/trips/{id}/recommend")
    @Operation(
        summary = "여행 코디 AI 추천",
        description = "Gemini가 여행 각 일차의 날씨·옷장 데이터를 기반으로 outfit_recommendation을 생성합니다."
    )
    public ResponseEntity<ApiResponse<List<TripDayResponse>>> recommendTrip(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(
                aiService.recommendTripOutfits(userDetails.getUsername(), id)));
    }

    @PostMapping("/recommend-today")
    @Operation(
        summary = "오늘 코디 AI 추천",
        description = "현재 날씨와 보유 의류를 기반으로 오늘의 코디를 텍스트로 추천합니다."
    )
    public ResponseEntity<ApiResponse<String>> recommendToday(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Integer temperature,
            @RequestParam String condition) {
        return ResponseEntity.ok(ApiResponse.success(
                aiService.recommendToday(userDetails.getUsername(), temperature, condition)));
    }

    @PostMapping("/outfit-suggestions")
    @Operation(
        summary = "여행지 코디 3가지 추천",
        description = "현재 날씨를 기반으로 옷장 전체에서 코디 3가지를 추천합니다."
    )
    public ResponseEntity<ApiResponse<List<OutfitSuggestionResponse>>> suggestOutfitsForCity(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Integer temperature,
            @RequestParam String condition) {
        return ResponseEntity.ok(ApiResponse.success(
                aiService.suggestOutfitsForCity(userDetails.getUsername(), temperature, condition)));
    }

    @PostMapping("/closet/items/{id}/outfit-suggestions")
    @Operation(
        summary = "아이템 기반 코디 3가지 추천",
        description = "특정 옷장 아이템을 중심으로 오늘 날씨에 맞는 코디 3가지를 추천합니다."
    )
    public ResponseEntity<ApiResponse<List<OutfitSuggestionResponse>>> suggestOutfits(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestParam Integer temperature,
            @RequestParam String condition) {
        return ResponseEntity.ok(ApiResponse.success(
                aiService.suggestOutfitsForItem(userDetails.getUsername(), id, temperature, condition)));
    }
}
