package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Favorite;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import com.vn.huit.travelApp.entity.User;
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
    private final UserRepository userRepository;

    @GetMapping("/{userId}/favorites")
    public ResponseEntity<ApiResponse<List<Long>>> getFavorites(@PathVariable String userId) {
        List<Long> ids = favoriteRepository.findByUser_Username(userId).stream()
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
        User user = userRepository.findByUsername(userId).orElse(null);
        if (user == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("User not synced. Please sync first."));
        }
        if (!favoriteRepository.existsByUser_UsernameAndDestination_Id(userId, destinationId)) {
            favoriteRepository.save(Favorite.builder().user(user).destination(destination).build());
        }
        return getFavorites(userId);
    }

    @DeleteMapping("/{userId}/favorites/{destinationId}")
    public ResponseEntity<ApiResponse<List<Long>>> removeFavorite(
            @PathVariable String userId,
            @PathVariable Long destinationId) {
        favoriteRepository.deleteByUser_UsernameAndDestination_Id(userId, destinationId);
        return getFavorites(userId);
    }
}
