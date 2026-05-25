package com.vn.huit.travelApp.service;

import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.repository.DestinationRepository;
import jakarta.persistence.criteria.JoinType;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class DestinationSearchService {
    private static final double EARTH_RADIUS_KM = 6371.0;
    private static final double DEFAULT_RADIUS_KM = 3.0;

    private final DestinationRepository destinationRepository;

    public List<SearchResult> search(SearchCriteria criteria) {
        SearchCriteria normalized = criteria.normalized();
        Destination origin = null;

        if (criteria.radiusKm() != null && criteria.radiusKm() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "radiusKm must be greater than 0");
        }

        if (normalized.nearId() != null) {
            origin = destinationRepository.findById(normalized.nearId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "nearId destination not found"));
            if (!hasCoordinates(origin)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "nearId destination does not have coordinates");
            }
        }

        String sortBy = normalized.effectiveSortBy();
        validateSortBy(sortBy);
        final Destination originDestination = origin;

        List<SearchResult> results = destinationRepository.findAll(buildSpecification(normalized)).stream()
                .filter(destination -> originDestination == null || !destination.getId().equals(originDestination.getId()))
                .map(destination -> new SearchResult(destination, calculateDistance(originDestination, destination)))
                .filter(result -> normalized.nearId() == null
                        || (result.distanceKm() != null && result.distanceKm() <= normalized.radiusKm()))
                .toList();

        return results.stream()
                .sorted(comparatorFor(sortBy))
                .toList();
    }

    private Specification<Destination> buildSpecification(SearchCriteria criteria) {
        Specification<Destination> spec = (root, query, cb) -> cb.conjunction();

        if (hasText(criteria.q())) {
            String keyword = "%" + criteria.q().toLowerCase(Locale.ROOT) + "%";
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.like(cb.lower(cb.coalesce(root.get("title"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("subtitle"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("description"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("region"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("city"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("district"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("address"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("tags"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("highlights"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.get("suitableFor"), "")), keyword),
                    cb.like(cb.lower(cb.coalesce(root.join("category", JoinType.LEFT).get("name"), "")), keyword)
            ));
        }

        if (hasText(criteria.city())) {
            spec = spec.and((root, query, cb) -> cb.or(
                    cb.equal(cb.lower(cb.coalesce(root.get("city"), "")), criteria.city().toLowerCase(Locale.ROOT)),
                    cb.equal(cb.lower(cb.coalesce(root.get("region"), "")), criteria.city().toLowerCase(Locale.ROOT))
            ));
        }

        if (hasText(criteria.district())) {
            spec = spec.and((root, query, cb) ->
                    cb.equal(cb.lower(cb.coalesce(root.get("district"), "")), criteria.district().toLowerCase(Locale.ROOT)));
        }

        if (hasText(criteria.placeType())) {
            spec = spec.and((root, query, cb) ->
                    cb.equal(cb.upper(cb.coalesce(root.get("placeType"), "")), criteria.placeType().toUpperCase(Locale.ROOT)));
        }

        if (hasText(criteria.priceLevel())) {
            spec = spec.and((root, query, cb) ->
                    cb.equal(cb.upper(cb.coalesce(root.get("priceLevel"), "")), criteria.priceLevel().toUpperCase(Locale.ROOT)));
        }

        if (hasText(criteria.category())) {
            spec = spec.and((root, query, cb) ->
                    cb.equal(cb.lower(cb.coalesce(root.join("category", JoinType.LEFT).get("name"), "")),
                            criteria.category().toLowerCase(Locale.ROOT)));
        }

        if (criteria.minRating() != null) {
            spec = spec.and((root, query, cb) ->
                    cb.greaterThanOrEqualTo(cb.coalesce(root.get("rating"), 0.0), criteria.minRating()));
        }

        return spec;
    }

    private Comparator<SearchResult> comparatorFor(String sortBy) {
        return switch (sortBy) {
            case "rating" -> Comparator
                    .comparing((SearchResult result) -> safeDouble(result.destination().getRating())).reversed()
                    .thenComparing(result -> safeInt(result.destination().getReviewCount()), Comparator.reverseOrder())
                    .thenComparing(result -> safeLong(result.destination().getId()), Comparator.reverseOrder());
            case "newest" -> Comparator.comparing(
                    (SearchResult result) -> safeLong(result.destination().getId()),
                    Comparator.reverseOrder());
            case "price_asc" -> Comparator
                    .comparing((SearchResult result) -> effectivePrice(result.destination()))
                    .thenComparing(result -> safeLong(result.destination().getId()), Comparator.reverseOrder());
            case "price_desc" -> Comparator
                    .comparing((SearchResult result) -> effectivePrice(result.destination()), Comparator.reverseOrder())
                    .thenComparing(result -> safeLong(result.destination().getId()), Comparator.reverseOrder());
            case "distance" -> Comparator
                    .comparing((SearchResult result) -> result.distanceKm() == null ? Double.MAX_VALUE : result.distanceKm())
                    .thenComparing(result -> safeLong(result.destination().getId()), Comparator.reverseOrder());
            default -> Comparator.comparing(
                    (SearchResult result) -> safeLong(result.destination().getId()),
                    Comparator.reverseOrder());
        };
    }

    private void validateSortBy(String sortBy) {
        if (!List.of("relevance", "rating", "newest", "price_asc", "price_desc", "distance").contains(sortBy)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid sortBy value");
        }
    }

    private Double calculateDistance(Destination origin, Destination destination) {
        if (origin == null || !hasCoordinates(destination)) {
            return null;
        }

        double originLat = Math.toRadians(origin.getLatitude());
        double destinationLat = Math.toRadians(destination.getLatitude());
        double deltaLat = Math.toRadians(destination.getLatitude() - origin.getLatitude());
        double deltaLng = Math.toRadians(destination.getLongitude() - origin.getLongitude());

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(originLat) * Math.cos(destinationLat)
                * Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return Math.round(EARTH_RADIUS_KM * c * 10.0) / 10.0;
    }

    private boolean hasCoordinates(Destination destination) {
        return destination.getLatitude() != null && destination.getLongitude() != null;
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private double safeDouble(Double value) {
        return value == null ? 0.0 : value;
    }

    private int safeInt(Integer value) {
        return value == null ? 0 : value;
    }

    private long safeLong(Long value) {
        return value == null ? 0 : value;
    }

    private long effectivePrice(Destination destination) {
        Long minPrice = destination.getMinPrice();
        Long maxPrice = destination.getMaxPrice();
        if (minPrice != null && minPrice > 0) return minPrice;
        if (maxPrice != null && maxPrice > 0) return maxPrice;
        if ("FREE".equalsIgnoreCase(destination.getPriceLevel())) return 0;
        return Long.MAX_VALUE;
    }

    public record SearchCriteria(
            String q,
            String city,
            String district,
            String placeType,
            String priceLevel,
            String category,
            Double minRating,
            Long nearId,
            Double radiusKm,
            String sortBy) {
        SearchCriteria normalized() {
            double effectiveRadius = radiusKm == null ? DEFAULT_RADIUS_KM : radiusKm;
            String effectiveSortBy = hasNearId() && !hasSortBy() ? "distance" : normalizedSortBy();
            return new SearchCriteria(
                    trimToNull(q),
                    trimToNull(city),
                    trimToNull(district),
                    trimToNull(placeType),
                    trimToNull(priceLevel),
                    trimToNull(category),
                    minRating,
                    nearId,
                    effectiveRadius,
                    effectiveSortBy);
        }

        String effectiveSortBy() {
            return normalizedSortBy() == null ? "relevance" : normalizedSortBy();
        }

        private boolean hasNearId() {
            return nearId != null;
        }

        private boolean hasSortBy() {
            return sortBy != null && !sortBy.isBlank();
        }

        private String normalizedSortBy() {
            return sortBy == null || sortBy.isBlank() ? null : sortBy.trim().toLowerCase(Locale.ROOT);
        }

        private static String trimToNull(String value) {
            if (value == null || value.isBlank()) {
                return null;
            }
            return value.trim();
        }
    }

    public record SearchResult(Destination destination, Double distanceKm) {
    }
}
