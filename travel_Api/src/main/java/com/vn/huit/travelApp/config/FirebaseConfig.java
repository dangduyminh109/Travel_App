package com.vn.huit.travelApp.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.service-account-path:src/main/resources/serviceAccountKey.json}")
    private String serviceAccountPath;

    @Value("${firebase.database-url:}")
    private String databaseUrl;

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        FirebaseOptions options;
        try (FileInputStream serviceAccount = new FileInputStream(serviceAccountPath)) {
            FirebaseOptions.Builder optionsBuilder = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount));

            if (databaseUrl != null && !databaseUrl.isBlank()) {
                optionsBuilder.setDatabaseUrl(databaseUrl);
            }

            options = optionsBuilder.build();
        }

        if (FirebaseApp.getApps().isEmpty()) {
            return FirebaseApp.initializeApp(options);
        } else {
            return FirebaseApp.getInstance();
        }
    }
}
