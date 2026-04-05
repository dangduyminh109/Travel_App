package com.vn.huit.travelApp.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "favorites", uniqueConstraints = @UniqueConstraint(columnNames = { "user_id", "destination_id" }))
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Favorite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "username", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "destination_id", nullable = false)
    private Destination destination;
}
