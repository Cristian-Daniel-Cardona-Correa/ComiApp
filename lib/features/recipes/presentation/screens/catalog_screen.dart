import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onOpenTimers;

  const CatalogScreen({super.key, this.onOpenTimers});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  static const String _favCategory = 'Favoritos';

  final List<String> _categories = [
    'Todos',
    'Favoritos',
    'Vegetariano',
    'Vegano',
    'Sin Gluten',
    'Rápido',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipeProv = context.watch<RecipeProvider>();
    final authProv = context.watch<AuthProvider>();
    final favorites = authProv.user?.favoriteRecipeIds ?? [];
    final showingFavorites = recipeProv.selectedCategory == _favCategory;

    // Cuando el filtro es "Favoritos", filtramos por favoriteRecipeIds en la UI
    final displayedRecipes = showingFavorites
        ? recipeProv.filteredRecipes
            .where((r) => favorites.contains(r.id))
            .toList()
        : recipeProv.filteredRecipes;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('La Despensa'),
        actions: [
          if (widget.onOpenTimers != null)
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 28),
              tooltip: 'Mis Tiempos',
              onPressed: widget.onOpenTimers,
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => recipeProv.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: '¿Qué se te antoja cocinar hoy?...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.primaryTeal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          recipeProv.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Chips de categorías
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = recipeProv.selectedCategory == cat;
                final isFavChip = cat == _favCategory;
                return ChoiceChip(
                  avatar: isFavChip
                      ? Icon(
                          isSelected
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.accentOrange,
                        )
                      : null,
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: isFavChip
                      ? AppColors.accentOrange
                      : AppColors.accentOrange,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isFavChip
                        ? AppColors.accentOrange
                        : AppColors.outlineDark,
                    width: 1.5,
                  ),
                  labelStyle: AppTypography.badge.copyWith(
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      recipeProv.selectCategory(cat);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Lista de recetas
          Expanded(
            child: recipeProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  )
                : displayedRecipes.isEmpty
                    ? _buildEmptyState(showingFavorites)
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount: displayedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = displayedRecipes[index];
                          final isFav = favorites.contains(recipe.id);
                          return RecipeCard(
                            recipe: recipe,
                            isFavorite: isFav,
                            onFavoriteToggle: () {
                              authProv.toggleFavorite(recipe.id);
                            },
                            onTap: () {
                              recipeProv.selectRecipe(recipe);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isFavorites) {
    if (isFavorites) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite_border_rounded,
                  size: 72, color: AppColors.accentOrange),
              const SizedBox(height: 16),
              Text('Aún no tienes favoritas',
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Toca el ♥ en cualquier receta para guardarla aquí.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.primaryTeal),
            const SizedBox(height: 16),
            Text('No encontramos recetas', style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Prueba buscando con otro ingrediente o desmarcando los filtros.',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
