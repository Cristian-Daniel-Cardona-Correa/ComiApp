import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../screens/cooking_mode_screen.dart';
import '../../providers/cooking_session_provider.dart';
import '../../providers/timer_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/models/user_profile.dart';
import '../../../ai_assistant/providers/ai_chef_provider.dart';
import '../../../ai_assistant/presentation/screens/ai_chef_modal.dart';
import '../../../ai_assistant/presentation/widgets/ai_permissions_dialog.dart';
import '../../../ai_assistant/services/ai_context_builder.dart';

class ActiveCookingBanner extends StatelessWidget {
  const ActiveCookingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProv = Provider.of<CookingSessionProvider?>(context, listen: true);
    if (sessionProv == null) {
      return const SizedBox.shrink();
    }
    final recipe = sessionProv.currentRecipe;

    if (recipe == null) {
      return const SizedBox.shrink();
    }

    final currentStep = sessionProv.currentStep;
    final stepNum = sessionProv.currentStepIndex + 1;
    final total = recipe.steps.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineDark, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.outlineDark.withValues(alpha: 0.18),
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.outdoor_grill_rounded,
                  color: AppColors.primaryTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            recipe.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Paso $stepNum/$total • ${currentStep?.title ?? "En preparación"}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final timerProv = context.read<TimerProvider>();
                  final aiProv = context.read<AiChefProvider>();
                  final authProv = context.read<AuthProvider>();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CookingModeScreen(
                        recipe: recipe,
                        portions: sessionProv.portions,
                        onOpenAiChef: () async {
                          final granted =
                              await AiPermissionsDialog.requestConsent(context);
                          if (!granted || !context.mounted) return;

                          final cookingCtx = AiCookingContext(
                            recipe: recipe,
                            currentStep: sessionProv.currentStep ?? recipe.steps.first,
                            portions: sessionProv.portions,
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.highlightYellow,
                  foregroundColor: AppColors.textDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(
                      color: AppColors.outlineDark, width: 1.5),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Continuar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('¿Cerrar receta activa?'),
                      content: Text(
                          '¿Deseas finalizar la sesión de cocina de "${recipe.title}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.errorCoral),
                          child: const Text('Cerrar sesión',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await sessionProv.clearSession();
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
