import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Implementación Firebase: Firebase Auth para autenticación + Firestore para perfiles.
/// Colección: `users/{uid}` guarda el perfil extendido del usuario.
class LocalAuthRepository implements AuthRepository {
  static const String _sessionKey = 'comiapp_session_user';
  static const String _onboardingCompleteKey = 'comiapp_onboarding_completed';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  bool _initialized = false;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  // ─── Inicialización ────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    if (_initialized) {
      _authController.add(_currentUser);
      return;
    }
    _initialized = true;

    try {
      final fbUser = _auth.currentUser;
      if (fbUser != null) {
        _currentUser = await _fetchOrCreateProfile(fbUser);
        await _cacheSession(_currentUser);
      } else {
        // Sin sesión de Firebase, intentar caché local para modo offline
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_sessionKey);
        if (cached != null) {
          try {
            _currentUser = UserProfile.fromJson(cached);
          } catch (_) {
            _currentUser = null;
          }
        }
      }
    } catch (e) {
      debugPrint('[comiAPP Auth] Error en initialize(): $e');
      _currentUser = null;
    }

    _authController.add(_currentUser);
  }

  // ─── Caché local (solo para restauración offline) ──────────────────────────

  Future<void> _cacheSession(UserProfile? user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user == null) {
        await prefs.remove(_sessionKey);
      } else {
        await prefs.setString(_sessionKey, user.toJson());
        await prefs.setBool(_onboardingCompleteKey, true);
      }
    } catch (_) {}
    _currentUser = user;
    _authController.add(user);
  }

  // ─── Firestore: obtener o crear perfil ────────────────────────────────────

  Future<UserProfile> _fetchOrCreateProfile(User fbUser,
      {String? displayName}) async {
    final uid = fbUser.uid;
    final doc = await _usersCol.doc(uid).get();

    if (doc.exists) {
      try {
        return UserProfile.fromFirestore(doc);
      } catch (e) {
        debugPrint('[comiAPP Auth] Error parseando perfil de Firestore: $e');
      }
    }

    // Crear perfil nuevo en Firestore
    final name =
        displayName ?? fbUser.displayName ?? fbUser.email?.split('@').first ?? 'Cocinero comiAPP';
    final profile = UserProfile(
      id: uid,
      name: name,
      email: fbUser.email ?? '',
      photoUrl: fbUser.photoURL,
      preferences: const DietaryPreferences(),
      favoriteRecipeIds: const [],
      hasAcceptedPrivacyConsent: false,
      createdAt: DateTime.now(),
    );
    await _usersCol.doc(uid).set(profile.toFirestore());
    return profile;
  }

  Future<void> _saveProfile(UserProfile profile) async {
    await _usersCol.doc(profile.id).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
    await _cacheSession(profile);
  }

  // ─── Autenticación por email/password ─────────────────────────────────────

  @override
  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    final emailClean = email.trim().toLowerCase();
    if (emailClean.isEmpty) throw Exception('El correo es obligatorio.');
    if (password.isEmpty) throw Exception('La contraseña es obligatoria.');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailClean,
        password: password,
      );
      final fbUser = credential.user!;
      final profile = await _fetchOrCreateProfile(fbUser);
      await _cacheSession(profile);
      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ─── Registro con email/password ──────────────────────────────────────────

  @override
  Future<UserProfile> registerWithEmailPassword(
      String name, String email, String password) async {
    if (name.trim().length < 2) {
      throw Exception('El nombre debe tener al menos 2 caracteres.');
    }
    final emailClean = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(emailClean)) {
      throw Exception('Ingresa un correo electrónico válido.');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailClean,
        password: password,
      );
      final fbUser = credential.user!;

      // Actualizar displayName en Firebase Auth
      await fbUser.updateDisplayName(name.trim());

      // Crear perfil en Firestore
      final profile = UserProfile(
        id: fbUser.uid,
        name: name.trim(),
        email: emailClean,
        photoUrl: null,
        preferences: const DietaryPreferences(),
        favoriteRecipeIds: const [],
        hasAcceptedPrivacyConsent: false,
        createdAt: DateTime.now(),
      );
      await _usersCol.doc(fbUser.uid).set(profile.toFirestore());
      await _cacheSession(profile);
      return profile;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn(
        serverClientId:
            '474523548597-c5fjh692tpjnhpqkgq64aca0fr53emp3.apps.googleusercontent.com',
      ).signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final fbUser = userCredential.user!;
      final profile = await _fetchOrCreateProfile(fbUser,
          displayName: googleUser.displayName);
      await _cacheSession(profile);
      return profile;
    } on PlatformException catch (e) {
      debugPrint('[comiAPP Auth] PlatformException Google: ${e.code} ${e.message}');
      if (e.message?.contains('10:') == true || e.code == 'sign_in_failed') {
        throw Exception(
            'Error de configuración de Google (Código 10): Registra la huella SHA-1 en la consola de Firebase.');
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  // ─── Invitado ──────────────────────────────────────────────────────────────

  @override
  Future<UserProfile> signInAsGuest() async {
    try {
      final credential = await _auth.signInAnonymously();
      final fbUser = credential.user!;
      final profile = UserProfile(
        id: fbUser.uid,
        name: 'Cocinero Invitado',
        email: '',
        preferences: const DietaryPreferences(
          experience: CookingExperience.principiante,
        ),
        favoriteRecipeIds: const [],
        hasAcceptedPrivacyConsent: true,
        createdAt: DateTime.now(),
      );
      // No guardamos perfil de invitado en Firestore (es anónimo)
      await _cacheSession(profile);
      return profile;
    } on FirebaseAuthException catch (e) {
      // Si Firebase anónimo no está habilitado, usar perfil local
      debugPrint('[comiAPP Auth] signInAnonymously falló: $e, usando perfil local');
      final profile = UserProfile(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Cocinero Invitado',
        email: '',
        preferences: const DietaryPreferences(
          experience: CookingExperience.principiante,
        ),
        favoriteRecipeIds: const [],
        hasAcceptedPrivacyConsent: true,
        createdAt: DateTime.now(),
      );
      await _cacheSession(profile);
      return profile;
    }
  }

  // ─── Preferencias y favoritos ──────────────────────────────────────────────

  @override
  Future<void> updatePreferences(DietaryPreferences prefs) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(preferences: prefs);
    await _saveProfile(updated);
  }

  @override
  Future<void> toggleFavorite(String recipeId) async {
    if (_currentUser == null) return;
    final favorites = List<String>.from(_currentUser!.favoriteRecipeIds);
    if (favorites.contains(recipeId)) {
      favorites.remove(recipeId);
    } else {
      favorites.add(recipeId);
    }
    final updated = _currentUser!.copyWith(favoriteRecipeIds: favorites);
    await _saveProfile(updated);
  }

  @override
  Future<void> acceptPrivacyConsent() async {
    if (_currentUser == null) {
      // Intentar cargar desde caché local
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString(_sessionKey);
        if (cached != null) _currentUser = UserProfile.fromJson(cached);
      } catch (_) {}
    }
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(hasAcceptedPrivacyConsent: true);
    await _saveProfile(updated);
  }

  // ─── Cierre de sesión ──────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try { await GoogleSignIn().signOut(); } catch (_) {}
    try { await _auth.signOut(); } catch (_) {}
    await _cacheSession(null);
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  // ─── Mapeo de errores de Firebase Auth ────────────────────────────────────

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese correo. ¿Quieres registrarte?';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Contraseña incorrecta. Verifica e inténtalo de nuevo.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo. ¿Quieres iniciar sesión?';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'Ingresa un correo electrónico válido.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'operation-not-allowed':
        return 'Este método de inicio de sesión no está habilitado. Actívalo en Firebase Console.';
      default:
        debugPrint('[comiAPP Auth] FirebaseAuthException: ${e.code} - ${e.message}');
        return 'Error de autenticación (${e.code}). Inténtalo de nuevo.';
    }
  }
}
