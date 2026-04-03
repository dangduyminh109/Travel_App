package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    List<Favorite> findByUserId(String userId);

    boolean existsByUserIdAndDestination_Id(String userId, Long destinationId);

    void deleteByUserIdAndDestination_Id(String userId, Long destinationId);
}
