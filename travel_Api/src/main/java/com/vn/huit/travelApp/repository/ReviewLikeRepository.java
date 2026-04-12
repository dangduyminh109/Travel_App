package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.ReviewLike;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ReviewLikeRepository extends JpaRepository<ReviewLike, Long> {
    Optional<ReviewLike> findByReviewAndUser(Review review, User user);
    long countByReview_Id(Long reviewId);
    long countByReview_IdAndReactionType(Long reviewId, String reactionType);
    boolean existsByReview_IdAndUser_Username(Long reviewId, String username);
}
