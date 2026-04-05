package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByDestination_IdOrderByCreatedAtDesc(Long destinationId);
    List<Review> findByUser_UsernameOrderByCreatedAtDesc(String username);
}
