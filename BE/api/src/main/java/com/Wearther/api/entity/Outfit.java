package com.Wearther.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "outfits")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Outfit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String description;

    @Column(name = "weather_condition")
    private String weatherCondition;

    @Column(name = "temperature_min")
    private Integer temperatureMin;

    @Column(name = "temperature_max")
    private Integer temperatureMax;

    @Column(name = "compatibility_score")
    private Integer compatibilityScore;

    @Column(name = "is_saved", nullable = false)
    @Builder.Default
    private boolean saved = false;

    @Column(name = "is_bookmarked", nullable = false)
    @Builder.Default
    private boolean bookmarked = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
            name = "outfit_items",
            joinColumns = @JoinColumn(name = "outfit_id"),
            inverseJoinColumns = @JoinColumn(name = "closet_item_id")
    )
    @Builder.Default
    private List<ClosetItem> items = new ArrayList<>();
}
