package com.Wearther.api.controller;

import com.Wearther.api.dto.request.ClosetItemUpdateRequest;
import com.Wearther.api.dto.response.ApiResponse;
import com.Wearther.api.dto.response.ClosetItemResponse;
import com.Wearther.api.entity.Category;
import com.Wearther.api.service.ClosetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/closet")
@RequiredArgsConstructor
@Tag(name = "Closet", description = "옷장 API")
@SecurityRequirement(name = "bearerAuth")
public class ClosetController {

    private final ClosetService closetService;

    @GetMapping("/items")
    @Operation(summary = "아이템 목록 조회")
    public ResponseEntity<ApiResponse<List<ClosetItemResponse>>> getItems(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Category category) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.getItems(userDetails.getUsername(), category)));
    }

    @PostMapping(value = "/items", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "아이템 등록")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> createItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String name,
            @RequestParam(required = false) String brand,
            @RequestParam Category category,
            @RequestParam(required = false) String tags,
            @RequestParam(required = false) Integer suitableTempMin,
            @RequestParam(required = false) Integer suitableTempMax,
            @RequestPart(value = "image", required = false) MultipartFile image) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.createItem(userDetails.getUsername(), name, brand, category,
                        tags, suitableTempMin, suitableTempMax, image)));
    }

    @GetMapping("/items/{id}")
    @Operation(summary = "아이템 단건 조회")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> getItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.getItem(userDetails.getUsername(), id)));
    }

    @PatchMapping("/items/{id}")
    @Operation(summary = "아이템 수정")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> updateItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestBody ClosetItemUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.updateItem(userDetails.getUsername(), id, request)));
    }

    @PatchMapping(value = "/items/{id}/image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "아이템 이미지 수정")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> updateItemImage(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestPart("image") MultipartFile image) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.updateItemImage(userDetails.getUsername(), id, image)));
    }

    @DeleteMapping("/items/{id}")
    @Operation(summary = "아이템 삭제")
    public ResponseEntity<ApiResponse<Void>> deleteItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        closetService.deleteItem(userDetails.getUsername(), id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @PostMapping("/items/{id}/wear")
    @Operation(summary = "착용 기록")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> wearItem(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.wearItem(userDetails.getUsername(), id)));
    }

    @PatchMapping("/items/{id}/favorite")
    @Operation(summary = "즐겨찾기 토글")
    public ResponseEntity<ApiResponse<ClosetItemResponse>> toggleFavorite(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(
                closetService.toggleFavorite(userDetails.getUsername(), id)));
    }
}
