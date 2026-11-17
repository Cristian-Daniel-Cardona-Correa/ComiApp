import 'ingredient.dart';
import 'cooking_step.dart';

/// Dificultad de la receta
enum RecipeDifficulty {
  facil,
  medio,
  dificil,
}

extension RecipeDifficultyExt on RecipeDifficulty {
  String get label {
    switch (this) {
      case RecipeDifficulty.facil:
        return 'Fácil';
      case RecipeDifficulty.medio:
        return 'Medio';
      case RecipeDifficulty.dificil:
        return 'Avanzado';
    }
  }

  static RecipeDifficulty fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'medio':
        return RecipeDifficulty.medio;
      case 'dificil':
      case 'avanzado':
        return RecipeDifficulty.dificil;
      case 'facil':
      default:
        return RecipeDifficulty.facil;
    }
  }
}

/// Modelo completo de Receta de comiAPP
class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int prepTimeMinutes;
  final RecipeDifficulty difficulty;
  final int defaultPortions;
  final List<String> dietaryTags;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final List<Ingredient> ingredients;
  final List<CookingStep> steps;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.difficulty,
    this.defaultPortions = 2,
    this.dietaryTags = const [],
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    required this.ingredients,
    required this.steps,
  });

  /// Busca un paso por su identificador único
  CookingStep? getStepById(String stepId) {
    try {
      return steps.firstWhere((s) => s.id == stepId);
    } catch (_) {
      return null;
    }
  }

  /// Retorna los ingredientes vinculados a un paso específico
  List<Ingredient> getIngredientsForStep(CookingStep step) {
    if (step.relevantIngredientIds.isEmpty) return [];
    return ingredients
        .where((ing) => step.relevantIngredientIds.contains(ing.id))
        .toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'prepTimeMinutes': prepTimeMinutes,
      'difficulty': difficulty.name,
      'defaultPortions': defaultPortions,
      'dietaryTags': dietaryTags,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'steps': steps.map((s) => s.toMap()).toList(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      prepTimeMinutes: map['prepTimeMinutes'] as int? ?? 30,
      difficulty: RecipeDifficultyExt.fromString(map['difficulty'] as String?),
      defaultPortions: map['defaultPortions'] as int? ?? 2,
      dietaryTags: List<String>.from(map['dietaryTags'] ?? const []),
      isVegetarian: map['isVegetarian'] as bool? ?? false,
      isVegan: map['isVegan'] as bool? ?? false,
      isGlutenFree: map['isGlutenFree'] as bool? ?? false,
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((item) => Ingredient.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
      steps: (map['steps'] as List<dynamic>?)
              ?.map((item) =>
                  CookingStep.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          const [],
    );
  }
}
