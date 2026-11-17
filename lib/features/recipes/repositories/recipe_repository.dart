import 'dart:async';
import '../models/recipe.dart';
import '../data/initial_recipes.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> getAllRecipes();
  Future<Recipe?> getRecipeById(String id);
  Future<List<Recipe>> searchRecipes({
    String query = '',
    bool? vegetarianOnly,
    bool? veganOnly,
    bool? glutenFreeOnly,
  });
}

class LocalRecipeRepository implements RecipeRepository {
  List<Recipe>? _cachedRecipes;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    if (_cachedRecipes == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      _cachedRecipes = List.from(InitialRecipes.recipes);
    }
    return _cachedRecipes!;
  }

  @override
  Future<Recipe?> getRecipeById(String id) async {
    final list = await getAllRecipes();
    try {
      return list.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Recipe>> searchRecipes({
    String query = '',
    bool? vegetarianOnly,
    bool? veganOnly,
    bool? glutenFreeOnly,
  }) async {
    final list = await getAllRecipes();
    final cleanQuery = query.trim().toLowerCase();

    return list.where((recipe) {
      if (cleanQuery.isNotEmpty) {
        final matchesTitle = recipe.title.toLowerCase().contains(cleanQuery);
        final matchesDesc =
            recipe.description.toLowerCase().contains(cleanQuery);
        final matchesTag = recipe.dietaryTags
            .any((tag) => tag.toLowerCase().contains(cleanQuery));
        if (!matchesTitle && !matchesDesc && !matchesTag) {
          return false;
        }
      }

      if (vegetarianOnly == true && !recipe.isVegetarian) {
        return false;
      }
      if (veganOnly == true && !recipe.isVegan) {
        return false;
      }
      if (glutenFreeOnly == true && !recipe.isGlutenFree) {
        return false;
      }

      return true;
    }).toList();
  }
}
