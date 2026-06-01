package com.vn.huit.travelApp.service;

import com.vn.huit.travelApp.entity.User;
import com.vn.huit.travelApp.repository.UserRepository;
import com.vn.huit.travelApp.security.FirebaseUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AuthenticatedUserService {

    private final UserRepository userRepository;

    public FirebaseUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null ||
                !authentication.isAuthenticated() ||
                !(authentication.getPrincipal() instanceof FirebaseUserPrincipal principal)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authentication is required");
        }
        return principal;
    }

    public User currentUser() {
        FirebaseUserPrincipal principal = currentPrincipal();
        return userRepository.findByUsername(principal.uid())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User is not synced"));
    }

    public boolean isAdmin() {
        return currentPrincipal().isAdmin();
    }

    public void requireSelfOrAdmin(String username) {
        FirebaseUserPrincipal principal = currentPrincipal();
        if (!principal.isAdmin() && !principal.uid().equals(username)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not authorized");
        }
    }

    public boolean canManage(User owner) {
        FirebaseUserPrincipal principal = currentPrincipal();
        return principal.isAdmin() || (owner != null && principal.uid().equals(owner.getUsername()));
    }
}
