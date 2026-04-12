package com.vn.huit.travelApp.repository;

import com.vn.huit.travelApp.entity.Reply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReplyRepository extends JpaRepository<Reply, Long> {
    List<Reply> findByReview_IdOrderByCreatedAtAsc(Long reviewId);
}
