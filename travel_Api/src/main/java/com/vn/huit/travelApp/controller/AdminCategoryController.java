package com.vn.huit.travelApp.controller;

import com.vn.huit.travelApp.dto.ApiResponse;
import com.vn.huit.travelApp.dto.CategoryDto;
import com.vn.huit.travelApp.entity.Category;
import com.vn.huit.travelApp.repository.CategoryRepository;
import com.vn.huit.travelApp.repository.DestinationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/categories")
@RequiredArgsConstructor
public class AdminCategoryController {

    private final CategoryRepository categoryRepository;
    private final DestinationRepository destinationRepository;

    @PostMapping
    public ResponseEntity<ApiResponse<CategoryDto>> create(@RequestBody CategoryDto request) {
        if (isBlank(request.getName())) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Category name is required"));
        }
        if (categoryRepository.findByName(request.getName().trim()).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(ApiResponse.error("Category already exists"));
        }
        Category category = Category.builder()
                .name(request.getName().trim())
                .icon(trimOrDefault(request.getIcon(), "category"))
                .build();
        Category saved = categoryRepository.save(category);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(toDto(saved), "Category created"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CategoryDto>> update(
            @PathVariable Long id,
            @RequestBody CategoryDto request
    ) {
        Category category = categoryRepository.findById(id).orElse(null);
        if (category == null) {
            return ResponseEntity.status(404).body(ApiResponse.error("Category not found"));
        }
        if (isBlank(request.getName())) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Category name is required"));
        }
        categoryRepository.findByName(request.getName().trim())
                .filter(existing -> !existing.getId().equals(id))
                .ifPresent(existing -> {
                    throw new CategoryConflictException();
                });
        category.setName(request.getName().trim());
        category.setIcon(trimOrDefault(request.getIcon(), "category"));
        return ResponseEntity.ok(ApiResponse.success(toDto(categoryRepository.save(category)), "Category updated"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        if (!categoryRepository.existsById(id)) {
            return ResponseEntity.status(404).body(ApiResponse.error("Category not found"));
        }
        if (destinationRepository.countByCategory_Id(id) > 0) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(ApiResponse.error("Cannot delete category that is used by destinations"));
        }
        categoryRepository.deleteById(id);
        return ResponseEntity.ok(ApiResponse.success(null, "Category deleted"));
    }

    @ExceptionHandler(CategoryConflictException.class)
    public ResponseEntity<ApiResponse<CategoryDto>> categoryConflict() {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(ApiResponse.error("Category already exists"));
    }

    private CategoryDto toDto(Category category) {
        return CategoryDto.builder()
                .id(category.getId())
                .name(category.getName())
                .icon(category.getIcon())
                .build();
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private String trimOrDefault(String value, String fallback) {
        return isBlank(value) ? fallback : value.trim();
    }

    private static class CategoryConflictException extends RuntimeException {
    }
}
