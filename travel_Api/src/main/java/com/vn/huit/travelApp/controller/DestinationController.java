package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.DestinationDto;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.repository.DestinationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/destinations")
@RequiredArgsConstructor
public class DestinationController {

    private final DestinationRepository destinationRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<DestinationDto>>> getAllDestinations() {
        List<DestinationDto> data = destinationRepository.findAll().stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Fetched destinations"));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DestinationDto>> getDestinationById(@PathVariable Long id) {
        return destinationRepository.findById(id)
                .map(destination -> ResponseEntity.ok(ApiResponse.success(toDto(destination), "Fetched destination")))
                .orElseGet(() -> ResponseEntity.status(404)
                        .body(ApiResponse.error("Destination not found")));
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<DestinationDto>>> search(@RequestParam("q") String query) {
        List<DestinationDto> data = destinationRepository
                .findByTitleContainingIgnoreCaseOrRegionContainingIgnoreCase(query, query)
                .stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Search results"));
    }

    @GetMapping("/latest")
    public ResponseEntity<ApiResponse<List<DestinationDto>>> latest(@RequestParam(defaultValue = "10") int limit) {
        if (limit < 1) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Limit must be >= 1"));
        }
        List<DestinationDto> data = destinationRepository
                .findAllByOrderByIdDesc(PageRequest.of(0, limit))
                .stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Latest destinations"));
    }

    @GetMapping("/by-category/{name}")
    public ResponseEntity<ApiResponse<List<DestinationDto>>> byCategory(@PathVariable String name) {
        List<DestinationDto> data = destinationRepository.findByCategory_NameIgnoreCase(name).stream()
                .map(this::toDto)
                .toList();
        return ResponseEntity.ok(ApiResponse.success(data, "Destinations by category"));
    }

    private DestinationDto toDto(Destination destination) {
        Long categoryId = null;
        String categoryName = null;
        if (destination.getCategory() != null) {
            categoryId = destination.getCategory().getId();
            categoryName = destination.getCategory().getName();
        }

        return DestinationDto.builder()
                .id(destination.getId())
                .title(destination.getTitle())
                .subtitle(destination.getSubtitle())
                .description(destination.getDescription())
                .imageUrl(destination.getImageUrl())
                .region(destination.getRegion())
                .price(destination.getPrice())
                .rating(destination.getRating())
                .reviewCount(destination.getReviewCount())
                .categoryId(categoryId)
                .categoryName(categoryName)
                .tags(destination.getTags())
                .build();
    }
}
