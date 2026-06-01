package com.vn.huit.travelApp.service;

import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserRepository userRepository;

    @Value("${app.admin-emails:}")
    private String adminEmails;

    public User getUserInfo(String username) {
        return userRepository.findByUsername(username).orElse(null);
    }

    public User syncUser(String uid, String email, String displayName, String photoUrl) {
        User user = userRepository.findByUsername(uid).orElse(null);
        User.Role desiredRole = isAdminEmail(email) ? User.Role.ADMIN : User.Role.USER;
        if (user == null) {
            user = User.builder()
                    .username(uid)
                    .email(email)
                    .fullName(displayName)
                    .avatarUrl(photoUrl)
                    .role(desiredRole)
                    .build();
        } else {
            if (displayName != null && !displayName.isEmpty()) user.setFullName(displayName);
            if (photoUrl != null && !photoUrl.isEmpty()) user.setAvatarUrl(photoUrl);
            if (email != null && !email.isEmpty()) user.setEmail(email);
            if (desiredRole == User.Role.ADMIN || user.getRole() == null) {
                user.setRole(desiredRole);
            }
        }
        return userRepository.save(user);
    }

    private boolean isAdminEmail(String email) {
        if (email == null || email.isBlank() || adminEmails == null || adminEmails.isBlank()) {
            return false;
        }
        String normalized = email.trim().toLowerCase(Locale.ROOT);
        return Arrays.stream(adminEmails.split(","))
                .map(item -> item.trim().toLowerCase(Locale.ROOT))
                .anyMatch(normalized::equals);
    }

    public User updateUserProfile(String username, String fullName, MultipartFile avatar) throws IOException {
        User user = userRepository.findByUsername(username).orElse(null);
        if (user == null) return null;

        if (fullName != null && !fullName.trim().isEmpty()) {
            user.setFullName(fullName);
        }

        if (avatar != null && !avatar.isEmpty()) {
            String uploadDir = "uploads/avatars/";
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            String originalFilename = avatar.getOriginalFilename();
            String extension = originalFilename != null && originalFilename.contains(".") 
                ? originalFilename.substring(originalFilename.lastIndexOf(".")) 
                : ".jpg";
            String newFilename = UUID.randomUUID().toString() + extension;
            Path filePath = uploadPath.resolve(newFilename);
            
            Files.copy(avatar.getInputStream(), filePath, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            String avatarUrl = "/uploads/avatars/" + newFilename;
            user.setAvatarUrl(avatarUrl);
        }

        return userRepository.save(user);
    }
}
