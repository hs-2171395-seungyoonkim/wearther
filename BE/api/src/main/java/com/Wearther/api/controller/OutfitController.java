package com.Wearther.api.controller;

import com.Wearther.api.dto.request.OutfitRequest;
import com.Wearther.api.dto.response.ApiResponse;
import com.Wearther.api.dto.response.OutfitResponse;
import com.Wearther.api.service.OutfitService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/outfits")
@RequiredArgsConstructor
@Tag(name = "Outfits", description = "코디 API")
@SecurityRequirement(name = "bearerAuth")
public class OutfitController {

    private final OutfitService outfitService;

    @GetMapping
    @Operation(summary = "내 코디 목록 조회")
    public ResponseEntity<ApiResponse<List<OutfitResponse>>> getOutfits(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.success(outfitService.getOutfits(userDetails.getUsername())));
    }

    @PostMapping
    @Operation(summary = "코디 생성")
    public ResponseEntity<ApiResponse<OutfitResponse>> createOutfit(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody @Valid OutfitRequest request) {
        return ResponseEntity.ok(ApiResponse.success(outfitService.createOutfit(userDetails.getUsername(), request)));
    }

    @GetMapping("/{id}")
    @Operation(summary = "코디 단건 조회")
    public ResponseEntity<ApiResponse<OutfitResponse>> getOutfit(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(outfitService.getOutfit(userDetails.getUsername(), id)));
    }

    @PatchMapping("/{id}/bookmark")
    @Operation(summary = "북마크 토글")
    public ResponseEntity<ApiResponse<OutfitResponse>> toggleBookmark(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(outfitService.toggleBookmark(userDetails.getUsername(), id)));
    }

    @PatchMapping("/{id}/save")
    @Operation(summary = "코디 저장")
    public ResponseEntity<ApiResponse<OutfitResponse>> saveOutfit(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(outfitService.saveOutfit(userDetails.getUsername(), id)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "코디 삭제")
    public ResponseEntity<ApiResponse<Void>> deleteOutfit(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        outfitService.deleteOutfit(userDetails.getUsername(), id);
        return ResponseEntity.ok(ApiResponse.success());
    }
}
