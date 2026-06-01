package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.dto.ReviewDto;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.security.FirebaseUserPrincipal;
import com.vn.huit.travelApp.service.AuthenticatedUserService;
import com.vn.huit.travelApp.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
    private final ReviewRepository reviewRepository;
    private final AuthenticatedUserService authenticatedUserService;

    @GetMapping("/{username}")
    public ResponseEntity<ApiResponse<User>> getUserProfile(@PathVariable String username) {
        authenticatedUserService.requireSelfOrAdmin(username);
        User user = userService.getUserInfo(username);
        if (user == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("User not found"));
        }
        return ResponseEntity.ok(ApiResponse.success(user, "User profile fetched"));
    }

    @PostMapping("/sync")
    public ResponseEntity<ApiResponse<User>> syncUser(@RequestBody Map<String, String> payload) {
        FirebaseUserPrincipal principal = authenticatedUserService.currentPrincipal();
        String uid = principal.uid();
        String email = principal.email() != null && !principal.email().isBlank()
                ? principal.email()
                : payload.get("email");
        String displayName = payload.get("displayName");
        if ((displayName == null || displayName.isBlank()) && principal.name() != null) {
            displayName = principal.name();
        }
        String photoUrl = payload.get("photoUrl");
        if (uid == null || uid.trim().isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("UID is required"));
        }
        User user = userService.syncUser(uid, email, displayName, photoUrl);
        return ResponseEntity.ok(ApiResponse.success(user, "User synced successfully"));
    }

    @PutMapping(value = "/{username}", consumes = {"multipart/form-data"})
    public ResponseEntity<ApiResponse<User>> updateUserProfile(
            @PathVariable String username,
            @RequestParam(value = "fullName", required = false) String fullName,
            @RequestParam(value = "avatar", required = false) MultipartFile avatar) {
        try {
            authenticatedUserService.requireSelfOrAdmin(username);
            User updatedUser = userService.updateUserProfile(username, fullName, avatar);
            if (updatedUser == null) {
                return ResponseEntity.status(404).body(ApiResponse.error("User not found"));
            }
            return ResponseEntity.ok(ApiResponse.success(updatedUser, "Profile updated successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(ApiResponse.error("Failed to update profile: " + e.getMessage()));
        }
    }

    @GetMapping("/{username}/reviews")
    public ResponseEntity<ApiResponse<List<ReviewDto>>> getUserReviews(@PathVariable String username) {
        authenticatedUserService.requireSelfOrAdmin(username);
        User user = userService.getUserInfo(username);
        if (user == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("User not found"));
        }
        List<ReviewDto> data = reviewRepository.findByUser_UsernameOrderByCreatedAtDesc(username)
                .stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Fetched user reviews"));
    }

    private ReviewDto toDto(Review review) {
        String authorName = "Ẩn danh";
        String avatarUrl = null;
        if (review.getUser() != null) {
             authorName = review.getUser().getFullName();
             if (authorName == null || authorName.isEmpty()) {
                 authorName = review.getUser().getUsername(); 
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
