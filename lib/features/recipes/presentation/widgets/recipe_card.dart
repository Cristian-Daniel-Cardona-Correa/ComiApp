import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/recipe.dart';
import 'dietary_badge.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.outlineDark.withValues(alpha: 0.15),
              offset: const Offset(4, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con etiquetas encima
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: recipe.imageUrl.startsWith('http')
                      ? Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.mintSoft,
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  size: 64,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            );
                          },
                        )
                      : (recipe.imageUrl.isNotEmpty
                          ? Image.file(
                              File(recipe.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.mintSoft,
                                  child: const Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      size: 64,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.mintSoft,
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  size: 64,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            )),
                ),
                // Botón de favorito
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.outlineDark, width: 1.5),
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite
                              ? AppColors.errorCoral
                              : AppColors.textDark,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                // Badge de tiempo de preparación
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.highlightYellow,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.outlineDark, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 16, color: AppColors.textDark),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTimeMinutes} min',
                          style: AppTypography.badge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Contenido textual
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DietaryBadge(
                        label: recipe.difficulty.label,
                        backgroundColor: AppColors.mintSoft,
                      ),
                      const SizedBox(width: 8),
                      if (recipe.isVegetarian) ...[
                        const DietaryBadge(label: 'Veggie'),
                        const SizedBox(width: 8),
                      ],
                      if (recipe.isGlutenFree) ...[
                        const DietaryBadge(label: 'Sin Gluten'),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    recipe.title,
                    style: AppTypography.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.description,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${recipe.steps.length} pasos sencillos',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDarkTeal,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.accentOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
