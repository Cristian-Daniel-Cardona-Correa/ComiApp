import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> saveCustomRecipe(Recipe recipe);
  Future<void> deleteCustomRecipe(String recipeId);
  Future<List<Recipe>> getCustomRecipes();
}

class LocalRecipeRepository implements RecipeRepository {
  static const String _customRecipesKey = 'comiapp_custom_recipes';

  List<Recipe>? _cachedRecipes;
  List<Recipe> _customRecipes = [];
  bool _customLoaded = false;

  @override
  Future<List<Recipe>> getAllRecipes() async {
    if (_cachedRecipes == null || !_customLoaded) {
      await _loadCustomRecipes();
      _cachedRecipes = [..._customRecipes, ...InitialRecipes.recipes];
    }
    return _cachedRecipes!;
  }

  @override
  Future<List<Recipe>> getCustomRecipes() async {
    if (!_customLoaded) {
      await _loadCustomRecipes();
    }
    return List.unmodifiable(_customRecipes);
  }

  Future<void> _loadCustomRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customRecipesKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = json.decode(raw);
        _customRecipes = list
            .map((item) => Recipe.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('[comiAPP RecipeRepository] Error cargando recetas de SharedPreferences: $e');
    }

    // Sincronización secundaria con Firestore si hay usuario autenticado
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('custom_recipes')
            .get();

        if (snap.docs.isNotEmpty) {
          final cloudRecipes = snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return Recipe.fromMap(data);
          }).toList();

          // Mezclar sin duplicar
          for (final cloud in cloudRecipes) {
            final idx = _customRecipes.indexWhere((r) => r.id == cloud.id);
            if (idx >= 0) {
              _customRecipes[idx] = cloud;
            } else {
              _customRecipes.insert(0, cloud);
            }
          }
          await _saveCustomToLocal();
        }
      }
    } catch (e) {
      debugPrint('[comiAPP RecipeRepository] Firestore custom recipes sync: $e');
    }

    _customLoaded = true;
  }

  Future<void> _saveCustomToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _customRecipes.map((r) => r.toMap()).toList();
      await prefs.setString(_customRecipesKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('[comiAPP RecipeRepository] Error guardando en SharedPreferences: $e');
    }
  }

  @override
  Future<void> saveCustomRecipe(Recipe recipe) async {
    if (!_customLoaded) {
      await _loadCustomRecipes();
    }

    final idx = _customRecipes.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) {
      _customRecipes[idx] = recipe;
    } else {
      _customRecipes.insert(0, recipe);
    }

    // Actualizar cache global
    _cachedRecipes = [..._customRecipes, ...InitialRecipes.recipes];
    await _saveCustomToLocal();

    // Guardar en Firestore si hay usuario
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('custom_recipes')
            .doc(recipe.id)
            .set(recipe.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[comiAPP RecipeRepository] Error guardando receta en Firestore: $e');
    }
  }

  @override
  Future<void> deleteCustomRecipe(String recipeId) async {
    if (!_customLoaded) {
      await _loadCustomRecipes();
    }

    _customRecipes.removeWhere((r) => r.id == recipeId);
    _cachedRecipes = [..._customRecipes, ...InitialRecipes.recipes];
    await _saveCustomToLocal();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('custom_recipes')
            .doc(recipeId)
            .delete();
      }
    } catch (e) {
      debugPrint('[comiAPP RecipeRepository] Error eliminando de Firestore: $e');
    }
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
