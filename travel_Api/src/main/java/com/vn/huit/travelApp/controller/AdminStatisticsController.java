package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Favorite;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/statistics")
@RequiredArgsConstructor
public class AdminStatisticsController {

    private final DestinationRepository destinationRepository;
    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;
    private final FavoriteRepository favoriteRepository;

    @GetMapping("/overview")
    public ResponseEntity<ApiResponse<Map<String, Object>>> overview() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("destinationCount", destinationRepository.count());
        data.put("userCount", userRepository.count());
        data.put("reviewCount", reviewRepository.count());
        data.put("favoriteCount", favoriteRepository.count());
        return ResponseEntity.ok(ApiResponse.success(data, "Statistics overview"));
    }

    @GetMapping("/top-rated")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> topRated(
            @RequestParam(defaultValue = "5") int limit
    ) {
        List<Map<String, Object>> data = destinationRepository.findAll().stream()
                .filter(item -> item.getRating() != null && item.getRating() > 0)
                .sorted(Comparator
                        .comparing((Destination item) -> item.getRating() == null ? 0.0 : item.getRating())
                        .reversed()
                        .thenComparing(
                                Comparator.comparing(
                                        (Destination item) -> item.getReviewCount() == null ? 0 : item.getReviewCount()
                                ).reversed()
                        ))
                .limit(Math.max(1, limit))
                .map(this::destinationSummary)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Top rated destinations"));
    }

    @GetMapping("/top-favorited")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> topFavorited(
            @RequestParam(defaultValue = "5") int limit
    ) {
        Map<Destination, Long> counts = favoriteRepository.findAll().stream()
                .collect(Collectors.groupingBy(Favorite::getDestination, Collectors.counting()));
        List<Map<String, Object>> data = counts.entrySet().stream()
                .sorted(Map.Entry.<Destination, Long>comparingByValue().reversed())
                .limit(Math.max(1, limit))
                .map(entry -> {
                    Map<String, Object> row = destinationSummary(entry.getKey());
                    row.put("favoriteCount", entry.getValue());
                    return row;
                })
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Top favorited destinations"));
    }

    @GetMapping("/by-category")
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> byCategory() {
        Map<String, Long> counts = destinationRepository.findAll().stream()
                .collect(Collectors.groupingBy(destination -> {
                    if (destination.getCategory() != null && destination.getCategory().getName() != null) {
                        return destination.getCategory().getName();
                    }
                    if (destination.getPlaceType() != null && !destination.getPlaceType().isBlank()) {
                        return destination.getPlaceType();
                    }
                    return "Khác";
                }, LinkedHashMap::new, Collectors.counting()));

        List<Map<String, Object>> data = counts.entrySet().stream()
                .map(entry -> {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("category", entry.getKey());
                    row.put("count", entry.getValue());
                    return row;
                })
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Destinations by category"));
    }

    private Map<String, Object> destinationSummary(Destination destination) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", destination.getId());
        row.put("title", destination.getTitle());
        row.put("city", destination.getCity());
        row.put("district", destination.getDistrict());
        row.put("placeType", destination.getPlaceType());
        row.put("rating", destination.getRating());
        row.put("reviewCount", destination.getReviewCount());
        return row;
    }
}
