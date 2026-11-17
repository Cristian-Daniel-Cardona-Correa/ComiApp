import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../recipes/models/recipe.dart';
import '../../providers/cooking_session_provider.dart';
import '../../providers/timer_provider.dart';
import '../widgets/active_timers_sheet.dart';
import 'recipe_complete_screen.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  final int portions;
  final VoidCallback? onOpenAiChef;

  const CookingModeScreen({
    super.key,
    required this.recipe,
    required this.portions,
    this.onOpenAiChef,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CookingSessionProvider>().startSession(
            recipe: widget.recipe,
            portions: widget.portions,
          );
    });
  }

  void _handleExit() {
    final timerProv = context.read<TimerProvider>();
    final sessionProv = context.read<CookingSessionProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.creamBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.outlineDark, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.accentOrange, size: 28),
            const SizedBox(width: 10),
            Text('¿Salir de la cocina?', style: AppTypography.titleLarge),
          ],
        ),
        content: Text(
          'Puedes cambiar de receta manteniendo tus temporizadores activos, o terminar completamente la sesión (lo cual cancelará todos los temporizadores en curso).',
          style: AppTypography.bodyMedium,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          // Opción A: Cambiar de receta (conserva temporizadores)
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Cambiar de receta (mantener tiempos)'),
          ),
          const SizedBox(height: 8),
          // Opción B: Terminar de cocinar (cancela temporizadores)
          ElevatedButton(
            onPressed: () async {
              timerProv.cancelAllTimers();
              await sessionProv.clearSession();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorCoral,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Terminar de cocinar (cancelar tiempos)'),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Continuar cocinando'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CookingSessionProvider>();
    final timerProv = context.watch<TimerProvider>();
    final step = session.currentStep;

    if (step == null) {
      return Scaffold(
        backgroundColor: AppColors.creamBackground,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
        ),
      );
    }

    final stepTimer = timerProv.getTimerForStep(widget.recipe.id, step.id);
    final isTimerRunning = stepTimer?.isRunning ?? false;
    final isTimerFinished = stepTimer?.isFinished ?? false;

    // Ingredientes usados en este paso
    final stepIngredients = widget.recipe.getIngredientsForStep(step);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.creamBackground,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 28),
            tooltip: 'Salir',
            onPressed: _handleExit,
          ),
          title: Text(
            widget.recipe.title,
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            // Indicador de pantalla encendida (Wakelock)
            IconButton(
              icon: Icon(
                session.keepScreenAwake
                    ? Icons.wb_sunny_rounded
                    : Icons.wb_sunny_outlined,
                color: session.keepScreenAwake
                    ? AppColors.accentOrange
                    : AppColors.textMuted,
              ),
              tooltip: session.keepScreenAwake
                  ? 'Pantalla siempre encendida (activo)'
                  : 'Pantalla siempre encendida (desactivado)',
              onPressed: () => session.toggleKeepScreenAwake(),
            ),
            // Acceso rápido a lista global de temporizadores
            IconButton(
              icon: Badge(
                isLabelVisible: timerProv.hasActiveTimers,
                label: Text('${timerProv.activeTimers.length}'),
                child: const Icon(Icons.timer_outlined, size: 26),
              ),
              tooltip: 'Mis Tiempos',
              onPressed: () => ActiveTimersSheet.show(context),
            ),
            // Botón "Chef IA" en AppBar para no solaparse con los botones de paso
            IconButton(
              icon: const Icon(Icons.psychology_alt_rounded, size: 26),
              tooltip: 'Preguntarle al chef',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.mintSoft,
                foregroundColor: AppColors.primaryTeal,
              ),
              onPressed: () {
                if (widget.onOpenAiChef != null) {
                  widget.onOpenAiChef!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abriendo Asistente Chef IA...'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Barra de progreso del paso
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.highlightYellow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.outlineDark, width: 1.5),
                      ),
                      child: Text(
                        'Paso ${session.currentStepIndex + 1} de ${session.totalSteps}',
                        style: AppTypography.badge.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (session.currentStepIndex + 1) /
                              session.totalSteps,
                          minHeight: 10,
                          backgroundColor: AppColors.mintSoft,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryTeal),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido deslizable del paso
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título del paso
                      Text(
                        step.title,
                        style: AppTypography.displayMedium.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 16),

                      // Instrucción grande de cocina (>= 24sp requerido)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: AppColors.outlineDark, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.outlineDark.withValues(alpha: 0.08),
                              offset: const Offset(3, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          step.instruction,
                          style: AppTypography.cookingInstruction,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Temporizador del paso (si tiene duración)
                      if (step.hasTimer)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isTimerFinished
                                ? AppColors.errorCoral.withValues(alpha: 0.15)
                                : AppColors.mintSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isTimerFinished
                                  ? AppColors.errorCoral
                                  : AppColors.outlineDark,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isTimerFinished
                                        ? Icons.notifications_active_rounded
                                        : Icons.alarm_rounded,
                                    color: isTimerFinished
                                        ? AppColors.errorCoral
                                        : AppColors.primaryTeal,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          step.timerLabel ?? 'Temporizador de paso',
                                          style: AppTypography.titleMedium
                                              .copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          'Duración recomendada: ${step.timerMinutes} minutos',
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (stepTimer != null)
                                    Text(
                                      stepTimer.formattedTime,
                                      style: AppTypography.titleLarge.copyWith(
                                        fontSize: 22,
                                        color: isTimerFinished
                                            ? AppColors.errorCoral
                                            : AppColors.textDark,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (stepTimer == null) ...[
                                ElevatedButton.icon(
                                  onPressed: () {
                                    timerProv.startTimer(
                                      label: step.timerLabel ?? step.title,
                                      recipeId: widget.recipe.id,
                                      stepId: step.id,
                                      minutes: step.timerMinutes!,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentOrange,
                                    minimumSize: const Size(0, 46),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                      'Iniciar temporizador (${step.timerMinutes} min)'),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          if (isTimerRunning) {
                                            timerProv.pauseTimer(stepTimer.id);
                                          } else {
                                            timerProv.resumeTimer(stepTimer.id);
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 44),
                                        ),
                                        icon: Icon(isTimerRunning
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded),
                                        label: Text(isTimerRunning
                                            ? 'Pausar'
                                            : 'Reanudar'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            timerProv.addOneMinute(stepTimer.id),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(0, 44),
                                          backgroundColor:
                                              AppColors.highlightYellow,
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('+1 min'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Ingredientes usados en este paso
                      if (stepIngredients.isNotEmpty) ...[
                        Text(
                          'Ingredientes para este paso:',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...stepIngredients.map((ing) {
                          final qty = ing.getFormattedQuantity(
                            widget.recipe.defaultPortions,
                            widget.portions,
                          );
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.outlineDark, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ing.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    qty,
                                    style: AppTypography.badge.copyWith(
                                      color: AppColors.primaryDarkTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Chef Tip opcional
                      if (step.chefTip != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.highlightYellow.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.outlineDark, width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  color: AppColors.accentOrange, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tip del Chef: ${step.chefTip!}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Botones gigantes de navegación de pasos (Siguiente / Anterior)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineDark, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    if (!session.isFirstStep) ...[
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => session.previousStep(),
                          child: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () {
                          if (session.isLastStep) {
                            RecipeCompleteScreen.navigate(
                              context,
                              widget.recipe,
                              portions: widget.portions,
                              onOpenAiChef: widget.onOpenAiChef,
                            );
                          } else {
                            session.nextStep();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: session.isLastStep
                              ? AppColors.primaryTeal
                              : AppColors.accentOrange,
                          foregroundColor: session.isLastStep
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                        child: Text(
                          session.isLastStep
                              ? '¡Plato Terminado!'
                              : 'Siguiente Paso',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
