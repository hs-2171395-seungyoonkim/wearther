package com.Wearther.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "closet_items")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ClosetItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String name;

    private String brand;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Category category;

    private String tags;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "wear_count", nullable = false)
    @Builder.Default
    private int wearCount = 0;

    @Column(name = "last_worn")
    private LocalDate lastWorn;

    @Column(name = "is_favorite", nullable = false)
    @Builder.Default
    private boolean favorite = false;

    @Column(name = "suitable_temp_min")
    private Integer suitableTempMin;

    @Column(name = "suitable_temp_max")
    private Integer suitableTempMax;

    @Column(name = "ai_notes", columnDefinition = "TEXT")
    private String aiNotes;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
