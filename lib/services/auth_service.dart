import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email & password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  /// Register with email & password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = AppConstants.roleUser,
    String? organizationId,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user!.updateDisplayName(name);

    final user = UserModel(
      userId: credential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
      organizationId: organizationId,
    );

    await _db
        .collection(AppConstants.colUsers)
        .doc(credential.user!.uid)
        .set(user.toMap());

    return user;
  }

  /// Sign in anonymously
  Future<UserModel> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = UserModel(
      userId: credential.user!.uid,
      name: 'Anonymous User',
      email: '',
      anonymousFlag: true,
      createdAt: DateTime.now(),
    );
    await _db
        .collection(AppConstants.colUsers)
        .doc(credential.user!.uid)
        .set(user.toMap());
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get user model from Firestore
  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  /// Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    await _db
        .collection(AppConstants.colUsers)
        .doc(user.userId)
        .update(user.toMap());
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Check if user is HR or Admin
  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['role'] ?? AppConstants.roleUser;
    }
    return AppConstants.roleUser;
  }
}
