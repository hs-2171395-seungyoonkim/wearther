package com.Wearther.api.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "trip_days")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TripDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @Column(name = "day_number", nullable = false)
    private int dayNumber;

    @Column(nullable = false)
    private LocalDate date;

    @Column(name = "location_name")
    private String locationName;

    private Double temperature;

    @Column(name = "weather_condition")
    private String weatherCondition;

    @Column(name = "feels_like")
    private Double feelsLike;

    @Column(name = "rain_chance")
    private Integer rainChance;

    @Column(name = "outfit_recommendation", columnDefinition = "TEXT")
    private String outfitRecommendation;

    @Column(name = "weather_notes", columnDefinition = "TEXT")
    private String weatherNotes;
}
