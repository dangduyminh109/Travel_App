package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.ReplyDto;
import com.vn.huit.travelApp.dto.ReviewCreateRequest;
import com.vn.huit.travelApp.dto.ReviewDto;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.repository.*;
import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.service.AuthenticatedUserService;
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
    private final ReplyRepository replyRepository;
    private final ReviewLikeRepository reviewLikeRepository;
    private final com.vn.huit.travelApp.service.FirebaseRealtimeService firebaseRealtimeService;
    private final AuthenticatedUserService authenticatedUserService;

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

        User user = authenticatedUserService.currentUser();

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

        // SYNC TO FIREBASE
        ReviewDto dto = toDto(saved);
        java.util.Map<String, Object> firebaseData = new java.util.HashMap<>();
        firebaseData.put("id", dto.getId());
        firebaseData.put("authorName", dto.getAuthorName());
        firebaseData.put("avatarUrl", dto.getAvatarUrl());
        firebaseData.put("rating", dto.getRating());
        firebaseData.put("comment", dto.getComment());
        firebaseData.put("createdAt", dto.getCreatedAt());
        firebaseData.put("destinationName", dto.getDestinationName());
        firebaseRealtimeService.pushReview(destinationId, firebaseData);

        // NOTIFY
        String authorName = dto.getAuthorName();
        firebaseRealtimeService.pushNotification(
            "Đánh giá mới",
            authorName + " đã đánh giá " + destination.getTitle(),
            "REVIEW",
            user.getUsername());

        return ResponseEntity.ok(ApiResponse.success(dto, "Review added"));
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
        if (!authenticatedUserService.canManage(review.getUser())) {
            return ResponseEntity.status(403).body(ApiResponse.error("Not authorized to update this review"));
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

        // SYNC TO FIREBASE
        ReviewDto dto = toDto(saved);
        java.util.Map<String, Object> firebaseData = new java.util.HashMap<>();
        firebaseData.put("id", dto.getId());
        firebaseData.put("authorName", dto.getAuthorName());
        firebaseData.put("avatarUrl", dto.getAvatarUrl());
        firebaseData.put("rating", dto.getRating());
        firebaseData.put("comment", dto.getComment());
        firebaseData.put("createdAt", dto.getCreatedAt());
        firebaseRealtimeService.pushReview(destinationId, firebaseData);

        return ResponseEntity.ok(ApiResponse.success(dto, "Review updated"));
    }

    @DeleteMapping("/{destinationId}/reviews/{reviewId}")
    public ResponseEntity<ApiResponse<Void>> deleteReview(
            @PathVariable Long destinationId,
            @PathVariable Long reviewId) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null || !review.getDestination().getId().equals(destinationId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Review not found"));
        }
        if (!authenticatedUserService.canManage(review.getUser())) {
            return ResponseEntity.status(403).body(ApiResponse.error("Not authorized to delete this review"));
        }
        
        reviewRepository.delete(review);
        
        recalculateDestinationRating(destinationId);

        // SYNC TO FIREBASE
        firebaseRealtimeService.removeReview(destinationId, reviewId);

        return ResponseEntity.ok(ApiResponse.success(null, "Review deleted"));
    }

    @PostMapping("/reviews/{reviewId}/replies")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> addReply(
            @PathVariable Long reviewId,
            @RequestBody ReviewCreateRequest request) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("Review not found"));
        }
        User user = authenticatedUserService.currentUser();
        if (request.getComment() == null || request.getComment().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Reply content is required"));
        }

        com.vn.huit.travelApp.entity.Reply reply = com.vn.huit.travelApp.entity.Reply.builder()
                .user(user)
                .content(request.getComment().trim()) // Reuse comment field as content
                .createdAt(LocalDateTime.now())
                .review(review)
                .build();
        com.vn.huit.travelApp.entity.Reply saved = replyRepository.save(reply);

        // SYNC TO FIREBASE
        java.util.Map<String, Object> firebaseData = new java.util.HashMap<>();
        firebaseData.put("id", saved.getId());
        firebaseData.put("userId", user.getUsername());
        firebaseData.put("authorName", displayName(user));
        firebaseData.put("content", saved.getContent());
        firebaseData.put("createdAt", saved.getCreatedAt().toString());
        firebaseRealtimeService.pushReply(reviewId, firebaseData);

        // NOTIFY the review author
        String reviewAuthor = review.getUser() != null ? displayName(review.getUser()) : "";
        String replyAuthor = displayName(user);
        if (review.getUser() != null && !user.getUsername().equals(review.getUser().getUsername())) {
            firebaseRealtimeService.pushNotification(
                "Phản hồi mới",
                replyAuthor + " đã phản hồi đánh giá của " + reviewAuthor,
                "REPLY",
                review.getUser().getUsername());
        }

        return ResponseEntity.ok(ApiResponse.success(firebaseData, "Reply added"));
    }

    @PutMapping("/reviews/{reviewId}/replies/{replyId}")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> updateReply(
            @PathVariable Long reviewId,
            @PathVariable Long replyId,
            @RequestParam String userId,
            @RequestBody ReviewCreateRequest request) {
        com.vn.huit.travelApp.entity.Reply reply = replyRepository.findById(replyId).orElse(null);
        if (reply == null || !reply.getReview().getId().equals(reviewId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Reply not found"));
        }
        if (!authenticatedUserService.canManage(reply.getUser())) {
            return ResponseEntity.status(403).body(ApiResponse.error("Not authorized to update this reply"));
        }
        if (request.getComment() == null || request.getComment().trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Reply content is required"));
        }

        reply.setContent(request.getComment().trim());
        com.vn.huit.travelApp.entity.Reply saved = replyRepository.save(reply);

        java.util.Map<String, Object> firebaseData = new java.util.HashMap<>();
        firebaseData.put("id", saved.getId());
        firebaseData.put("userId", saved.getUser().getUsername());
        firebaseData.put("authorName", displayName(saved.getUser()));
        firebaseData.put("content", saved.getContent());
        firebaseData.put("createdAt", saved.getCreatedAt().toString());
        firebaseRealtimeService.pushReply(reviewId, firebaseData);

        return ResponseEntity.ok(ApiResponse.success(firebaseData, "Reply updated"));
    }

    @PostMapping("/reviews/{reviewId}/like")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> toggleLike(
            @PathVariable Long reviewId,
            @RequestParam String userId,
            @RequestParam(defaultValue = "LIKE") String type) {
        Review review = reviewRepository.findById(reviewId).orElse(null);
        if (review == null) return ResponseEntity.status(404).body(ApiResponse.error("Review not found"));
        
        User user = authenticatedUserService.currentUser();
        userId = user.getUsername();

        java.util.Optional<com.vn.huit.travelApp.entity.ReviewLike> existing = reviewLikeRepository.findByReviewAndUser(review, user);
        String resultType;
        if (existing.isPresent()) {
            if (existing.get().getReactionType().equals(type)) {
                // Same type → toggle off (remove)
                reviewLikeRepository.delete(existing.get());
                resultType = "NONE";
            } else {
                // Different type → switch (e.g. LIKE → DISLIKE)
                existing.get().setReactionType(type);
                reviewLikeRepository.save(existing.get());
                resultType = type;
            }
        } else {
            // No existing → create new
            reviewLikeRepository.save(com.vn.huit.travelApp.entity.ReviewLike.builder()
                    .review(review)
                    .user(user)
                    .reactionType(type)
                    .createdAt(LocalDateTime.now())
                    .build());
            resultType = type;
        }

        // SYNC TO FIREBASE
        firebaseRealtimeService.pushReaction(reviewId, userId, resultType);

        // NOTIFY the review author (only for new like/dislike, not for removal)
        if (!"NONE".equals(resultType) && review.getUser() != null
                && !userId.equals(review.getUser().getUsername())) {
            String reactorName = displayName(user);
            String reviewAuthor = displayName(review.getUser());
            String action = "LIKE".equals(resultType) ? "thích" : "không thích";
            firebaseRealtimeService.pushNotification(
                "Tương tác mới",
                reactorName + " đã " + action + " đánh giá của " + reviewAuthor,
                "REACTION",
                review.getUser().getUsername());
        }

        long likeCount = reviewLikeRepository.countByReview_IdAndReactionType(reviewId, "LIKE");
        long dislikeCount = reviewLikeRepository.countByReview_IdAndReactionType(reviewId, "DISLIKE");
        return ResponseEntity.ok(ApiResponse.success(
                java.util.Map.of("type", resultType, "likeCount", likeCount, "dislikeCount", dislikeCount),
                "Reaction toggled"));
    }

    @DeleteMapping("/reviews/{reviewId}/replies/{replyId}")
    public ResponseEntity<ApiResponse<Void>> deleteReply(
            @PathVariable Long reviewId,
            @PathVariable Long replyId,
            @RequestParam String userId) {
        com.vn.huit.travelApp.entity.Reply reply = replyRepository.findById(replyId).orElse(null);
        if (reply == null || !reply.getReview().getId().equals(reviewId)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Reply not found"));
        }
        // Only the author can delete
        if (!authenticatedUserService.canManage(reply.getUser())) {
            return ResponseEntity.status(403).body(ApiResponse.error("Not authorized to delete this reply"));
        }
        replyRepository.delete(reply);

        // SYNC TO FIREBASE
        firebaseRealtimeService.removeReply(reviewId, replyId);

        return ResponseEntity.ok(ApiResponse.success(null, "Reply deleted"));
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
             authorName = displayName(review.getUser());
             avatarUrl = review.getUser().getAvatarUrl();
        }
        List<ReplyDto> replies = replyRepository.findByReview_IdOrderByCreatedAtAsc(review.getId())
                .stream()
                .map(this::toReplyDto)
                .toList();
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
                .likeCount(reviewLikeRepository.countByReview_IdAndReactionType(review.getId(), "LIKE"))
                .dislikeCount(reviewLikeRepository.countByReview_IdAndReactionType(review.getId(), "DISLIKE"))
                .replies(replies)
                .build();
    }

    private ReplyDto toReplyDto(com.vn.huit.travelApp.entity.Reply reply) {
        User user = reply.getUser();
        return ReplyDto.builder()
                .id(reply.getId())
                .userId(user != null ? user.getUsername() : "")
                .authorName(user != null ? displayName(user) : "Ẩn danh")
                .content(reply.getContent())
                .createdAt(reply.getCreatedAt().toString())
                .build();
    }

    private String displayName(User user) {
        if (user == null) return "Ẩn danh";
        String name = user.getFullName();
        if (name == null || name.isBlank()) {
            return user.getUsername();
        }
        return name;
    }
}
