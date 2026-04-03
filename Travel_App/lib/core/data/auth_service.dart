import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_local_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final AuthLocalService _local = AuthLocalService();

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
    );
  }

  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      return null;
    }
    await user.updateDisplayName(displayName);
    await user.reload();
    await _local.saveUser(
      uid: user.uid,
      email: email,
      displayName: displayName,
      provider: 'password',
    );
    return _firebaseAuth.currentUser;
  }

  Future<User?> login({required String email, required String password}) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      return null;
    }
    await _local.saveUser(
      uid: user.uid,
      email: user.email ?? email,
      displayName: user.displayName ?? '',
      provider: 'password',
      photoUrl: user.photoURL,
    );
    return user;
  }

  Future<User?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null; // User cancelled
    }
    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      return null;
    }
    await _local.saveUser(
      uid: user.uid,
      email: user.email ?? account.email,
      displayName: user.displayName ?? account.displayName ?? '',
      provider: 'google',
      photoUrl: user.photoURL ?? account.photoUrl,
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
