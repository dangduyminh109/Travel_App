package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Destination;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Pageable;
import java.util.List;

public interface DestinationRepository extends JpaRepository<Destination, Long> {
    List<Destination> findByTitleContainingIgnoreCaseOrRegionContainingIgnoreCase(String title, String region);

    List<Destination> findAllByOrderByIdDesc(Pageable pageable);

    List<Destination> findByCategory_NameIgnoreCase(String name);
}
