package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.ReviewCreateRequest;
import com.vn.huit.travelApp.dto.ReviewDto;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import com.vn.huit.travelApp.entity.User;
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
    private final UserRepository userRepository;

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

        if (request.getUserId() == null || request.getUserId().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("User ID (uid) is required"));
        }
        User user = userRepository.findByUsername(request.getUserId()).orElse(null);
        if (user == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("User not found in system. Please sync user first."));
        }

        Review review = Review.builder()
                .user(user)
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

    @PutMapping("/{destinationId}/reviews/{reviewId}")
    public ResponseEntity<ApiResponse<ReviewDto>> updateReview(
            @PathVariable Long destinationId,
            @PathVariable Long reviewId,
            @RequestBody ReviewCreateRequest request) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null || !review.getDestination().getId().equals(destinationId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Review not found"));
        }
        if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Rating must be between 1 and 5"));
        }
        if (request.getComment() == null || request.getComment().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Comment is required"));
        }

        review.setRating(request.getRating());
        review.setComment(request.getComment());
        review.setCreatedAt(LocalDateTime.now());
        Review saved = reviewRepository.save(review);
        
        recalculateDestinationRating(destinationId);

        return ResponseEntity.ok(ApiResponse.success(toDto(saved), "Review updated"));
    }

    @DeleteMapping("/{destinationId}/reviews/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteReview(
            @PathVariable Long destinationId,
            @PathVariable Long reviewId) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null || !review.getDestination().getId().equals(destinationId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Review not found"));
        }
        
        reviewRepository.delete(review);
        
        recalculateDestinationRating(destinationId);

        return ResponseEntity.ok(ApiResponse.success(null, "Review deleted"));
    }

    private void recalculateDestinationRating(Long destinationId) {
        Destination destination = destinationRepository.findById(destinationId).orElse(null);
        if (destination == null) return;
        
        List<Review> reviews = reviewRepository.findByDestination_IdOrderByCreatedAtDesc(destinationId);
        if (reviews.isEmpty()) {
             destination.setRating(0.0);
             destination.setReviewCount(0);
        } else {
             double totalRating = 0;
             for (Review r : reviews) {
                 totalRating += r.getRating();
             }
             destination.setRating(totalRating / reviews.size());
             destination.setReviewCount(reviews.size());
        }
        destinationRepository.save(destination);
    }

    private ReviewDto toDto(Review review) {
        String authorName = "Ẩn danh";
        String avatarUrl = null;
        if (review.getUser() != null) {
             authorName = review.getUser().getFullName();
             if (authorName == null || authorName.isEmpty()) {
                 authorName = review.getUser().getUsername(); // Fallback
             }
             avatarUrl = review.getUser().getAvatarUrl();
        }
        return ReviewDto.builder()
                .id(review.getId())
                .destinationId(review.getDestination().getId())
                .destinationName(review.getDestination().getTitle())
                .destinationImage(review.getDestination().getImageUrl())
                .authorName(authorName)
                .avatarUrl(avatarUrl)
                .rating(review.getRating())
                .comment(review.getComment())
                .createdAt(review.getCreatedAt().toString())
                .build();
    }
}
