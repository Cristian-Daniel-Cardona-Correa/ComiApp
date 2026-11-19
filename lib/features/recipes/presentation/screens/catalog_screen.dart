import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'create_recipe_screen.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onOpenTimers;

  const CatalogScreen({super.key, this.onOpenTimers});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  static const String _favCategory = 'Favoritos';
  static const String _customCategory = 'Mis Recetas';

  final List<String> _categories = [
    'Todos',
    'Mis Recetas',
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
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Crear Receta',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreateRecipeScreen(),
                ),
              );
            },
          ),
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
                final isCustomChip = cat == _customCategory;
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
                      : (isCustomChip
                          ? Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryTeal,
                            )
                          : null),
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: isFavChip
                      ? AppColors.accentOrange
                      : (isCustomChip
                          ? AppColors.primaryTeal
                          : AppColors.accentOrange),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isFavChip
                        ? AppColors.accentOrange
                        : (isCustomChip
                            ? AppColors.primaryTeal
                            : AppColors.outlineDark),
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

          // Lista de recetas con soporte de Pull-to-Refresh
          Expanded(
            child: recipeProv.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.primaryTeal,
                    onRefresh: () => recipeProv.loadRecipes(forceRefresh: true),
                    child: displayedRecipes.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 400,
                              child: _buildEmptyState(
                                isFavorites: showingFavorites,
                                isCustom:
                                    recipeProv.selectedCategory == _customCategory,
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required bool isFavorites,
    required bool isCustom,
  }) {
    if (isCustom) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 72, color: AppColors.primaryTeal),
              const SizedBox(height: 16),
              Text('Aún no tienes recetas propias',
                  style: AppTypography.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Crea tus recetas caseras personalizadas con sus pasos y temporizadores.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateRecipeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear mi primera receta'),
              ),
            ],
          ),
        ),
      );
    }
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
