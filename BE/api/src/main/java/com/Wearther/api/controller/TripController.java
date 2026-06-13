package com.Wearther.api.controller;

import com.Wearther.api.dto.request.TripRequest;
import com.Wearther.api.dto.request.TripUpdateRequest;
import com.Wearther.api.dto.response.ApiResponse;
import com.Wearther.api.dto.response.TripDayResponse;
import com.Wearther.api.dto.response.TripResponse;
import com.Wearther.api.service.TripService;
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
@RequestMapping("/api/trips")
@RequiredArgsConstructor
@Tag(name = "Trips", description = "여행 API")
@SecurityRequirement(name = "bearerAuth")
public class TripController {

    private final TripService tripService;

    @GetMapping
    @Operation(summary = "내 여행 목록 조회")
    public ResponseEntity<ApiResponse<List<TripResponse>>> getTrips(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.success(tripService.getTrips(userDetails.getUsername())));
    }

    @PostMapping
    @Operation(summary = "여행 생성")
    public ResponseEntity<ApiResponse<TripResponse>> createTrip(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody @Valid TripRequest request) {
        return ResponseEntity.ok(ApiResponse.success(tripService.createTrip(userDetails.getUsername(), request)));
    }

    @GetMapping("/{id}")
    @Operation(summary = "여행 단건 조회")
    public ResponseEntity<ApiResponse<TripResponse>> getTrip(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(tripService.getTrip(userDetails.getUsername(), id)));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "여행 수정")
    public ResponseEntity<ApiResponse<TripResponse>> updateTrip(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @RequestBody TripUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(tripService.updateTrip(userDetails.getUsername(), id, request)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "여행 삭제")
    public ResponseEntity<ApiResponse<Void>> deleteTrip(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        tripService.deleteTrip(userDetails.getUsername(), id);
        return ResponseEntity.ok(ApiResponse.success());
    }

    @GetMapping("/{id}/days")
    @Operation(summary = "일차별 목록 조회")
    public ResponseEntity<ApiResponse<List<TripDayResponse>>> getTripDays(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success(tripService.getTripDays(userDetails.getUsername(), id)));
    }

    @GetMapping("/{id}/days/{dayNumber}")
    @Operation(summary = "특정 일차 상세 조회")
    public ResponseEntity<ApiResponse<TripDayResponse>> getTripDay(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable Long id,
            @PathVariable int dayNumber) {
        return ResponseEntity.ok(ApiResponse.success(
                tripService.getTripDay(userDetails.getUsername(), id, dayNumber)));
    }
}
