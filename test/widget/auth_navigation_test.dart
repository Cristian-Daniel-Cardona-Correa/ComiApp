import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/features/auth/models/user_profile.dart';
import 'package:comiapp/features/auth/presentation/screens/login_screen.dart';
import 'package:comiapp/features/auth/providers/auth_provider.dart';
import 'package:comiapp/features/auth/repositories/auth_repository.dart';
import 'package:comiapp/features/recipes/providers/recipe_provider.dart';
import 'package:comiapp/features/recipes/repositories/recipe_repository.dart';
import 'package:comiapp/features/cooking/providers/timer_provider.dart';
import 'package:comiapp/features/cooking/providers/cooking_session_provider.dart';
import 'package:comiapp/features/cooking/repositories/cooking_repository.dart';
import 'package:comiapp/features/cooking/services/notification_service.dart';
import 'package:comiapp/features/ai_assistant/providers/ai_chef_provider.dart';

/// Repositorio de autenticación falso para tests (sin Firebase ni red)
class _MockAuthRepository implements AuthRepository {
  final _ctrl = StreamController<UserProfile?>.broadcast();
  UserProfile? _user;

  // Simula usuarios registrados en memoria
  final Map<String, String> _db = {};

  @override
  Stream<UserProfile?> get authStateChanges => _ctrl.stream;

  @override
  UserProfile? get currentUser => _user;

  @override
  Future<void> initialize() async {
    _ctrl.add(_user);
  }

  @override
  Future<UserProfile> signInWithEmailPassword(
      String email, String password) async {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) throw Exception('El correo es obligatorio.');
    if (password.isEmpty) throw Exception('La contraseña es obligatoria.');
    if (!_db.containsKey(key)) {
      throw Exception(
          'No existe ninguna cuenta con ese correo. ¿Quieres registrarte?');
    }
    if (_db[key] != password) {
      throw Exception('Contraseña incorrecta. Verifica e inténtalo de nuevo.');
    }
    _user = UserProfile(
      id: 'test_uid',
      name: 'Test User',
      email: key,
      preferences: const DietaryPreferences(),
      createdAt: DateTime.now(),
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<UserProfile> registerWithEmailPassword(
      String name, String email, String password) async {
    final key = email.trim().toLowerCase();
    _db[key] = password;
    _user = UserProfile(
      id: 'test_uid',
      name: name,
      email: key,
      preferences: const DietaryPreferences(),
      createdAt: DateTime.now(),
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<UserProfile> signInWithGoogle() async =>
      throw UnimplementedError('Not needed in tests');

  @override
  Future<UserProfile> signInAsGuest() async {
    _user = UserProfile(
      id: 'guest_test',
      name: 'Cocinero Invitado',
      email: '',
      preferences: const DietaryPreferences(
        experience: CookingExperience.principiante,
      ),
      hasAcceptedPrivacyConsent: true,
      createdAt: DateTime.now(),
    );
    _ctrl.add(_user);
    return _user!;
  }

  @override
  Future<void> updatePreferences(DietaryPreferences prefs) async {
    if (_user == null) return;
    _user = _user!.copyWith(preferences: prefs);
    _ctrl.add(_user);
  }

  @override
  Future<void> toggleFavorite(String recipeId) async {
    if (_user == null) return;
    final favs = List<String>.from(_user!.favoriteRecipeIds);
    if (favs.contains(recipeId)) {
      favs.remove(recipeId);
    } else {
      favs.add(recipeId);
    }
    _user = _user!.copyWith(favoriteRecipeIds: favs);
    _ctrl.add(_user);
  }

  @override
  Future<void> acceptPrivacyConsent() async {
    if (_user == null) return;
    _user = _user!.copyWith(hasAcceptedPrivacyConsent: true);
    _ctrl.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _ctrl.add(null);
  }
}

Widget _buildApp() {
  final authRepo = _MockAuthRepository();
  final recipeRepo = LocalRecipeRepository();
  final cookingRepo = CookingRepository();
  final notificationService = LocalCookingNotificationService();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
      ChangeNotifierProvider(create: (_) => RecipeProvider(recipeRepo)),
      ChangeNotifierProvider(
        create: (_) => TimerProvider(
          repository: cookingRepo,
          notificationService: notificationService,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => CookingSessionProvider(repository: cookingRepo),
      ),
      ChangeNotifierProvider(
        create: (_) => AiChefProvider(),
      ),
    ],
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen guest login navigates to home shell',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Tu cocina inteligente, siempre contigo'), findsOneWidget);
    final guestButton = find.textContaining('Entrar como invitado');
    expect(guestButton, findsOneWidget);

    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    // After guest login → HomeShell should be visible
    expect(find.text('Tu cocina inteligente, siempre contigo'), findsNothing);
    expect(find.text('La Despensa'), findsWidgets);
    expect(find.text('Mis Tiempos'), findsWidgets);
    expect(find.text('Mi Perfil'), findsWidgets);
  });

  testWidgets('LoginScreen shows field errors when submitting empty form',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
    expect(loginButton, findsOneWidget);

    // Tap without filling fields → should show inline errors
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Should stay on login screen and show error messages
    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });

  testWidgets('LoginScreen shows error when credentials are wrong',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    // Enter invalid credentials
    await tester.enterText(find.byType(TextField).at(0), 'noexiste@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
    await tester.pumpAndSettle();

    // Should show snackbar with error
    expect(find.byType(SnackBar), findsOneWidget);
    // Should remain on login screen
    expect(find.text('Tu cocina inteligente, siempre contigo'), findsOneWidget);
  });
}
