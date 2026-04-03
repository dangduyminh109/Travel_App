package vn.com.huit.travelapp.auth;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.google.firebase.auth.FirebaseUser;
import vn.com.huit.travelapp.MainActivity;
import vn.com.huit.travelapp.R;

public class AuthActivity extends AppCompatActivity {

    private EditText etEmail;
    private EditText etPassword;
    private EditText etDisplayName;
    private Button btnSubmit;
    private TextView tvToggleMode;
    private ProgressBar progressBar;
    private AuthManager authManager;
    private boolean isLoginMode = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_auth);

        authManager = new AuthManager(this);

        if (authManager.getCurrentUser() != null) {
            navigateToMain();
            return;
        }

        etEmail = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);
        etDisplayName = findViewById(R.id.etDisplayName);
        btnSubmit = findViewById(R.id.btnSubmit);
        tvToggleMode = findViewById(R.id.tvToggleMode);
        progressBar = findViewById(R.id.progressBar);

        updateUI();

        btnSubmit.setOnClickListener(v -> handleSubmit());
        tvToggleMode.setOnClickListener(v -> {
            isLoginMode = !isLoginMode;
            updateUI();
        });
    }

    private void updateUI() {
        if (isLoginMode) {
            btnSubmit.setText("Dang nhap");
            tvToggleMode.setText("Chua co tai khoan? Dang ky");
            etDisplayName.setVisibility(View.GONE);
        } else {
            btnSubmit.setText("Dang ky");
            tvToggleMode.setText("Da co tai khoan? Dang nhap");
            etDisplayName.setVisibility(View.VISIBLE);
        }
    }

    private void handleSubmit() {
        String email = etEmail.getText().toString().trim();
        String password = etPassword.getText().toString().trim();

        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Vui long nhap day du thong tin.", Toast.LENGTH_SHORT).show();
            return;
        }

        setLoading(true);

        if (isLoginMode) {
            authManager.login(email, password, new AuthManager.AuthCallback() {
                @Override
                public void onSuccess(FirebaseUser user) {
                    setLoading(false);
                    navigateToMain();
                }

                @Override
                public void onFailure(String errorMessage) {
                    setLoading(false);
                    Toast.makeText(AuthActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                }
            });
        } else {
            String displayName = etDisplayName.getText().toString().trim();
            if (displayName.isEmpty()) {
                setLoading(false);
                Toast.makeText(this, "Vui long nhap ten hien thi.", Toast.LENGTH_SHORT).show();
                return;
            }
            authManager.register(email, password, displayName, new AuthManager.AuthCallback() {
                @Override
                public void onSuccess(FirebaseUser user) {
                    setLoading(false);
                    navigateToMain();
                }

                @Override
                public void onFailure(String errorMessage) {
                    setLoading(false);
                    Toast.makeText(AuthActivity.this, errorMessage, Toast.LENGTH_LONG).show();
                }
            });
        }
    }

    private void setLoading(boolean isLoading) {
        progressBar.setVisibility(isLoading ? View.VISIBLE : View.GONE);
        btnSubmit.setEnabled(!isLoading);
    }

    private void navigateToMain() {
        startActivity(new Intent(this, MainActivity.class));
        finish();
    }
}
