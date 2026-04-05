package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

import org.springframework.transaction.annotation.Transactional;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    List<Favorite> findByUser_Username(String username);

    boolean existsByUser_UsernameAndDestination_Id(String username, Long destinationId);

    @Transactional
    void deleteByUser_UsernameAndDestination_Id(String username, Long destinationId);
}
