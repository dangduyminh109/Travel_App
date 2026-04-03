package vn.com.huit.travelapp.data;

import android.content.Context;
import vn.com.huit.travelapp.adapter.DestinationAdapter;
import vn.com.huit.travelapp.database.FavoritesHelper;
import vn.com.huit.travelapp.model.Destination;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.QueryDocumentSnapshot;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DataManager {

    private final FirebaseFirestore firestore;
    private final FavoritesHelper favoritesHelper;
    private final String currentUserId;

    public DataManager(Context context) {
        this.firestore = FirebaseFirestore.getInstance();
        this.favoritesHelper = new FavoritesHelper(context);
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        this.currentUserId = (user != null) ? user.getUid() : null;
    }

    public void listenToDestinations(DestinationAdapter adapter) {
        firestore.collection("destinations").addSnapshotListener((value, error) -> {
            if (error != null || value == null) {
                return;
            }
            List<Destination> list = new ArrayList<>();
            for (QueryDocumentSnapshot doc : value) {
                Destination destination = doc.toObject(Destination.class);
                destination.setId(doc.getId());
                list.add(destination);
            }
            adapter.updateData(list);
        });
    }

    public void handleFavoriteToggle(Destination destination) {
        if (currentUserId == null) {
            return;
        }
        String destId = destination.getId();
        if (favoritesHelper.isFavorite(destId, currentUserId)) {
            favoritesHelper.removeFavorite(destId, currentUserId);
            firestore.collection("users").document(currentUserId)
                    .collection("favorites").document(destId).delete();
        } else {
            favoritesHelper.addFavorite(destId, currentUserId);
            syncFavorites();
        }
    }

    public void syncFavorites() {
        if (currentUserId == null) {
            return;
        }
        List<String> unsynced = favoritesHelper.getUnsyncedFavorites(currentUserId);
        for (String destId : unsynced) {
            Map<String, Object> data = new HashMap<>();
            data.put("destinationId", destId);
            firestore.collection("users").document(currentUserId)
                    .collection("favorites").document(destId)
                    .set(data)
                    .addOnSuccessListener(aVoid -> favoritesHelper.updateSyncStatus(destId, currentUserId, 1));
        }
    }
}
