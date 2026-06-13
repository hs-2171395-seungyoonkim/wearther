package com.Wearther.api.controller;

import com.Wearther.api.dto.request.WornLogRequest;
import com.Wearther.api.dto.response.ApiResponse;
import com.Wearther.api.dto.response.WornLogResponse;
import com.Wearther.api.service.WornLogService;
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
@RequestMapping("/api/worn-logs")
@RequiredArgsConstructor
@Tag(name = "WornLog", description = "착용 기록 API")
@SecurityRequirement(name = "bearerAuth")
public class WornLogController {

    private final WornLogService wornLogService;

    @PostMapping
    @Operation(summary = "착용 기록 저장", description = "특정 날짜에 착용한 아이템을 기록합니다.")
    public ResponseEntity<ApiResponse<WornLogResponse>> logWorn(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody WornLogRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                wornLogService.logWorn(userDetails.getUsername(), request)));
    }

    @GetMapping
    @Operation(summary = "월별 착용 기록 조회", description = "연도와 월을 기준으로 착용 기록을 조회합니다.")
    public ResponseEntity<ApiResponse<List<WornLogResponse>>> getWornLogs(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam int year,
            @RequestParam int month) {
        return ResponseEntity.ok(ApiResponse.success(
                wornLogService.getWornLogs(userDetails.getUsername(), year, month)));
    }

    @GetMapping("/{date}")
    @Operation(summary = "특정 날짜 착용 기록 조회")
    public ResponseEntity<ApiResponse<WornLogResponse>> getWornLogByDate(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String date) {
        return ResponseEntity.ok(ApiResponse.success(
                wornLogService.getWornLogByDate(userDetails.getUsername(), date)));
    }
}
