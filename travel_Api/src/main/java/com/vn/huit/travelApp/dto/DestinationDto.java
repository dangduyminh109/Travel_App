package com.vn.huit.travelApp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class DestinationDto {
    private Long id;
    private String title;
    private String subtitle;
    private String description;
    private String imageUrl;
    private String region;
    private String city;
    private String district;
    private String address;
    private String placeType;
    private String priceLevel;
    private Long minPrice;
    private Long maxPrice;
    private String openingHours;
    private String highlights;
    private String suitableFor;

    private Double rating;
    private Integer reviewCount;
    private Long categoryId;
    private String categoryName;
    private String tags;
    private Double latitude;
    private Double longitude;
    private Double distanceKm;
}
