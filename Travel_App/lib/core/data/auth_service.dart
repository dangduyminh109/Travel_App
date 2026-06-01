import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_local_service.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final AuthLocalService _local = AuthLocalService();
  static const Duration _authTimeout = Duration(seconds: 20);
  static const Duration _syncTimeout = Duration(seconds: 6);

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  /// Lấy thông tin user session đã lưu local (bao gồm photoUrl)
  Future<Map<String, dynamic>?> getUserSession() async {
    return _local.getUser();
  }

  Future<void> refreshLocalSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    final session = await _local.getUser();
    final provider = (session?['provider'] as String?) ?? 'firebase';
    await _local.saveUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      provider: provider,
      photoUrl: user.photoURL,
      role: (session?['role'] as String?) ?? 'USER',
    );
  }

  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password)
        .timeout(_authTimeout);
    final user = credential.user;
    if (user == null) {
      return null;
    }
    await user.updateDisplayName(displayName).timeout(_authTimeout);
    await user.reload().timeout(_authTimeout);
    var role = 'USER';
    try {
      final synced = await ApiService()
          .syncUser(uid: user.uid, email: email, displayName: displayName)
          .timeout(_syncTimeout);
      role = synced['role'] as String? ?? 'USER';
    } catch (_) {
      // Ignored for resilience
    }
    await _local.saveUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      provider: 'password',
      role: role,
    );
    return _firebaseAuth.currentUser;
  }

  Future<User?> login({required String email, required String password}) async {
    final credential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password)
        .timeout(_authTimeout);
    final user = credential.user;
    if (user == null) {
      return null;
    }
    var role = 'USER';
    try {
      final synced = await ApiService()
          .syncUser(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName ?? '',
            photoUrl: user.photoURL,
          )
          .timeout(_syncTimeout);
      role = synced['role'] as String? ?? 'USER';
    } catch (_) {
      // Ignored
    }
    await _local.saveUser(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName ?? '',
      provider: 'password',
      photoUrl: user.photoURL,
      role: role,
    );
    return user;
  }

  Future<User?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn().timeout(_authTimeout);
    if (account == null) {
      return null; // User cancelled
    }
    final auth = await account.authentication.timeout(_authTimeout);
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final userCredential = await _firebaseAuth
        .signInWithCredential(credential)
        .timeout(_authTimeout);
    final user = userCredential.user;
    if (user == null) {
      return null;
    }
    var role = 'USER';
    try {
      final synced = await ApiService()
          .syncUser(
            uid: user.uid,
            email: user.email ?? account.email,
            displayName: user.displayName ?? account.displayName ?? '',
            photoUrl: user.photoURL ?? account.photoUrl,
          )
          .timeout(_syncTimeout);
      role = synced['role'] as String? ?? 'USER';
    } catch (_) {
      // Ignored
    }
    await _local.saveUser(
      uid: user.uid,
      email: user.email ?? account.email,
      displayName: user.displayName ?? account.displayName ?? '',
      provider: 'google',
      photoUrl: user.photoURL ?? account.photoUrl,
      role: role,
    );
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    await _local.clear();
  }
}
