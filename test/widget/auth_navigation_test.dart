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

Widget _buildApp() {
  final authRepo = LocalAuthRepository();
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
