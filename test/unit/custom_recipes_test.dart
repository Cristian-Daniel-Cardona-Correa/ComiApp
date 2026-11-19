import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comiapp/features/recipes/models/recipe.dart';
import 'package:comiapp/features/recipes/models/ingredient.dart';
import 'package:comiapp/features/recipes/models/cooking_step.dart';
import 'package:comiapp/features/recipes/repositories/recipe_repository.dart';
import 'package:comiapp/features/recipes/providers/recipe_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Custom Recipes and RecipeProvider Tests', () {
    late LocalRecipeRepository repository;
    late RecipeProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalRecipeRepository();
      provider = RecipeProvider(repository);
    });

    test('Recipe model supports isCustom attribute and fromMap parsing', () {
      final recipe = Recipe(
        id: 'custom_123',
        title: 'Mi Arepa Rellena',
        description: 'Arepa con queso y aguacate',
        imageUrl: '',
        prepTimeMinutes: 15,
        difficulty: RecipeDifficulty.facil,
        ingredients: const [
          Ingredient(id: 'i1', name: 'Harina de maíz', baseQuantity: 1, unit: 'taza'),
        ],
        steps: const [
          CookingStep(
            id: 's1',
            stepNumber: 1,
            title: 'Amasar',
            instruction: 'Mezclar agua y sal',
          ),
        ],
        isCustom: true,
      );

      expect(recipe.isCustom, isTrue);
      final map = recipe.toMap();
      expect(map['isCustom'], isTrue);
      expect(map['id'], 'custom_123');

      final parsed = Recipe.fromMap(map);
      expect(parsed.isCustom, isTrue);
      expect(parsed.title, 'Mi Arepa Rellena');
    });

    test('RecipeProvider filters custom recipes with "Mis Recetas" category', () async {
      await provider.loadRecipes();

      final customRecipe = Recipe(
        id: 'custom_999',
        title: 'Bandeja Paisa Casera',
        description: 'Hecha a mi manera',
        imageUrl: '',
        prepTimeMinutes: 45,
        difficulty: RecipeDifficulty.medio,
        ingredients: const [],
        steps: const [],
        isCustom: true,
      );

      await provider.addCustomRecipe(customRecipe);

      expect(provider.recipes.any((r) => r.id == 'custom_999'), isTrue);

      // Filtrar por Mis Recetas
      provider.selectCategory('Mis Recetas');
      expect(provider.filteredRecipes.every((r) => r.isCustom), isTrue);
      expect(provider.filteredRecipes.any((r) => r.id == 'custom_999'), isTrue);

      // Eliminar receta personalizada
      await provider.deleteCustomRecipe('custom_999');
      expect(provider.recipes.any((r) => r.id == 'custom_999'), isFalse);
    });
  });
}
