import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/recipe.dart';
import '../../models/ingredient.dart';
import '../../models/cooking_step.dart';
import '../../providers/recipe_provider.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controladores principales
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '25');

  int _portions = 2;
  RecipeDifficulty _difficulty = RecipeDifficulty.facil;
  bool _isVegetarian = false;
  bool _isVegan = false;
  bool _isGlutenFree = false;

  // Listas de datos dinámicos
  final List<Ingredient> _ingredients = [];
  final List<_StepData> _steps = [];

  // Controladores temporales para nuevo ingrediente
  final _ingNameController = TextEditingController();
  final _ingQtyController = TextEditingController(text: '1');
  final _ingUnitController = TextEditingController(text: 'unidad');

  // Controladores temporales para nuevo paso
  final _stepTitleController = TextEditingController();
  final _stepDescController = TextEditingController();
  final _stepTimerController = TextEditingController(text: '5');
  bool _stepHasTimer = false;

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _prepTimeController.dispose();
    _ingNameController.dispose();
    _ingQtyController.dispose();
    _ingUnitController.dispose();
    _stepTitleController.dispose();
    _stepDescController.dispose();
    _stepTimerController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final name = _ingNameController.text.trim();
    if (name.isEmpty) return;

    final qty = double.tryParse(_ingQtyController.text.trim()) ?? 1.0;
    final unit = _ingUnitController.text.trim().isEmpty
        ? 'unidad'
        : _ingUnitController.text.trim();

    setState(() {
      _ingredients.add(
        Ingredient(
          id: _uuid.v4(),
          name: name,
          baseQuantity: qty,
          unit: unit,
        ),
      );
      _ingNameController.clear();
      _ingQtyController.text = '1';
      _ingUnitController.text = 'unidad';
    });
  }

  void _addStep() {
    final title = _stepTitleController.text.trim();
    final desc = _stepDescController.text.trim();
    if (title.isEmpty && desc.isEmpty) return;

    final timerMins = _stepHasTimer
        ? (int.tryParse(_stepTimerController.text.trim()) ?? 5)
        : null;

    setState(() {
      _steps.add(
        _StepData(
          id: _uuid.v4(),
          title: title.isEmpty ? 'Paso ${_steps.length + 1}' : title,
          instruction: desc.isEmpty ? title : desc,
          hasTimer: _stepHasTimer,
          timerMinutes: timerMins,
        ),
      );
      _stepTitleController.clear();
      _stepDescController.clear();
      _stepHasTimer = false;
      _stepTimerController.text = '5';
    });
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos un ingrediente a tu receta.'),
          backgroundColor: AppColors.errorCoral,
        ),
      );
      return;
    }

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos un paso de preparación.'),
          backgroundColor: AppColors.errorCoral,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recipeId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      final prepTime = int.tryParse(_prepTimeController.text.trim()) ?? 25;

      final cookingSteps = _steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final s = entry.value;
        return CookingStep(
          id: s.id,
          stepNumber: idx + 1,
          title: s.title,
          instruction: s.instruction,
          timerMinutes: s.hasTimer ? s.timerMinutes : null,
          timerLabel: s.hasTimer ? s.title : null,
          relevantIngredientIds: _ingredients.map((i) => i.id).toList(),
        );
      }).toList();

      final dietaryTags = <String>[];
      if (_isVegetarian) dietaryTags.add('Vegetariano');
      if (_isVegan) dietaryTags.add('Vegano');
      if (_isGlutenFree) dietaryTags.add('Sin Gluten');
      if (prepTime <= 25) dietaryTags.add('Rápido');

      final newRecipe = Recipe(
        id: recipeId,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? 'Receta personalizada creada por ti en comiAPP.'
            : _descController.text.trim(),
        imageUrl:
            'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=800&q=80',
        prepTimeMinutes: prepTime,
        difficulty: _difficulty,
        defaultPortions: _portions,
        dietaryTags: dietaryTags,
        isVegetarian: _isVegetarian,
        isVegan: _isVegan,
        isGlutenFree: _isGlutenFree,
        ingredients: _ingredients,
        steps: cookingSteps,
        isCustom: true,
      );

      final recipeProv = context.read<RecipeProvider>();
      await recipeProv.addCustomRecipe(newRecipe);
      recipeProv.selectCategory('Mis Recetas');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Receta "${newRecipe.title}" guardada exitosamente!'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la receta: $e'),
            backgroundColor: AppColors.errorCoral,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('Crear Receta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveRecipe,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, color: AppColors.primaryTeal),
              label: Text(
                'Guardar',
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryTeal,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Título de la receta
            Text('Información General', style: AppTypography.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la receta *',
                hintText: 'Ej. Cazuela de Lentejas Casera',
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Descripción
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción / Consejos',
                hintText: 'Cuéntanos un poco sobre esta preparación o su origen...',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Tiempo y Porciones
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo (min) *',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    validator: (val) {
                      final n = int.tryParse(val ?? '');
                      if (n == null || n <= 0) return 'Válido > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.outlineDark, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Porciones: $_portions',
                            style: AppTypography.badge
                                .copyWith(color: AppColors.textMuted)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _portions > 1
                                  ? () => setState(() => _portions--)
                                  : null,
                            ),
                            Text('$_portions',
                                style: AppTypography.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _portions < 12
                                  ? () => setState(() => _portions++)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dificultad
            Text('Dificultad', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: RecipeDifficulty.values.map((diff) {
                final isSelected = _difficulty == diff;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Center(child: Text(diff.label)),
                      selected: isSelected,
                      selectedColor: AppColors.highlightYellow,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryTeal
                            : AppColors.outlineDark,
                        width: isSelected ? 2 : 1.5,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _difficulty = diff);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tags dietéticos
            Text('Características', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Vegetariano'),
                  selected: _isVegetarian,
                  selectedColor: AppColors.mintSoft,
                  onSelected: (val) => setState(() => _isVegetarian = val),
                ),
                FilterChip(
                  label: const Text('Vegano'),
                  selected: _isVegan,
                  selectedColor: AppColors.mintSoft,
                  onSelected: (val) => setState(() => _isVegan = val),
                ),
                FilterChip(
                  label: const Text('Sin Gluten'),
                  selected: _isGlutenFree,
                  selectedColor: AppColors.mintSoft,
                  onSelected: (val) => setState(() => _isGlutenFree = val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── SECCIÓN: INGREDIENTES ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ingredientes (${_ingredients.length})',
                    style: AppTypography.titleLarge),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de ingredientes añadidos
            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineDark, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Aún no has agregado ingredientes.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ..._ingredients.map((ing) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineDark, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 8, color: AppColors.primaryTeal),
                          const SizedBox(width: 8),
                          Text(ing.name, style: AppTypography.titleMedium),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${ing.baseQuantity % 1 == 0 ? ing.baseQuantity.toInt() : ing.baseQuantity} ${ing.unit}',
                            style: AppTypography.badge
                                .copyWith(color: AppColors.primaryDarkTeal),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.errorCoral),
                            onPressed: () {
                              setState(() => _ingredients.remove(ing));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),

            // Formulario para agregar ingrediente
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mintSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Agregar ingrediente',
                      style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ingNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nombre (ej. Cebolla cabezona)',
                      prefixIcon: Icon(Icons.egg_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ingQtyController,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            hintText: '1',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _ingUnitController,
                          decoration: const InputDecoration(
                            labelText: 'Unidad',
                            hintText: 'taza, g, unidad',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _addIngredient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir ingrediente'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── SECCIÓN: PASOS DE PREPARACIÓN ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pasos de Preparación (${_steps.length})',
                    style: AppTypography.titleLarge),
              ],
            ),
            const SizedBox(height: 8),

            // Lista de pasos añadidos
            if (_steps.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineDark, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    'Aún no has agregado pasos de cocción.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ..._steps.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineDark, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(s.title, style: AppTypography.titleMedium),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.errorCoral),
                            onPressed: () {
                              setState(() => _steps.removeAt(idx));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(s.instruction, style: AppTypography.bodyMedium),
                      if (s.hasTimer) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.highlightYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.outlineDark, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Temporizador: ${s.timerMinutes} min',
                                style: AppTypography.badge.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),

            // Formulario para agregar nuevo paso
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.highlightYellow.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outlineDark, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Agregar paso a la receta',
                      style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _stepTitleController,
                    decoration: InputDecoration(
                      labelText: 'Título del paso',
                      hintText: 'Ej. Sofreír condimentos',
                      prefixIcon: const Icon(Icons.flag_outlined),
                      prefixText: 'Paso ${_steps.length + 1}: ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _stepDescController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Instrucciones detalladas',
                      hintText: 'Explica qué debe hacerse en este momento...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('¿Requiere temporizador de cocción?'),
                    subtitle: const Text('La app y el Chef te avisarán al terminar'),
                    value: _stepHasTimer,
                    activeTrackColor: AppColors.primaryTeal,
                    onChanged: (val) => setState(() => _stepHasTimer = val),
                  ),
                  if (_stepHasTimer) ...[
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _stepTimerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutos del temporizador',
                        hintText: '5',
                        prefixIcon: Icon(Icons.hourglass_bottom_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir paso'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón principal Guardar Receta
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.restaurant_rounded, size: 22),
              label: Text(
                _isSaving ? 'Guardando receta...' : '¡Guardar y Cocinar!',
                style: AppTypography.titleMedium.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StepData {
  final String id;
  final String title;
  final String instruction;
  final bool hasTimer;
  final int? timerMinutes;

  _StepData({
    required this.id,
    required this.title,
    required this.instruction,
    required this.hasTimer,
    this.timerMinutes,
  });
}
