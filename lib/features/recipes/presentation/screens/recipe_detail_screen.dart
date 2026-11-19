import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_profile.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../widgets/portion_selector.dart';
import '../widgets/dietary_badge.dart';
import '../../../cooking/presentation/screens/cooking_mode_screen.dart';
import '../../../cooking/providers/cooking_session_provider.dart';
import '../../../cooking/providers/timer_provider.dart';
import '../../../ai_assistant/providers/ai_chef_provider.dart';
import '../../../ai_assistant/presentation/screens/ai_chef_modal.dart';
import '../../../ai_assistant/presentation/widgets/ai_permissions_dialog.dart';
import '../../../ai_assistant/services/ai_context_builder.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final void Function(BuildContext context, Recipe recipe, int portions)?
      onStartCooking;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    this.onStartCooking,
  });

  @override
  Widget build(BuildContext context) {
    final recipeProv = context.watch<RecipeProvider>();
    final authProv = context.watch<AuthProvider>();
    final portions = recipeProv.currentPortions;
    final isFav = authProv.user?.favoriteRecipeIds.contains(recipe.id) ?? false;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: CustomScrollView(
        slivers: [
          // AppBar colapsable con imagen
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primaryTeal,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            actions: [
              if (recipe.isCustom)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.errorCoral),
                      tooltip: 'Eliminar receta',
                      onPressed: () => _confirmDelete(context, recipe),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.errorCoral : AppColors.textDark,
                    ),
                    onPressed: () {
                      authProv.toggleFavorite(recipe.id);
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.mintSoft,
                      child: const Center(
                        child: Icon(Icons.restaurant_rounded,
                            size: 80, color: AppColors.primaryTeal),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Badges de tiempo y dificultad
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (recipe.isCustom)
                        DietaryBadge(
                          label: 'Tu Receta',
                          backgroundColor: AppColors.accentOrange,
                          textColor: Colors.white,
                        ),
                      DietaryBadge(
                        label: '${recipe.prepTimeMinutes} minutos',
                        backgroundColor: AppColors.highlightYellow,
                      ),
                      DietaryBadge(
                        label: recipe.difficulty.label,
                        backgroundColor: AppColors.mintSoft,
                      ),
                      if (recipe.isVegetarian)
                        const DietaryBadge(label: 'Vegetariano'),
                      if (recipe.isGlutenFree)
                        const DietaryBadge(label: 'Sin Gluten'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Título
                  Text(
                    recipe.title,
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 10),

                  // Descripción
                  Text(
                    recipe.description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selector de porciones interactivo
                  Center(
                    child: PortionSelector(
                      portions: portions,
                      onIncrement: () => recipeProv.incrementPortions(),
                      onDecrement: () => recipeProv.decrementPortions(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Lista de ingredientes reescalados
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: AppColors.outlineDark, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.outlineDark.withValues(alpha: 0.08),
                          offset: const Offset(3, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.egg_alt_outlined,
                                color: AppColors.primaryTeal),
                            const SizedBox(width: 10),
                            Text(
                              'Ingredientes ($portions ${portions == 1 ? 'porción' : 'porciones'})',
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...recipe.ingredients.map((ing) {
                          final formattedQty = ing.getFormattedQuantity(
                            recipe.defaultPortions,
                            portions,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6.0),
                                  child: Icon(Icons.check_circle_rounded,
                                      size: 16, color: AppColors.primaryTeal),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ing.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSoft,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.outlineDark,
                                        width: 1.2),
                                  ),
                                  child: Text(
                                    formattedQty,
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.primaryDarkTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Pasos de preparación resumidos
                  Text(
                    'Pasos a seguir (${recipe.steps.length})',
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...recipe.steps.map((step) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: AppColors.outlineDark, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.highlightYellow,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${step.stepNumber}',
                                style: AppTypography.titleMedium
                                    .copyWith(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: AppTypography.titleMedium
                                      .copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step.instruction,
                                  style: AppTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (step.hasTimer) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined,
                                          size: 15,
                                          color: AppColors.primaryTeal),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Temporizador: ${step.timerMinutes} min (${step.timerLabel ?? ''})',
                                        style: AppTypography.badge.copyWith(
                                          color: AppColors.primaryDarkTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 90), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.creamBackground,
          border: const Border(
            top: BorderSide(color: AppColors.outlineDark, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.outlineDark.withValues(alpha: 0.1),
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () {
              if (onStartCooking != null) {
                onStartCooking!(context, recipe, portions);
              } else {
                final sessionProv = context.read<CookingSessionProvider>();
                final timerProv = context.read<TimerProvider>();
                final aiProv = context.read<AiChefProvider>();
                final authProv = context.read<AuthProvider>();

                aiProv.onNextStepRequested = () => sessionProv.nextStep();
                aiProv.onPreviousStepRequested = () => sessionProv.previousStep();
                aiProv.onStartTimerRequested = (name, minutes) {
                  final step = sessionProv.currentStep;
                  timerProv.startTimer(
                    label: name,
                    recipeId: recipe.id,
                    stepId: step?.id ?? 'voice_timer',
                    minutes: minutes,
                  );
                };
                aiProv.onCancelTimerRequested = (name) {
                  final match = timerProv.timers.firstWhere(
                    (t) => t.label.toLowerCase().contains(name.toLowerCase()),
                    orElse: () => timerProv.timers.first,
                  );
                  timerProv.cancelTimer(match.id);
                };

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CookingModeScreen(
                      recipe: recipe,
                      portions: portions,
                      onOpenAiChef: () async {
                        final granted =
                            await AiPermissionsDialog.requestConsent(context);
                        if (!granted || !context.mounted) return;

                        final currentStep =
                            sessionProv.currentStep ?? recipe.steps.first;
                        final cookingCtx = AiCookingContext(
                          recipe: recipe,
                          currentStep: currentStep,
                          portions: portions,
                          activeTimers: timerProv.timers,
                          preferences: authProv.user?.preferences ??
                              const DietaryPreferences(),
                        );
                        aiProv.startSession(cookingCtx);
                        if (context.mounted) {
                          AiChefModal.show(context);
                        }
                      },
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.outdoor_grill_rounded, size: 24),
            label: const Text('Empezar a cocinar'),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Recipe recipe) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¿Eliminar receta?'),
        content: Text(
            '¿Seguro que deseas eliminar "${recipe.title}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context
                  .read<RecipeProvider>()
                  .deleteCustomRecipe(recipe.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Receta "${recipe.title}" eliminada.'),
                    backgroundColor: AppColors.errorCoral,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.errorCoral),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
