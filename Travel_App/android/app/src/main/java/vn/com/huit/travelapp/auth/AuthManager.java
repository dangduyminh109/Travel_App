package vn.com.huit.travelapp.auth;

import android.content.Context;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import java.util.HashMap;
import java.util.Map;
import vn.com.huit.travelapp.database.DatabaseHelper;

public class AuthManager {

    private final FirebaseAuth firebaseAuth;
    private final FirebaseFirestore firestore;
    private final DatabaseHelper dbHelper;

    public interface AuthCallback {
        void onSuccess(FirebaseUser user);

        void onFailure(String errorMessage);
    }

    public AuthManager(Context context) {
        this.firebaseAuth = FirebaseAuth.getInstance();
        this.firestore = FirebaseFirestore.getInstance();
        this.dbHelper = new DatabaseHelper(context);
    }

    public void register(String email, String password, String displayName, AuthCallback callback) {
        firebaseAuth.createUserWithEmailAndPassword(email, password)
                .addOnSuccessListener(authResult -> {
                    FirebaseUser user = authResult.getUser();
                    if (user == null) {
                        callback.onFailure("Registration failed: user is null.");
                        return;
                    }
                    Map<String, Object> userData = new HashMap<>();
                    userData.put("uid", user.getUid());
                    userData.put("email", email);
                    userData.put("displayName", displayName);
                    userData.put("role", "user");

                    firestore.collection("users").document(user.getUid())
                            .set(userData)
                            .addOnSuccessListener(unused -> {
                                dbHelper.saveUser(user.getUid(), email, displayName, "user");
                                callback.onSuccess(user);
                            })
                            .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
                })
                .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
    }

    public void login(String email, String password, AuthCallback callback) {
        firebaseAuth.signInWithEmailAndPassword(email, password)
                .addOnSuccessListener(authResult -> {
                    FirebaseUser user = authResult.getUser();
                    if (user == null) {
                        callback.onFailure("Login failed: user is null.");
                        return;
                    }
                    firestore.collection("users").document(user.getUid())
                            .get()
                            .addOnSuccessListener(document -> {
                                if (document.exists()) {
                                    String displayName = document.getString("displayName");
                                    String role = document.getString("role");
                                    dbHelper.saveUser(user.getUid(), email, displayName, role);
                                }
                                callback.onSuccess(user);
                            })
                            .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
                })
                .addOnFailureListener(e -> callback.onFailure(e.getMessage()));
    }

    public void logout() {
        FirebaseUser user = firebaseAuth.getCurrentUser();
        if (user != null) {
            dbHelper.deleteUser(user.getUid());
        }
        firebaseAuth.signOut();
    }

    public FirebaseUser getCurrentUser() {
        return firebaseAuth.getCurrentUser();
    }
}
