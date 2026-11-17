import 'package:flutter/material.dart';
import '../../recipes/models/recipe.dart';
import '../../recipes/models/cooking_step.dart';
import '../models/cooking_session.dart';
import '../repositories/cooking_repository.dart';

class CookingSessionProvider extends ChangeNotifier {
  final CookingRepository _repository;

  Recipe? _currentRecipe;
  int _currentStepIndex = 0;
  int _portions = 2;
  List<String> _completedStepIds = [];
  bool _keepScreenAwake = true;

  CookingSessionProvider({CookingRepository? repository})
      : _repository = repository ?? CookingRepository();

  Recipe? get currentRecipe => _currentRecipe;
  int get currentStepIndex => _currentStepIndex;
  int get portions => _portions;
  bool get keepScreenAwake => _keepScreenAwake;
  List<String> get completedStepIds => _completedStepIds;

  CookingStep? get currentStep {
    if (_currentRecipe == null ||
        _currentStepIndex < 0 ||
        _currentStepIndex >= _currentRecipe!.steps.length) {
      return null;
    }
    return _currentRecipe!.steps[_currentStepIndex];
  }

  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep =>
      _currentRecipe != null &&
      _currentStepIndex == _currentRecipe!.steps.length - 1;

  int get totalSteps => _currentRecipe?.steps.length ?? 0;

  Future<void> startSession({
    required Recipe recipe,
    required int portions,
  }) async {
    _currentRecipe = recipe;
    _portions = portions;

    final saved = await _repository.loadSession(recipe.id);
    if (saved != null) {
      final index = recipe.steps.indexWhere((s) => s.id == saved.currentStepId);
      _currentStepIndex = index >= 0 ? index : 0;
      _completedStepIds = List.from(saved.completedStepIds);
      _keepScreenAwake = saved.keepScreenAwake;
    } else {
      _currentStepIndex = 0;
      _completedStepIds = [];
      _keepScreenAwake = true;
    }

    _saveCurrentSession();
    notifyListeners();
  }

  void nextStep() {
    if (_currentRecipe == null) return;
    if (_currentStepIndex < _currentRecipe!.steps.length - 1) {
      final step = currentStep;
      if (step != null && !_completedStepIds.contains(step.id)) {
        _completedStepIds.add(step.id);
      }
      _currentStepIndex++;
      _saveCurrentSession();
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentRecipe == null) return;
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _saveCurrentSession();
      notifyListeners();
    }
  }

  void goToStepById(String stepId) {
    if (_currentRecipe == null) return;
    final index = _currentRecipe!.steps.indexWhere((s) => s.id == stepId);
    if (index >= 0) {
      _currentStepIndex = index;
      _saveCurrentSession();
      notifyListeners();
    }
  }

  void toggleKeepScreenAwake() {
    _keepScreenAwake = !_keepScreenAwake;
    _saveCurrentSession();
    notifyListeners();
  }

  Future<void> clearSession() async {
    if (_currentRecipe != null) {
      await _repository.clearSession(_currentRecipe!.id);
    }
    _currentRecipe = null;
    _currentStepIndex = 0;
    _completedStepIds = [];
    notifyListeners();
  }

  void _saveCurrentSession() {
    if (_currentRecipe == null || currentStep == null) return;
    final session = CookingSession(
      recipeId: _currentRecipe!.id,
      currentStepId: currentStep!.id,
      portions: _portions,
      completedStepIds: _completedStepIds,
      keepScreenAwake: _keepScreenAwake,
      startedAt: DateTime.now(),
    );
    _repository.saveSession(session);
  }
}
