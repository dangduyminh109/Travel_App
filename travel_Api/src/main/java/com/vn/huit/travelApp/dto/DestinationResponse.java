package com.vn.huit.travelApp.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DestinationResponse {
    private Long id;
    private String title;
    private String subtitle;
    private String description;
    private String imageUrl;
    private String region;

    private String category;
    private Double rating;
    private Integer reviewCount;
    private String tags;
}
