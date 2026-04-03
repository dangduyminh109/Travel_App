package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.ReviewCreateRequest;
import com.vn.huit.travelApp.dto.ReviewDto;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/destinations")
@RequiredArgsConstructor
public class ReviewController {

    private final DestinationRepository destinationRepository;
    private final ReviewRepository reviewRepository;

    @GetMapping("/{destinationId}/reviews")
    public ResponseEntity<ApiResponse<List<ReviewDto>>> getReviews(@PathVariable Long destinationId) {
        if (!destinationRepository.existsById(destinationId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Destination not found"));
        }
        List<ReviewDto> data = reviewRepository.findByDestination_IdOrderByCreatedAtDesc(destinationId)
                .stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Fetched reviews"));
    }

    @PostMapping("/{destinationId}/reviews")
    public ResponseEntity<ApiResponse<ReviewDto>> addReview(
            @PathVariable Long destinationId,
            @RequestBody ReviewCreateRequest request) {
        Destination destination = destinationRepository.findById(destinationId).orElse(null);
        if (destination == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("Destination not found"));
        }
        if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Rating must be between 1 and 5"));
        }
        if (request.getComment() == null || request.getComment().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Comment is required"));
        }

        Review review = Review.builder()
                .authorName(request.getAuthorName() == null ? "Ẩn danh" : request.getAuthorName())
                .avatarUrl(request.getAvatarUrl())
                .rating(request.getRating())
                .comment(request.getComment())
                .createdAt(LocalDateTime.now())
                .destination(destination)
                .build();
        Review saved = reviewRepository.save(review);

        Integer currentCount = destination.getReviewCount() == null ? 0 : destination.getReviewCount();
        Double currentRating = destination.getRating() == null ? 0.0 : destination.getRating();
        int nextCount = currentCount + 1;
        double nextRating = ((currentRating * currentCount) + request.getRating()) / nextCount;
        destination.setReviewCount(nextCount);
        destination.setRating(nextRating);
        destinationRepository.save(destination);

        return ResponseEntity.ok(ApiResponse.success(toDto(saved), "Review added"));
    }

    private ReviewDto toDto(Review review) {
        return ReviewDto.builder()
                .id(review.getId())
                .destinationId(review.getDestination().getId())
                .authorName(review.getAuthorName())
                .avatarUrl(review.getAvatarUrl())
                .rating(review.getRating())
                .comment(review.getComment())
                .createdAt(review.getCreatedAt().toString())
                .build();
    }
}
