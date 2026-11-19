import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeRepository _repository;
  StreamSubscription<User?>? _authSubscription;

  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  Recipe? _selectedRecipe;
  int _currentPortions = 2;

  RecipeProvider(this._repository) {
    loadRecipes();
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        debugPrint('[comiAPP RecipeProvider] Cambio en sesión de usuario (UID: ${user?.uid}). Sincronizando recetas...');
        loadRecipes(forceRefresh: true);
      });
    } catch (e) {
      debugPrint('[comiAPP RecipeProvider] authStateChanges no disponible en este entorno: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  List<Recipe> get recipes => _recipes;
  List<Recipe> get filteredRecipes => _filteredRecipes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Recipe? get selectedRecipe => _selectedRecipe;
  int get currentPortions => _currentPortions;

  Future<void> loadRecipes({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    _recipes = await _repository.getAllRecipes(forceRefresh: forceRefresh);
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  Future<void> addCustomRecipe(Recipe recipe) async {
    _isLoading = true;
    notifyListeners();

    await _repository.saveCustomRecipe(recipe);
    _recipes = await _repository.getAllRecipes(forceRefresh: true);
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCustomRecipe(String recipeId) async {
    _isLoading = true;
    notifyListeners();

    await _repository.deleteCustomRecipe(recipeId);
    _recipes = await _repository.getAllRecipes(forceRefresh: true);
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  void selectRecipe(Recipe recipe) {
    _selectedRecipe = recipe;
    _currentPortions = recipe.defaultPortions;
    notifyListeners();
  }

  void setPortions(int portions) {
    if (portions < 1 || portions > 20) return;
    _currentPortions = portions;
    notifyListeners();
  }

  void incrementPortions() {
    if (_currentPortions < 20) {
      _currentPortions++;
      notifyListeners();
    }
  }

  void decrementPortions() {
    if (_currentPortions > 1) {
      _currentPortions--;
      notifyListeners();
    }
  }

  void _applyFilters() {
    final cleanQuery = _searchQuery.trim().toLowerCase();

    _filteredRecipes = _recipes.where((recipe) {
      // Filtro por búsqueda de texto
      if (cleanQuery.isNotEmpty) {
        final inTitle = recipe.title.toLowerCase().contains(cleanQuery);
        final inDesc = recipe.description.toLowerCase().contains(cleanQuery);
        final inTags = recipe.dietaryTags
            .any((t) => t.toLowerCase().contains(cleanQuery));
        if (!inTitle && !inDesc && !inTags) return false;
      }

      // Filtro por categoría seleccionada
      if (_selectedCategory == 'Mis Recetas' && !recipe.isCustom) {
        return false;
      }
      if (_selectedCategory == 'Vegetariano' && !recipe.isVegetarian) {
        return false;
      }
      if (_selectedCategory == 'Vegano' && !recipe.isVegan) {
        return false;
      }
      if (_selectedCategory == 'Sin Gluten' && !recipe.isGlutenFree) {
        return false;
      }
      if (_selectedCategory == 'Rápido' && recipe.prepTimeMinutes > 25) {
        return false;
      }

      return true;
    }).toList();
  }
}
