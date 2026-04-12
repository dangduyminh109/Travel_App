package com.vn.huit.travelApp.service;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@Slf4j
public class FirebaseRealtimeService {

    private DatabaseReference getRootRef() {
        return FirebaseDatabase.getInstance().getReference();
    }

    public void pushReview(Long destinationId, Map<String, Object> reviewData) {
        String reviewId = reviewData.get("id").toString();
        getRootRef().child("reviews_realtime")
                .child(destinationId.toString())
                .child(reviewId)
                .setValueAsync(reviewData);
    }

    public void pushReply(Long reviewId, Map<String, Object> replyData) {
        String replyId = replyData.get("id").toString();
        getRootRef().child("replies")
                .child(reviewId.toString())
                .child(replyId)
                .setValueAsync(replyData);
    }

    public void pushReaction(Long reviewId, String userId, String reactionType) {
        DatabaseReference likeRef = getRootRef().child("review_likes")
                .child(reviewId.toString())
                .child(userId);
        if ("NONE".equals(reactionType)) {
            likeRef.removeValueAsync();
        } else {
            likeRef.setValueAsync(reactionType); // "LIKE" or "DISLIKE"
        }
    }

    public void pushNotification(String title, String message, String type) {
        DatabaseReference notifRef = getRootRef().child("notifications").push();
        Map<String, Object> notifData = Map.of(
                "id", notifRef.getKey(),
                "title", title,
                "message", message,
                "type", type,
                "createdAt", System.currentTimeMillis()
        );
        notifRef.setValueAsync(notifData);
    }

    public void removeReview(Long destinationId, Long reviewId) {
        getRootRef().child("reviews_realtime")
                .child(destinationId.toString())
                .child(reviewId.toString())
                .removeValueAsync();
    }

    public void removeReply(Long reviewId, Long replyId) {
        getRootRef().child("replies")
                .child(reviewId.toString())
                .child(replyId.toString())
                .removeValueAsync();
    }
}
