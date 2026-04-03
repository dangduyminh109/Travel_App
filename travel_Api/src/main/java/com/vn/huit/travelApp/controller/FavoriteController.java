package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Favorite;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FavoriteController {

    private final FavoriteRepository favoriteRepository;
    private final DestinationRepository destinationRepository;

    @GetMapping("/{userId}/favorites")
    public ResponseEntity<ApiResponse<List<Long>>> getFavorites(@PathVariable String userId) {
        List<Long> ids = favoriteRepository.findByUserId(userId).stream()
                .map(fav -> fav.getDestination().getId())
                .toList();
        return ResponseEntity.ok(ApiResponse.success(ids, "Fetched favorites"));
    }

    @PostMapping("/{userId}/favorites/{destinationId}")
    public ResponseEntity<ApiResponse<List<Long>>> addFavorite(
            @PathVariable String userId,
            @PathVariable Long destinationId) {
        Destination destination = destinationRepository.findById(destinationId).orElse(null);
        if (destination == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("Destination not found"));
        }
        if (!favoriteRepository.existsByUserIdAndDestination_Id(userId, destinationId)) {
            favoriteRepository.save(Favorite.builder().userId(userId).destination(destination).build());
        }
        return getFavorites(userId);
    }

    @DeleteMapping("/{userId}/favorites/{destinationId}")
    public ResponseEntity<ApiResponse<List<Long>>> removeFavorite(
            @PathVariable String userId,
            @PathVariable Long destinationId) {
        favoriteRepository.deleteByUserIdAndDestination_Id(userId, destinationId);
        return getFavorites(userId);
    }
}
