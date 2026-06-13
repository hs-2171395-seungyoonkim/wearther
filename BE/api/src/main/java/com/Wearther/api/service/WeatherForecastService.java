package com.Wearther.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class WeatherForecastService {

    private static final String FORECAST_URL = "https://api.openweathermap.org/data/2.5/forecast";

    @Value("${openweather.api.key}")
    private String apiKey;

    private final RestClient restClient = RestClient.create();

    public record WeatherData(Double temperature, Double feelsLike, String weatherCondition, Integer rainChance) {}

    /**
     * OWM 5-day/3h forecast에서 해당 날짜의 12:00:00 슬롯 데이터를 추출한다.
     * 12:00 슬롯이 없으면 가장 가까운 슬롯을 사용한다.
     */
    @SuppressWarnings("unchecked")
    public WeatherData getForecast(double lat, double lon, LocalDate date) {
        try {
            Map<String, Object> response = restClient.get()
                    .uri(FORECAST_URL + "?lat={lat}&lon={lon}&appid={key}&units=metric",
                            lat, lon, apiKey)
                    .retrieve()
                    .body(new ParameterizedTypeReference<>() {});

            if (response == null) return null;

            List<Map<String, Object>> list = (List<Map<String, Object>>) response.get("list");
            if (list == null || list.isEmpty()) return null;

            String targetDate = date.toString(); // "yyyy-MM-dd"
            Map<String, Object> best = null;

            for (Map<String, Object> slot : list) {
                String dtTxt = (String) slot.get("dt_txt"); // "yyyy-MM-dd HH:mm:ss"
                if (dtTxt == null || !dtTxt.startsWith(targetDate)) continue;
                if (dtTxt.contains("12:00:00")) {
                    best = slot;
                    break;
                }
                if (best == null) best = slot; // 날짜 일치하는 첫 슬롯 fallback
            }

            if (best == null) return null;

            Map<String, Object> main = (Map<String, Object>) best.get("main");
            List<Map<String, Object>> weatherList = (List<Map<String, Object>>) best.get("weather");
            Number pop = (Number) best.get("pop");

            double temp = ((Number) main.get("temp")).doubleValue();
            double feelsLike = ((Number) main.get("feels_like")).doubleValue();
            String condition = toKorean((String) weatherList.get(0).get("main"));
            int rainChance = pop != null ? (int) Math.round(pop.doubleValue() * 100) : 0;

            return new WeatherData(temp, feelsLike, condition, rainChance);

        } catch (Exception e) {
            log.warn("날씨 예보 조회 실패: lat={}, lon={}, date={}", lat, lon, date, e);
            return null;
        }
    }

    private String toKorean(String owmMain) {
        if (owmMain == null) return "알 수 없음";
        return switch (owmMain) {
            case "Clear"       -> "맑음";
            case "Clouds"      -> "흐림";
            case "Rain"        -> "비";
            case "Drizzle"     -> "이슬비";
            case "Thunderstorm" -> "천둥번개";
            case "Snow"        -> "눈";
            case "Mist", "Fog" -> "안개";
            case "Haze"        -> "연무";
            case "Dust", "Sand" -> "황사";
            default            -> owmMain;
        };
    }
}
