import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  List<Map<String, dynamic>> _trustedContacts = [];

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get trustedContacts => _trustedContacts;

  bool get isHROrAdmin =>
      _currentUser?.role == 'hr' || _currentUser?.role == 'admin';

  /// True if user is signed in anonymously
  bool get isAnonymous =>
      FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

  /// True if user is properly signed in (not anonymous)
  bool get isSignedIn =>
      _currentUser != null && !isAnonymous;

  String get userId => _currentUser?.userId ?? '';
  String get displayName => _currentUser?.name ?? 'User';

  void _setStatus(AuthStatus s) {
    _status = s;
    notifyListeners();
  }

  /// Listen to Firebase auth state changes
  void initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _currentUser = await _authService.getUserModel(user.uid);
        _currentUser ??= UserModel(
          userId: user.uid,
          name: user.displayName ?? (user.isAnonymous ? 'Anonymous User' : 'User'),
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
        if (!user.isAnonymous) {
          await _loadTrustedContacts(user.uid);
        }
        _setStatus(AuthStatus.authenticated);
      } else {
        _currentUser = null;
        _trustedContacts = [];
        _setStatus(AuthStatus.unauthenticated);
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _setStatus(AuthStatus.loading);
    try {
      await _authService.signInWithEmailPassword(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String role = 'user',
  }) async {
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      _setStatus(AuthStatus.authenticated);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    _setStatus(AuthStatus.loading);
    try {
      _currentUser = await _authService.signInAnonymously();
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _errorMessage = 'Anonymous sign-in failed. Please try again.';
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _trustedContacts = [];
    _setStatus(AuthStatus.unauthenticated);
  }

  // ── Trusted Contacts (signed-in users only) ─────────────────────────

  Future<void> _loadTrustedContacts(String userId) async {
    _db.trustedContactsStream(userId).listen((contacts) {
      _trustedContacts = contacts;
      notifyListeners();
    });
  }

  /// Add a trusted contact — validates phone number format
  Future<String?> addTrustedContact({
    required String name,
    required String phone,
    String relation = 'Friend',
  }) async {
    if (isAnonymous) return 'Please login to add trusted contacts.';
    if (userId.isEmpty) return 'User not logged in.';

    // Validate Indian phone number (10 digits, optionally +91 prefix)
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(\+91)?[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid 10-digit Indian mobile number.';
    }

    await _db.saveTrustedContact(userId, {
      'name': name.trim(),
      'phone': cleanPhone.replaceAll('+91', ''),
      'relation': relation,
      'addedAt': DateTime.now().toIso8601String(),
    });
    return null; // null = success
  }

  /// Edit a trusted contact
  Future<String?> editTrustedContact({
    required String contactId,
    required String name,
    required String phone,
    String relation = 'Friend',
  }) async {
    if (isAnonymous) return 'Please login to edit contacts.';

    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(\+91)?[6-9]\d{9}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid 10-digit Indian mobile number.';
    }

    await _db.saveTrustedContact(userId, {
      'id': contactId,
      'name': name.trim(),
      'phone': cleanPhone.replaceAll('+91', ''),
      'relation': relation,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    return null;
  }

  /// Delete a trusted contact
  Future<void> deleteTrustedContact(String contactId) async {
    if (isAnonymous || userId.isEmpty) return;
    await _db.deleteTrustedContact(userId, contactId);
  }

  // ── Legacy method ───────────────────────────────────────────────────
  Future<void> updateTrustedContacts(List<TrustedContact> contacts) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(trustedContacts: contacts);
    await _authService.updateUserProfile(updated);
    _currentUser = updated;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'email-already-in-use': return 'Email is already registered.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Invalid email address.';
      case 'too-many-requests': return 'Too many attempts. Please try later.';
      case 'invalid-credential': return 'Invalid email or password.';
      default: return 'Authentication failed. Please try again.';
    }
  }
}
