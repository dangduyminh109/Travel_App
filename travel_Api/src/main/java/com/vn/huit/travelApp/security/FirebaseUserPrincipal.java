package com.vn.huit.travelApp.security;

import com.vn.huit.travelApp.entity.User;

public record FirebaseUserPrincipal(
        String uid,
        String email,
        String name,
        User.Role role
) {
    public boolean isAdmin() {
        return role == User.Role.ADMIN;
    }
}
