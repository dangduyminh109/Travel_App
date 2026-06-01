package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.DestinationDto;
import com.vn.huit.travelApp.entity.Category;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.repository.CategoryRepository;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Set;

@RestController
@RequestMapping("/api/admin/destinations")
@RequiredArgsConstructor
public class AdminDestinationController {

    private static final Set<String> PLACE_TYPES = Set.of(
            "FOOD", "ENTERTAINMENT", "HOTEL", "CAFE", "CULTURE_HISTORY", "SHOPPING"
    );
    private static final Set<String> PRICE_LEVELS = Set.of(
            "FREE", "BUDGET", "MODERATE", "PREMIUM", "LUXURY"
    );

    private final DestinationRepository destinationRepository;
    private final CategoryRepository categoryRepository;
    private final ReviewRepository reviewRepository;
    private final FavoriteRepository favoriteRepository;

    @PostMapping
    public ResponseEntity<ApiResponse<DestinationDto>> create(@RequestBody DestinationDto request) {
        ResponseEntity<ApiResponse<DestinationDto>> invalid = validate(request);
        if (invalid != null) return invalid;

        Destination destination = new Destination();
        apply(destination, request);
        destination.setRating(request.getRating() == null ? 0.0 : request.getRating());
        destination.setReviewCount(request.getReviewCount() == null ? 0 : request.getReviewCount());
        Destination saved = destinationRepository.save(destination);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(toDto(saved), "Destination created"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<DestinationDto>> update(
            @PathVariable Long id,
            @RequestBody DestinationDto request
    ) {
        Destination destination = destinationRepository.findById(id).orElse(null);
        if (destination == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("Destination not found"));
        }
        ResponseEntity<ApiResponse<DestinationDto>> invalid = validate(request);
        if (invalid != null) return invalid;

        apply(destination, request);
        Destination saved = destinationRepository.save(destination);
        return ResponseEntity.ok(ApiResponse.success(toDto(saved), "Destination updated"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        if (!destinationRepository.existsById(id)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Destination not found"));
        }
        long reviewCount = reviewRepository.countByDestination_Id(id);
        long favoriteCount = favoriteRepository.countByDestination_Id(id);
        if (reviewCount > 0 || favoriteCount > 0) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("Cannot delete destination with reviews or favorites"));
        }
        destinationRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Destination deleted"));
    }

    private ResponseEntity<ApiResponse<DestinationDto>> validate(DestinationDto request) {
        if (isBlank(request.getTitle())) return bad("Title is required");
        if (isBlank(request.getDescription())) return bad("Description is required");
        if (isBlank(request.getCity())) return bad("City is required");
        if (isBlank(request.getPlaceType()) || !PLACE_TYPES.contains(request.getPlaceType().toUpperCase())) {
            return bad("Place type is invalid");
        }
        if (isBlank(request.getPriceLevel()) || !PRICE_LEVELS.contains(request.getPriceLevel().toUpperCase())) {
            return bad("Price level is invalid");
        }
        if (request.getCategoryId() == null || !categoryRepository.existsById(request.getCategoryId())) {
            return bad("Category is required");
        }
        if (request.getMinPrice() != null && request.getMaxPrice() != null
                && request.getMinPrice() > request.getMaxPrice()) {
            return bad("Min price must be less than or equal to max price");
        }
        if (request.getRating() != null && (request.getRating() < 0 || request.getRating() > 5)) {
            return bad("Rating must be between 0 and 5");
        }
        return null;
    }

    private ResponseEntity<ApiResponse<DestinationDto>> bad(String message) {
        return ResponseEntity.badRequest().body(ApiResponse.error(message));
    }

    private void apply(Destination destination, DestinationDto request) {
        Category category = categoryRepository.findById(request.getCategoryId()).orElseThrow();
        destination.setTitle(request.getTitle().trim());
        destination.setSubtitle(trimOrEmpty(request.getSubtitle()));
        destination.setDescription(request.getDescription().trim());
        destination.setImageUrl(normalizeImageUrl(request.getImageUrl()));
        destination.setRegion(trimOrDefault(request.getRegion(), request.getCity()));
        destination.setCity(request.getCity().trim());
        destination.setDistrict(trimOrEmpty(request.getDistrict()));
        destination.setAddress(trimOrEmpty(request.getAddress()));
        destination.setPlaceType(request.getPlaceType().trim().toUpperCase());
        destination.setPriceLevel(request.getPriceLevel().trim().toUpperCase());
        destination.setMinPrice(request.getMinPrice());
        destination.setMaxPrice(request.getMaxPrice());
        destination.setOpeningHours(trimOrEmpty(request.getOpeningHours()));
        destination.setHighlights(trimOrEmpty(request.getHighlights()));
        destination.setSuitableFor(trimOrEmpty(request.getSuitableFor()));
        destination.setCategory(category);
        destination.setTags(trimOrEmpty(request.getTags()));
        destination.setLatitude(request.getLatitude());
        destination.setLongitude(request.getLongitude());
        if (request.getRating() != null) destination.setRating(request.getRating());
        if (request.getReviewCount() != null) destination.setReviewCount(request.getReviewCount());
    }

    private DestinationDto toDto(Destination destination) {
        Long categoryId = destination.getCategory() == null ? null : destination.getCategory().getId();
        String categoryName = destination.getCategory() == null ? null : destination.getCategory().getName();
        return DestinationDto.builder()
                .id(destination.getId())
                .title(destination.getTitle())
                .subtitle(destination.getSubtitle())
                .description(destination.getDescription())
                .imageUrl(destination.getImageUrl())
                .region(destination.getRegion())
                .city(destination.getCity())
                .district(destination.getDistrict())
                .address(destination.getAddress())
                .placeType(destination.getPlaceType())
                .priceLevel(destination.getPriceLevel())
                .minPrice(destination.getMinPrice())
                .maxPrice(destination.getMaxPrice())
                .openingHours(destination.getOpeningHours())
                .highlights(destination.getHighlights())
                .suitableFor(destination.getSuitableFor())
                .rating(destination.getRating())
                .reviewCount(destination.getReviewCount())
                .categoryId(categoryId)
                .categoryName(categoryName)
                .tags(destination.getTags())
                .latitude(destination.getLatitude())
                .longitude(destination.getLongitude())
                .build();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trimOrEmpty(String value) {
        return value == null ? "" : value.trim();
    }

    private String trimOrDefault(String value, String fallback) {
        return isBlank(value) ? fallback.trim() : value.trim();
    }

    private String normalizeImageUrl(String value) {
        String imageUrl = trimOrEmpty(value);
        String marker = "/api/images/proxy?url=";
        int markerIndex = imageUrl.indexOf(marker);
        if (markerIndex < 0) {
            return imageUrl;
        }
        String encoded = imageUrl.substring(markerIndex + marker.length());
        int nextParam = encoded.indexOf('&');
        if (nextParam >= 0) {
            encoded = encoded.substring(0, nextParam);
        }
        return URLDecoder.decode(encoded, StandardCharsets.UTF_8);
    }
}
