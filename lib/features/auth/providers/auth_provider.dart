import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Proveedor de estado de autenticación y perfil de usuario
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  UserProfile? _user;

  AuthProvider(this._repository) {
    _init();
  }

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserProfile? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> _init() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _repository.initialize();
    _user = _repository.currentUser;
    _status = _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();

    _repository.authStateChanges.listen((updatedUser) {
      _user = updatedUser;
      _status = updatedUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    return _handleAuth(() => _repository.signInWithEmailPassword(email, password));
  }

  Future<bool> register(String name, String email, String password) async {
    return _handleAuth(
        () => _repository.registerWithEmailPassword(name, email, password));
  }

  Future<bool> signInWithGoogle() async {
    return _handleAuth(() => _repository.signInWithGoogle());
  }

  Future<bool> signInAsGuest() async {
    return _handleAuth(() => _repository.signInAsGuest());
  }

  Future<void> updatePreferences(DietaryPreferences prefs) async {
    try {
      await _repository.updatePreferences(prefs);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    try {
      await _repository.toggleFavorite(recipeId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> acceptPrivacyConsent() async {
    try {
      await _repository.acceptPrivacyConsent();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _status = AuthStatus.loading;
    notifyListeners();
    await _repository.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _handleAuth(Future<UserProfile> Function() action) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await action();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
