import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../recipes/models/recipe.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import '../../providers/cooking_session_provider.dart';
import '../../providers/timer_provider.dart';

/// Pantalla de celebración al terminar una receta.
/// Muestra: título, animación de check, calificación con estrellas,
/// y botones para volver a La Despensa o cocinar de nuevo.
class RecipeCompleteScreen extends StatefulWidget {
  final Recipe recipe;
  final int portions;
  final VoidCallback? onOpenAiChef;

  const RecipeCompleteScreen({
    super.key,
    required this.recipe,
    this.portions = 2,
    this.onOpenAiChef,
  });

  /// Navega reemplazando la pantalla actual
  static void navigate(
    BuildContext context,
    Recipe recipe, {
    int portions = 2,
    VoidCallback? onOpenAiChef,
  }) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: RecipeCompleteScreen(
            recipe: recipe,
            portions: portions,
            onOpenAiChef: onOpenAiChef,
          ),
        ),
      ),
    );
  }

  @override
  State<RecipeCompleteScreen> createState() => _RecipeCompleteScreenState();
}

class _RecipeCompleteScreenState extends State<RecipeCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _selectedRating = 0;
  bool _ratingSaved = false;

  static const String _ratingsKey = 'comiapp_ratings';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    _loadExistingRating();

    // Cancelar timers de esta receta al terminar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProv = context.read<TimerProvider>();
      final toCancel = timerProv.timers
          .where((t) => t.recipeId == widget.recipe.id)
          .map((t) => t.id)
          .toList();
      for (final id in toCancel) {
        timerProv.cancelTimer(id);
      }
      context.read<CookingSessionProvider>().clearSession();
    });
  }

  Future<void> _loadExistingRating() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ratingsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    final saved = map[widget.recipe.id];
    if (saved != null && mounted) {
      setState(() => _selectedRating = (saved as num).toInt());
    }
  }

  Future<void> _saveRating(int stars) async {
    if (_ratingSaved) return;
    setState(() {
      _selectedRating = stars;
      _ratingSaved = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ratingsKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw));
    map[widget.recipe.id] = stars;
    await prefs.setString(_ratingsKey, jsonEncode(map));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.star_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            Text('¡Gracias! Calificaste con $stars ${stars == 1 ? "estrella" : "estrellas"}'),
          ]),
          backgroundColor: AppColors.primaryTeal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShellScreen()),
      (route) => false,
    );
  }

  void _cookAgain() {
    Navigator.of(context).pop(); // vuelve a RecipeDetailScreen
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Animación del check ──────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.mintSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primaryTeal, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryTeal,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Título celebración ───────────────────────────────
              Text(
                '¡Buen provecho! 🎉',
                style: AppTypography.displayLarge
                    .copyWith(color: AppColors.primaryTeal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Terminaste de cocinar:',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.recipe.title,
                style: AppTypography.titleLarge
                    .copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
              Divider(color: AppColors.outlineDark.withValues(alpha: 0.5)),
              const SizedBox(height: 24),

              // ── Calificación con estrellas ───────────────────────
              Text(
                '¿Cómo te quedó?',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Tu calificación se guarda en este dispositivo',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  return GestureDetector(
                    onTap: () => _saveRating(starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        starValue <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),
              if (_ratingSaved)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _ratingLabel(_selectedRating),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // ── Botones de acción ────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goHome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.home_rounded, color: Colors.white),
                  label: Text(
                    'Volver a La Despensa',
                    style: AppTypography.bodyMedium
                        .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cookAgain,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                        color: AppColors.accentOrange, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.replay_rounded,
                      color: AppColors.accentOrange),
                  label: Text(
                    'Cocinar de nuevo',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Hay que practicar más 💪';
      case 2:
        return 'No estuvo mal 🙂';
      case 3:
        return '¡Quedó bien! 👌';
      case 4:
        return '¡Muy rico! 😋';
      case 5:
        return '¡Obra maestra! 🏆';
      default:
        return '';
    }
  }
}
