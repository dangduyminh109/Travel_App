package com.vn.huit.travelApp.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ReviewResponse {
    private Long id;
    private String name;
    private String date;
    private Integer rating;
    private String comment;
    private String avatarUrl;
}
