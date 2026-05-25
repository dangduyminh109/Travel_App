package com.vn.huit.travelApp.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ReplyDto {
    private Long id;
    private String userId;
    private String authorName;
    private String content;
    private String createdAt;
}
