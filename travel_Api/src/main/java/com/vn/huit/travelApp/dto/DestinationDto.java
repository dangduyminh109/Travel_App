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
    private Double price;
    private Double rating;
    private Integer reviewCount;
    private Long categoryId;
    private String categoryName;
    private String tags;
}
