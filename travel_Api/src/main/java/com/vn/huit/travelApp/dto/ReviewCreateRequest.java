package com.vn.huit.travelApp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ReviewCreateRequest {
    private String userId;
    private Integer rating;
    private String comment;
}
