package com.Wearther.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class GeocodingService {

    // Nominatim은 한국어 포함 다국어 지명 검색 지원, API 키 불필요
    private static final String NOMINATIM_URL = "https://nominatim.openstreetmap.org/search";

    private final RestClient restClient = RestClient.builder()
            .defaultHeader("User-Agent", "Wearther-App/1.0")
            .build();

    /**
     * @return double[]{lat, lon}, or null if not found
     */
    public double[] getCoordinates(String cityName) {
        try {
            List<Map<String, Object>> result = restClient.get()
                    .uri(NOMINATIM_URL + "?q={city}&format=json&limit=1", cityName)
                    .retrieve()
                    .body(new ParameterizedTypeReference<>() {});

            if (result == null || result.isEmpty()) {
                log.warn("도시 좌표 없음: {}", cityName);
                return null;
            }

            double lat = Double.parseDouble((String) result.get(0).get("lat"));
            double lon = Double.parseDouble((String) result.get(0).get("lon"));
            return new double[]{lat, lon};

        } catch (Exception e) {
            log.warn("Geocoding API 호출 실패: {}", cityName, e);
            return null;
        }
    }
}
