package com.Wearther.api.service;

import com.Wearther.api.dto.request.TripRequest;
import com.Wearther.api.dto.request.TripUpdateRequest;
import com.Wearther.api.dto.response.TripDayResponse;
import com.Wearther.api.dto.response.TripResponse;
import com.Wearther.api.entity.Trip;
import com.Wearther.api.entity.TripDay;
import com.Wearther.api.entity.User;
import com.Wearther.api.exception.ApiException;
import com.Wearther.api.repository.TripDayRepository;
import com.Wearther.api.repository.TripRepository;
import com.Wearther.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TripService {

    private final TripRepository tripRepository;
    private final TripDayRepository tripDayRepository;
    private final UserRepository userRepository;
    private final GeocodingService geocodingService;
    private final WeatherForecastService weatherForecastService;
    private final AiService aiService;

    @Transactional(readOnly = true)
    public List<TripResponse> getTrips(String email) {
        User user = findUserByEmail(email);
        return tripRepository.findByUserId(user.getId())
                .stream().map(TripResponse::from).collect(Collectors.toList());
    }

    @Transactional
    public TripResponse createTrip(String email, TripRequest request) {
        User user = findUserByEmail(email);
        Trip trip = Trip.builder()
                .user(user)
                .destination(request.getDestination())
                .startDate(request.getStartDate())
                .endDate(request.getEndDate())
                .travelStyle(request.getTravelStyle())
                .activities(request.getActivities() != null
                        ? String.join(",", request.getActivities()) : null)
                .build();
        tripRepository.save(trip);

        long numDays = ChronoUnit.DAYS.between(request.getStartDate(), request.getEndDate()) + 1;
        List<TripDay> savedDays = new ArrayList<>();
        for (int i = 0; i < numDays; i++) {
            savedDays.add(tripDayRepository.save(TripDay.builder()
                    .trip(trip)
                    .dayNumber(i + 1)
                    .date(request.getStartDate().plusDays(i))
                    .build()));
        }

        try {
            long daysUntilTrip = ChronoUnit.DAYS.between(LocalDate.now(), trip.getStartDate());
            if (daysUntilTrip <= 5) {
                double[] coords = geocodingService.getCoordinates(trip.getDestination());
                if (coords != null) {
                    for (TripDay day : savedDays) {
                        WeatherForecastService.WeatherData weather =
                                weatherForecastService.getForecast(coords[0], coords[1], day.getDate());
                        if (weather != null) {
                            day.setTemperature(weather.temperature());
                            day.setFeelsLike(weather.feelsLike());
                            day.setWeatherCondition(weather.weatherCondition());
                            day.setRainChance(weather.rainChance());
                            tripDayRepository.save(day);
                        }
                    }
                }
            }
            aiService.recommendTripOutfitsInternal(user.getEmail(), trip.getId());
        } catch (Exception e) {
            log.warn("날씨/AI 처리 실패, trip 생성은 완료: tripId={}", trip.getId(), e);
        }

        return TripResponse.from(trip);
    }

    @Transactional(readOnly = true)
    public TripResponse getTrip(String email, Long tripId) {
        return TripResponse.from(findTripByOwner(tripId, email));
    }

    @Transactional
    public TripResponse updateTrip(String email, Long tripId, TripUpdateRequest request) {
        Trip trip = findTripByOwner(tripId, email);
        if (request.getDestination() != null) trip.setDestination(request.getDestination());
        if (request.getStartDate() != null) trip.setStartDate(request.getStartDate());
        if (request.getEndDate() != null) trip.setEndDate(request.getEndDate());
        if (request.getTravelStyle() != null) trip.setTravelStyle(request.getTravelStyle());
        if (request.getActivities() != null) trip.setActivities(String.join(",", request.getActivities()));
        if (request.getPackingList() != null) trip.setPackingList(request.getPackingList());
        return TripResponse.from(tripRepository.save(trip));
    }

    @Transactional
    public void deleteTrip(String email, Long tripId) {
        Trip trip = findTripByOwner(tripId, email);
        tripDayRepository.deleteByTripId(trip.getId());
        tripRepository.delete(trip);
    }

    @Transactional(readOnly = true)
    public List<TripDayResponse> getTripDays(String email, Long tripId) {
        findTripByOwner(tripId, email);
        return tripDayRepository.findByTripIdOrderByDayNumber(tripId)
                .stream().map(TripDayResponse::from).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TripDayResponse getTripDay(String email, Long tripId, int dayNumber) {
        findTripByOwner(tripId, email);
        TripDay day = tripDayRepository.findByTripIdAndDayNumber(tripId, dayNumber)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "해당 일차를 찾을 수 없습니다."));
        return TripDayResponse.from(day);
    }

    private Trip findTripByOwner(Long tripId, String email) {
        User user = findUserByEmail(email);
        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "여행을 찾을 수 없습니다."));
        if (!trip.getUser().getId().equals(user.getId())) {
            throw new ApiException(HttpStatus.FORBIDDEN, "접근 권한이 없습니다.");
        }
        return trip;
    }

    private User findUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
