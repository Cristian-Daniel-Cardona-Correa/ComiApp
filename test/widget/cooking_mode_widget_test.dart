import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/features/cooking/presentation/screens/cooking_mode_screen.dart';
import 'package:comiapp/features/cooking/providers/cooking_session_provider.dart';
import 'package:comiapp/features/cooking/providers/timer_provider.dart';
import 'package:comiapp/features/recipes/data/initial_recipes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('CookingModeScreen renders step instruction and advances',
      (WidgetTester tester) async {
    final recipe = InitialRecipes.recipes.first; // Pasta Carbonara

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TimerProvider()),
          ChangeNotifierProvider(create: (_) => CookingSessionProvider()),
        ],
        child: MaterialApp(
          home: CookingModeScreen(
            recipe: recipe,
            portions: 2,
          ),
        ),
      ),
    );

    // Permitir inicialización de frame
    await tester.pumpAndSettle();

    // Comprobar que aparece el primer paso
    expect(find.textContaining('Paso 1 de'), findsOneWidget);
    expect(find.text(recipe.steps.first.title), findsOneWidget);

    // Encontrar el botón de siguiente paso y pulsarlo
    final nextButton = find.text('Siguiente Paso');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Comprobar que avanzó al Paso 2
    expect(find.textContaining('Paso 2 de'), findsOneWidget);
    expect(find.text(recipe.steps[1].title), findsOneWidget);
  });
}
