package com.vn.huit.travelApp.config;

import com.vn.huit.travelApp.entity.Category;
import com.vn.huit.travelApp.entity.Destination;
import com.vn.huit.travelApp.entity.Favorite;
import com.vn.huit.travelApp.entity.Review;
import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.repository.CategoryRepository;
import com.vn.huit.travelApp.repository.DestinationRepository;
import com.vn.huit.travelApp.repository.FavoriteRepository;
import com.vn.huit.travelApp.repository.ReviewRepository;
import com.vn.huit.travelApp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

@Configuration
@RequiredArgsConstructor
public class DataSeeder {

    private final CategoryRepository categoryRepository;
    private final DestinationRepository destinationRepository;
    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final FavoriteRepository favoriteRepository;

    @Bean
    public CommandLineRunner initData() {
        return args -> {
            Map<String, Category> categories = ensureCategories();
            List<Destination> destinations = ensureDestinations(categories);
            List<User> users = ensureUsers();
            ensureReviews(destinations);
            ensureFavorites(destinations, users);
        };
    }

    private Map<String, Category> ensureCategories() {
        if (categoryRepository.count() == 0) {
            Category bien = Category.builder().name("Biển").icon("beach_access").build();
            Category nui = Category.builder().name("Núi").icon("terrain").build();
            Category amThuc = Category.builder().name("Ẩm thực").icon("restaurant").build();
            Category thanhPho = Category.builder().name("Thành phố").icon("location_city").build();
            categoryRepository.saveAll(List.of(bien, nui, amThuc, thanhPho));
        }
        List<Category> all = categoryRepository.findAll();
        Map<String, Category> map = new HashMap<>();
        for (Category category : all) {
            map.put(category.getName(), category);
        }
        return map;
    }

    private List<Destination> ensureDestinations(Map<String, Category> categories) {
        long existing = destinationRepository.count();
        int target = 50;
        if (existing < target) {
            int missing = (int) (target - existing);
            List<Destination> newItems = new ArrayList<>();

            String[] regions = { "Miền Bắc", "Miền Trung", "Miền Nam" };
            String[] subtitles = {
                    "Cảnh sắc tuyệt đẹp", "Trải nghiệm văn hóa", "Nghỉ dưỡng cuối tuần",
                    "Ẩm thực đặc sắc", "Thiên nhiên hoang sơ"
            };
            String[] descriptions = {
                    "Điểm đến nổi bật với cảnh quan thiên nhiên và trải nghiệm địa phương.",
                    "Không khí trong lành, phù hợp cho chuyến đi gia đình.",
                    "Kết hợp giữa nghỉ dưỡng và khám phá văn hóa bản địa.",
                    "Cảnh đẹp, ẩm thực phong phú, dịch vụ thân thiện.",
                    "Một hành trình đáng nhớ với nhiều hoạt động ngoài trời."
            };
            String[] tags = {
                    "Tự nhiên,Trải nghiệm", "Nghỉ dưỡng,Ẩm thực", "Văn hóa,Khám phá",
                    "Biển,Thư giãn", "Núi,Chụp ảnh"
            };
            String[] images = {
                    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800",
                    "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800",
                    "https://images.unsplash.com/photo-1528127269322-539801943592?w=800",
                    "https://images.unsplash.com/photo-1540611025311-01df3cee54b5?w=800",
                    "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=800",
                    "https://images.unsplash.com/photo-1570366583862-f91883984fde?w=800"
            };
            Category[] categoryPool = {
                    categories.get("Biển"),
                    categories.get("Núi"),
                    categories.get("Ẩm thực"),
                    categories.get("Thành phố")
            };

            for (int i = 0; i < missing; i++) {
                int index = (int) existing + i + 1;
                Destination destination = Destination.builder()
                        .title("Diem den " + index)
                        .subtitle(subtitles[i % subtitles.length])
                        .description(descriptions[i % descriptions.length])
                        .imageUrl(images[i % images.length])
                        .region(regions[i % regions.length])
                        .category(categoryPool[i % categoryPool.length])
                        .price(900000.0 + (i % 8) * 200000.0)
                        .tags(tags[i % tags.length])
                        .build();
                newItems.add(destination);
            }
            destinationRepository.saveAll(newItems);
        }
        return destinationRepository.findAll();
    }

    private List<User> ensureUsers() {
        long existing = userRepository.count();
        int target = 25;
        if (existing < target) {
            List<User> users = new ArrayList<>();
            for (int i = (int) existing + 1; i <= target; i++) {
                users.add(User.builder()
                        .username("user" + i)
                        .password("password123")
                        .email("user" + i + "@example.com")
                        .fullName("User " + i)
                        .avatarUrl("https://i.pravatar.cc/150?img=" + ((i % 70) + 1))
                        .role(User.Role.USER)
                        .build());
            }
            userRepository.saveAll(users);
        }
        return userRepository.findAll();
    }

    private void ensureReviews(List<Destination> destinations) {
        long existing = reviewRepository.count();
        int target = 30;
        if (existing >= target) {
            return;
        }
        int missing = (int) (target - existing);
        String[] names = { "Minh Tran", "Linh Nguyen", "Huy Pham", "Anh Le", "Thanh Vo", "Tuan Ngo", "Lan Pham" };
        String[] comments = {
                "Cảnh đẹp, dịch vụ tốt.",
                "Trải nghiệm đáng nhớ.",
                "Không khí dễ chịu và đồ ăn ngon.",
                "Rất đáng để quay lại.",
                "Tuyệt vời cho kỳ nghỉ cuối tuần."
        };

        Random random = new Random(42);
        List<Review> newReviews = new ArrayList<>();
        for (int i = 0; i < missing; i++) {
            Destination destination = destinations.get(random.nextInt(destinations.size()));
            Review review = Review.builder()
                    .authorName(names[i % names.length])
                    .avatarUrl("https://i.pravatar.cc/150?img=" + ((i % 70) + 1))
                    .rating(3 + random.nextInt(3))
                    .comment(comments[i % comments.length])
                    .createdAt(LocalDateTime.now().minusDays(random.nextInt(60) + 1))
                    .destination(destination)
                    .build();
            newReviews.add(review);
        }
        reviewRepository.saveAll(newReviews);

        for (Destination destination : destinations) {
            List<Review> reviews = reviewRepository.findByDestination_IdOrderByCreatedAtDesc(destination.getId());
            if (reviews.isEmpty()) {
                continue;
            }
            int count = reviews.size();
            int sum = reviews.stream().mapToInt(Review::getRating).sum();
            destination.setReviewCount(count);
            destination.setRating(sum / (double) count);
        }
        destinationRepository.saveAll(destinations);
    }

    private void ensureFavorites(List<Destination> destinations, List<User> users) {
        long existing = favoriteRepository.count();
        int target = 30;
        if (existing >= target || users.isEmpty()) {
            return;
        }
        Random random = new Random(24);
        int attempts = 0;
        while (favoriteRepository.count() < target && attempts < target * 5) {
            User user = users.get(random.nextInt(users.size()));
            Destination destination = destinations.get(random.nextInt(destinations.size()));
            if (!favoriteRepository.existsByUserIdAndDestination_Id(user.getUsername(), destination.getId())) {
                favoriteRepository.save(Favorite.builder()
                        .userId(user.getUsername())
                        .destination(destination)
                        .build());
            }
            attempts++;
        }
    }
}
