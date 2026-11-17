import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/features/auth/presentation/screens/login_screen.dart';
import 'package:comiapp/features/auth/providers/auth_provider.dart';
import 'package:comiapp/features/auth/repositories/auth_repository.dart';
import 'package:comiapp/features/recipes/providers/recipe_provider.dart';
import 'package:comiapp/features/recipes/repositories/recipe_repository.dart';
import 'package:comiapp/features/cooking/providers/timer_provider.dart';
import 'package:comiapp/features/cooking/repositories/cooking_repository.dart';
import 'package:comiapp/features/cooking/services/notification_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen guest login navigates to home shell',
      (WidgetTester tester) async {
    final authRepo = LocalAuthRepository();
    final recipeRepo = LocalRecipeRepository();
    final cookingRepo = CookingRepository();
    final notificationService = LocalCookingNotificationService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
          ChangeNotifierProvider(create: (_) => RecipeProvider(recipeRepo)),
          ChangeNotifierProvider(
            create: (_) => TimerProvider(
              repository: cookingRepo,
              notificationService: notificationService,
            ),
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify LoginScreen is shown
    expect(find.text('Entra a tu cocina personalizada'), findsOneWidget);
    final guestButton = find.textContaining('Entrar como invitado');
    expect(guestButton, findsOneWidget);

    // Ensure visible and tap 'Entrar como invitado'
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    // Should navigate away from LoginScreen and show HomeShell (bottom navigation tabs)
    expect(find.text('Entra a tu cocina personalizada'), findsNothing);
    expect(find.text('La Despensa'), findsWidgets);
    expect(find.text('Mis Tiempos'), findsWidgets);
    expect(find.text('Mi Perfil'), findsWidgets);
  });

  testWidgets('LoginScreen email login navigates to privacy consent or home shell',
      (WidgetTester tester) async {
    final authRepo = LocalAuthRepository();
    final recipeRepo = LocalRecipeRepository();
    final cookingRepo = CookingRepository();
    final notificationService = LocalCookingNotificationService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
          ChangeNotifierProvider(create: (_) => RecipeProvider(recipeRepo)),
          ChangeNotifierProvider(
            create: (_) => TimerProvider(
              repository: cookingRepo,
              notificationService: notificationService,
            ),
          ),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Default email and password are prefilled in LoginScreen
    final loginButton = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // First time email user hasn't accepted privacy consent yet, so PrivacyConsentScreen is shown
    expect(find.text('Privacidad y Permisos'), findsOneWidget);
    expect(find.text('Aceptar y Continuar'), findsOneWidget);
  });
}
