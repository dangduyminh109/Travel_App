package vn.com.huit.travelapp.profile;

import android.net.Uri;
import android.os.Bundle;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.StorageReference;
import vn.com.huit.travelapp.R;
import vn.com.huit.travelapp.auth.AuthManager;

public class ProfileActivity extends AppCompatActivity {

    private ImageView ivAvatar;
    private TextView tvName;
    private TextView tvEmail;
    private Button btnLogout;
    private FirebaseAuth auth;
    private FirebaseFirestore firestore;
    private FirebaseStorage storage;
    private AuthManager authManager;
    private ActivityResultLauncher<String> imagePickerLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);

        auth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
        storage = FirebaseStorage.getInstance();
        authManager = new AuthManager(this);

        ivAvatar = findViewById(R.id.ivAvatar);
        tvName = findViewById(R.id.tvName);
        tvEmail = findViewById(R.id.tvEmail);
        btnLogout = findViewById(R.id.btnLogout);

        imagePickerLauncher = registerForActivityResult(
                new ActivityResultContracts.GetContent(),
                uri -> {
                    if (uri != null) {
                        ivAvatar.setImageURI(uri);
                        uploadImageToStorage(uri);
                    }
                });

        loadUserInfo();

        ivAvatar.setOnClickListener(v -> imagePickerLauncher.launch("image/*"));

        btnLogout.setOnClickListener(v -> {
            authManager.logout();
            finish();
        });
    }

    private void loadUserInfo() {
        FirebaseUser user = auth.getCurrentUser();
        if (user == null) {
            return;
        }
        tvEmail.setText(user.getEmail());
        firestore.collection("users").document(user.getUid())
                .get()
                .addOnSuccessListener(document -> {
                    if (document.exists()) {
                        String displayName = document.getString("displayName");
                        String photoUrl = document.getString("photoURL");
                        tvName.setText(displayName);
                        if (photoUrl != null && !photoUrl.isEmpty()) {
                            Glide.with(this)
                                    .load(photoUrl)
                                    .circleCrop()
                                    .into(ivAvatar);
                        }
                    }
                });
    }

    private void uploadImageToStorage(Uri imageUri) {
        FirebaseUser user = auth.getCurrentUser();
        if (user == null) {
            return;
        }
        String uid = user.getUid();
        StorageReference storageRef = storage.getReference().child("avatars/" + uid + ".jpg");

        storageRef.putFile(imageUri)
                .addOnSuccessListener(taskSnapshot -> storageRef.getDownloadUrl()
                        .addOnSuccessListener(uri -> updatePhotoUrl(uid, uri.toString()))
                        .addOnFailureListener(e -> showToast("Khong the lay URL anh.")))
                .addOnFailureListener(e -> showToast("Tai anh len that bai."));
    }

    private void updatePhotoUrl(String uid, String photoUrl) {
        firestore.collection("users").document(uid)
                .update("photoURL", photoUrl)
                .addOnSuccessListener(aVoid -> {
                    showToast("Cap nhat avatar thanh cong.");
                    Glide.with(this).load(photoUrl).circleCrop().into(ivAvatar);
                })
                .addOnFailureListener(e -> showToast("Cap nhat Firestore that bai."));
    }

    private void showToast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }
}
