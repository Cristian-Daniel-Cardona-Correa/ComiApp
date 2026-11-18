import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

/// Implementación local persistente con SharedPreferences.
/// Registra usuarios reales: el correo y contraseña se almacenan de forma segura
/// (hash XOR simple — sin red — hasta integrar Firebase Auth real).
class LocalAuthRepository implements AuthRepository {
  static const String _sessionKey = 'comiapp_session_user';
  static const String _usersDbKey = 'comiapp_users_db';
  static const String _onboardingCompleteKey = 'comiapp_onboarding_completed';

  final _uuid = const Uuid();
  final _authController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  @override
  Stream<UserProfile?> get authStateChanges => _authController.stream;

  @override
  UserProfile? get currentUser => _currentUser;

  // ─── Inicialización ────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    if (sessionJson != null) {
      try {
        _currentUser = UserProfile.fromJson(sessionJson);
      } catch (_) {
        _currentUser = null;
      }
    }

    // Restaurar desde Firebase Auth si la sesión local está vacía
    if (_currentUser == null) {
      try {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          final email = fbUser.email ?? 'usuario@google.com';
          final db = await _loadUsersDb();
          if (db.containsKey(email)) {
            try {
              _currentUser = UserProfile.fromMap(
                  Map<String, dynamic>.from(db[email]!['profile'] as Map));
            } catch (_) {
              _currentUser = _buildGoogleUser(
                  email, fbUser.displayName ?? 'Usuario', fbUser.photoURL);
            }
          } else {
            _currentUser = _buildGoogleUser(
                email, fbUser.displayName ?? 'Usuario', fbUser.photoURL);
          }
          await _saveSession(_currentUser);
        }
      } catch (e) {
        debugPrint('Error restaurando sesión de Firebase: $e');
      }
    }

    _authController.add(_currentUser);
  }

  // ─── Persistencia de sesión activa ─────────────────────────────────────────

  Future<void> _saveSession(UserProfile? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, user.toJson());
      await prefs.setBool(_onboardingCompleteKey, true);
    }
    _currentUser = user;
    _authController.add(user);
  }

  // ─── Base de datos local de usuarios registrados ───────────────────────────

  Future<Map<String, Map<String, dynamic>>> _loadUsersDb() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersDbKey);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveUsersDb(Map<String, Map<String, dynamic>> db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersDbKey, json.encode(db));
  }

  /// Hash simplísimo (XOR + base64) solo para no guardar contraseñas en texto plano.
  /// En producción con Firebase Auth esto no se necesita — Firebase lo gestiona.
  String _hashPassword(String password) {
    const salt = 'comiApp2024!';
    final combined = password + salt;
    final bytes = combined.codeUnits;
    final hashed = bytes.map((b) => b ^ 42).toList();
    return base64.encode(hashed);
  }

  // ─── Autenticación por email ───────────────────────────────────────────────

  @override
  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final emailClean = email.trim().toLowerCase();
    if (emailClean.isEmpty) {
      throw Exception('El correo electrónico es obligatorio.');
    }
    if (password.isEmpty) {
      throw Exception('La contraseña es obligatoria.');
    }

    final db = await _loadUsersDb();
    final record = db[emailClean];

    if (record == null) {
      throw Exception(
          'No existe ninguna cuenta con ese correo. ¿Quieres registrarte?');
    }

    final storedHash = record['passwordHash'] as String? ?? '';
    if (_hashPassword(password) != storedHash) {
      throw Exception('Contraseña incorrecta. Verifica e inténtalo de nuevo.');
    }

    // Cargar perfil guardado y actualizar sesión
    UserProfile user;
    try {
      user = UserProfile.fromMap(Map<String, dynamic>.from(record['profile'] as Map));
    } catch (_) {
      throw Exception('Error al cargar tu perfil. Contacta soporte.');
    }

    await _saveSession(user);
    return user;
  }

  // ─── Registro ─────────────────────────────────────────────────────────────

  @override
  Future<UserProfile> registerWithEmailPassword(
      String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final emailClean = email.trim().toLowerCase();

    if (name.trim().length < 2) {
      throw Exception('El nombre debe tener al menos 2 caracteres.');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(emailClean)) {
      throw Exception('Ingresa un correo electrónico válido.');
    }
    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final db = await _loadUsersDb();
    if (db.containsKey(emailClean)) {
      throw Exception(
          'Ya existe una cuenta con ese correo. ¿Quieres iniciar sesión?');
    }

    final user = UserProfile(
      id: _uuid.v4(),
      name: name.trim(),
      email: emailClean,
      preferences: const DietaryPreferences(),
      favoriteRecipeIds: const [],
      hasAcceptedPrivacyConsent: false,
      createdAt: DateTime.now(),
    );

    db[emailClean] = {
      'passwordHash': _hashPassword(password),
      'profile': user.toMap(),
    };
    await _saveUsersDb(db);
    await _saveSession(user);
    return user;
  }

  // ─── Actualizar perfil en la BD local ──────────────────────────────────────

  Future<void> _syncUserToDb(UserProfile user) async {
    final db = await _loadUsersDb();
    final key = user.email.toLowerCase();
    if (db.containsKey(key)) {
      db[key]!['profile'] = user.toMap();
      await _saveUsersDb(db);
    }
  }

  // ─── Google Sign-In Oficial con Firebase Auth ────────────────────────────

  @override
  Future<UserProfile> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo nativo oficial de selección de cuenta de Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw 'Inicio de sesión con Google cancelado por el usuario';
      }

      // 2. Obtener los detalles de autenticación del request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear una nueva credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase con la credencial de Google
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      final targetEmail =
          firebaseUser?.email ?? googleUser.email.toLowerCase();
      final targetName = firebaseUser?.displayName ??
          googleUser.displayName ??
          'Usuario de Google';
      final photoUrl = firebaseUser?.photoURL ?? googleUser.photoUrl;

      final db = await _loadUsersDb();
      UserProfile user;
      if (db.containsKey(targetEmail)) {
        try {
          user = UserProfile.fromMap(
              Map<String, dynamic>.from(db[targetEmail]!['profile'] as Map));
          user = user.copyWith(
            name: targetName,
            photoUrl: photoUrl ?? user.photoUrl,
          );
          db[targetEmail]!['profile'] = user.toMap();
          await _saveUsersDb(db);
        } catch (_) {
          user = _buildGoogleUser(targetEmail, targetName, photoUrl);
        }
      } else {
        user = _buildGoogleUser(targetEmail, targetName, photoUrl);
        db[targetEmail] = {
          'passwordHash': _hashPassword(_uuid.v4()),
          'profile': user.toMap(),
        };
        await _saveUsersDb(db);
      }

      await _saveSession(user);
      return user;
    } catch (e) {
      debugPrint('[comiAPP Auth] Error en signInWithGoogle oficial: $e');
      rethrow;
    }
  }

  UserProfile _buildGoogleUser(String email, String name, String? photoUrl) =>
      UserProfile(
        id: _uuid.v4(),
        name: name,
        email: email,
        photoUrl: photoUrl ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        preferences: const DietaryPreferences(
          experience: CookingExperience.intermedio,
        ),
        hasAcceptedPrivacyConsent: false,
        createdAt: DateTime.now(),
      );

  // ─── Invitado ──────────────────────────────────────────────────────────────

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

    await _saveSession(user);
    return user;
  }

  // ─── Preferencias y favoritos ──────────────────────────────────────────────

  @override
  Future<void> updatePreferences(DietaryPreferences prefs) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(preferences: prefs);
    await _saveSession(updated);
    await _syncUserToDb(updated);
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
    await _saveSession(updated);
    await _syncUserToDb(updated);
  }

  @override
  Future<void> acceptPrivacyConsent() async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(hasAcceptedPrivacyConsent: true);
    await _saveSession(updated);
    await _syncUserToDb(updated);
  }

  // ─── Cierre de sesión ──────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _saveSession(null);
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
}
