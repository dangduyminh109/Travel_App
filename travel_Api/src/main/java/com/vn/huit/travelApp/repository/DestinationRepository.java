package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Destination;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import java.util.List;
import java.util.Optional;

public interface DestinationRepository extends JpaRepository<Destination, Long>, JpaSpecificationExecutor<Destination> {
    List<Destination> findByTitleContainingIgnoreCaseOrRegionContainingIgnoreCase(String title, String region);

    List<Destination> findAllByOrderByIdDesc(Pageable pageable);

    List<Destination> findByCategory_NameIgnoreCase(String name);

    List<Destination> findByTitleIgnoreCase(String title);

    Optional<Destination> findFirstByTitleIgnoreCaseAndCityIgnoreCase(String title, String city);
}
