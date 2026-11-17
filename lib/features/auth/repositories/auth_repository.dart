import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

/// Contrato del repositorio de autenticación
abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  UserProfile? get currentUser;
  Future<void> initialize();
  Future<UserProfile> signInWithEmailPassword(String email, String password);
  Future<UserProfile> registerWithEmailPassword(
      String name, String email, String password);
  Future<UserProfile> signInWithGoogle();
  Future<UserProfile> signInAsGuest();
  Future<void> updatePreferences(DietaryPreferences prefs);
  Future<void> toggleFavorite(String recipeId);
  Future<void> acceptPrivacyConsent();
  Future<void> signOut();
}

/// Implementación local persistente con SharedPreferences
/// Permite probar la aplicación de inmediato sin depender de conexión externa a Firebase.
class LocalAuthRepository implements AuthRepository {
  static const String _userKey = 'comiapp_user_profile';
  static const String _onboardingCompleteKey = 'comiapp_onboarding_completed';

  final _uuid = const Uuid();
  final _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromJson(userJson);
      } catch (_) {
        _currentUser = null;
      }
    }
    _authController.add(_currentUser);
  }

  Future<void> _saveUser(UserProfile? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_userKey);
    } else {
      await prefs.setString(_userKey, user.toJson());
    }
    _currentUser = user;
    _authController.add(user);
  }

  @override
  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Por favor ingresa un correo electrónico válido');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final user = UserProfile(
      id: _currentUser?.id ?? _uuid.v4(),
      name: email.split('@').first,
      email: email.trim(),
      preferences: _currentUser?.preferences ?? const DietaryPreferences(),
      favoriteRecipeIds: _currentUser?.favoriteRecipeIds ?? [],
      hasAcceptedPrivacyConsent: _currentUser?.hasAcceptedPrivacyConsent ?? false,
      createdAt: _currentUser?.createdAt ?? DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> registerWithEmailPassword(
      String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (name.trim().isEmpty) {
      throw Exception('Por favor ingresa tu nombre');
    }
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Por favor ingresa un correo electrónico válido');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres');
    }

    final user = UserProfile(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.trim(),
      preferences: const DietaryPreferences(),
      favoriteRecipeIds: const [],
      hasAcceptedPrivacyConsent: false,
      createdAt: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 700));

    final user = UserProfile(
      id: _uuid.v4(),
      name: 'Chef Google Demo',
      email: 'chef.demo@google.com',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      preferences: const DietaryPreferences(
        experience: CookingExperience.intermedio,
      ),
      hasAcceptedPrivacyConsent: true,
      createdAt: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<UserProfile> signInAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final user = UserProfile(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Cocinero Invitado',
      email: 'invitado@comiapp.local',
      preferences: const DietaryPreferences(
        experience: CookingExperience.principiante,
      ),
      hasAcceptedPrivacyConsent: true,
      createdAt: DateTime.now(),
    );

    await _saveUser(user);
    return user;
  }

  @override
  Future<void> updatePreferences(DietaryPreferences prefs) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(preferences: prefs);
    await _saveUser(updated);
  }

  @override
  Future<void> toggleFavorite(String recipeId) async {
    if (_currentUser == null) return;
    final currentFavorites = List<String>.from(_currentUser!.favoriteRecipeIds);
    if (currentFavorites.contains(recipeId)) {
      currentFavorites.remove(recipeId);
    } else {
      currentFavorites.add(recipeId);
    }
    final updated = _currentUser!.copyWith(favoriteRecipeIds: currentFavorites);
    await _saveUser(updated);
  }

  @override
  Future<void> acceptPrivacyConsent() async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(hasAcceptedPrivacyConsent: true);
    await _saveUser(updated);
  }

  @override
  Future<void> signOut() async {
    await _saveUser(null);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }
}
