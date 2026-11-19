import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cooking_timer.dart';
import '../repositories/cooking_repository.dart';
import '../services/notification_service.dart';
import '../services/timer_sound_service.dart';

class TimerProvider extends ChangeNotifier {
  final CookingRepository _repository;
  final NotificationService _notificationService;
  final TimerSoundService _soundService;
  final _uuid = const Uuid();

  List<CookingTimer> _timers = [];
  Timer? _ticker;
  bool _isDisposed = false;

  TimerProvider({
    CookingRepository? repository,
    NotificationService? notificationService,
    TimerSoundService? soundService,
  })  : _repository = repository ?? CookingRepository(),
        _notificationService =
            notificationService ?? LocalCookingNotificationService(),
        _soundService = soundService ?? TimerSoundService() {
    _init();
  }

  List<CookingTimer> get timers => _timers;
  List<CookingTimer> get activeTimers =>
      _timers.where((t) => t.isRunning || t.isPaused).toList();
  List<CookingTimer> get runningTimers =>
      _timers.where((t) => t.isRunning).toList();
  bool get hasActiveTimers => activeTimers.isNotEmpty;

  Future<void> _init() async {
    final saved = await _repository.loadActiveTimers();
    final now = DateTime.now();

    _timers = saved.map((timer) {
      if (timer.status == TimerStatus.corriendo && timer.deadline != null) {
        final diff = timer.deadline!.difference(now).inSeconds;
        if (diff <= 0) {
          return timer.copyWith(
            remainingSeconds: 0,
            status: TimerStatus.terminado,
          );
        } else {
          return timer.copyWith(remainingSeconds: diff);
        }
      }
      return timer;
    }).toList();

    _evaluateTicker();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _evaluateTicker() {
    final anyRunning = _timers.any((t) => t.isRunning);
    if (anyRunning) {
      if (_ticker == null || !_ticker!.isActive) {
        _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
      }
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _onTick(Timer _) {
    final now = DateTime.now();
    bool hasChanged = false;
    bool hasCompletedTimer = false;

    _timers = _timers.map((timer) {
      if (timer.status == TimerStatus.corriendo) {
        if (timer.deadline != null) {
          final diff = timer.deadline!.difference(now).inSeconds;
          if (diff <= 0) {
            hasChanged = true;
            hasCompletedTimer = true;
            return timer.copyWith(
              remainingSeconds: 0,
              status: TimerStatus.terminado,
            );
          } else {
            hasChanged = true;
            return timer.copyWith(remainingSeconds: diff);
          }
        } else {
          final nextRem = timer.remainingSeconds - 1;
          hasChanged = true;
          if (nextRem <= 0) {
            hasCompletedTimer = true;
            return timer.copyWith(
              remainingSeconds: 0,
              status: TimerStatus.terminado,
            );
          }
          return timer.copyWith(remainingSeconds: nextRem);
        }
      }
      return timer;
    }).toList();

    if (hasCompletedTimer) {
      _soundService.playTimerAlarm();
    }

    if (hasChanged) {
      _evaluateTicker();
      _repository.saveActiveTimers(_timers);
      notifyListeners();
    }
  }

  /// Inicia un temporizador manual (sin receta asociada)
  CookingTimer startManualTimer({
    required String label,
    required int minutes,
  }) {
    return startTimer(
      label: label,
      recipeId: 'manual',
      stepId: _uuid.v4(),
      minutes: minutes,
    );
  }

  /// Inicia o crea un temporizador para un paso de receta
  CookingTimer startTimer({
    required String label,
    required String recipeId,
    required String stepId,
    required int minutes,
  }) {
    final durationSeconds = minutes * 60;
    final deadline = DateTime.now().add(Duration(seconds: durationSeconds));

    final existingIndex =
        _timers.indexWhere((t) => t.recipeId == recipeId && t.stepId == stepId);

    CookingTimer timer;
    if (existingIndex >= 0) {
      timer = _timers[existingIndex].copyWith(
        label: label,
        totalDurationSeconds: durationSeconds,
        remainingSeconds: durationSeconds,
        deadline: deadline,
        status: TimerStatus.corriendo,
      );
      _timers[existingIndex] = timer;
    } else {
      timer = CookingTimer(
        id: _uuid.v4(),
        label: label,
        recipeId: recipeId,
        stepId: stepId,
        totalDurationSeconds: durationSeconds,
        remainingSeconds: durationSeconds,
        deadline: deadline,
        status: TimerStatus.corriendo,
      );
      _timers.add(timer);
    }

    _notificationService.scheduleTimerNotification(
      timer: timer,
      deadline: deadline,
    );

    _evaluateTicker();
    _repository.saveActiveTimers(_timers);
    notifyListeners();
    return timer;
  }

  void pauseTimer(String timerId) {
    final index = _timers.indexWhere((t) => t.id == timerId);
    if (index >= 0) {
      final timer = _timers[index];
      if (timer.isRunning) {
        _timers[index] = timer.copyWith(
          status: TimerStatus.pausado,
          deadline: null,
        );
        _notificationService.cancelTimerNotification(timerId);
        _evaluateTicker();
        _repository.saveActiveTimers(_timers);
        notifyListeners();
      }
    }
  }

  void resumeTimer(String timerId) {
    final index = _timers.indexWhere((t) => t.id == timerId);
    if (index >= 0) {
      final timer = _timers[index];
      if (timer.isPaused) {
        final newDeadline =
            DateTime.now().add(Duration(seconds: timer.remainingSeconds));
        final updated = timer.copyWith(
          status: TimerStatus.corriendo,
          deadline: newDeadline,
        );
        _timers[index] = updated;
        _notificationService.scheduleTimerNotification(
          timer: updated,
          deadline: newDeadline,
        );
        _evaluateTicker();
        _repository.saveActiveTimers(_timers);
        notifyListeners();
      }
    }
  }

  /// Agrega 1 minuto al temporizador
  void addOneMinute(String timerId) {
    _adjustMinutes(timerId, 60);
  }

  /// Quita 1 minuto al temporizador (mínimo 10 segundos restantes)
  void removeOneMinute(String timerId) {
    _adjustMinutes(timerId, -60);
  }

  void _adjustMinutes(String timerId, int deltaSeconds) {
    final index = _timers.indexWhere((t) => t.id == timerId);
    if (index < 0) return;
    final timer = _timers[index];

    // No bajar de 10 segundos
    final newRemaining =
        (timer.remainingSeconds + deltaSeconds).clamp(10, 86400);
    final newTotal = (timer.totalDurationSeconds + deltaSeconds).clamp(10, 86400);
    DateTime? newDeadline;

    if (timer.isRunning) {
      newDeadline = DateTime.now().add(Duration(seconds: newRemaining));
    }

    final updated = timer.copyWith(
      remainingSeconds: newRemaining,
      totalDurationSeconds: newTotal,
      deadline: newDeadline,
      status: timer.isFinished ? TimerStatus.corriendo : timer.status,
    );

    _timers[index] = updated;
    if (newDeadline != null) {
      _notificationService.scheduleTimerNotification(
        timer: updated,
        deadline: newDeadline,
      );
    }
    _evaluateTicker();
    _repository.saveActiveTimers(_timers);
    notifyListeners();
  }

  void cancelTimer(String timerId) {
    _timers.removeWhere((t) => t.id == timerId);
    _notificationService.cancelTimerNotification(timerId);
    _evaluateTicker();
    _repository.saveActiveTimers(_timers);
    notifyListeners();
  }

  void cancelAllTimers() {
    _timers.clear();
    _notificationService.cancelAllNotifications();
    _evaluateTicker();
    _repository.clearAllTimers();
    notifyListeners();
  }

  CookingTimer? getTimerForStep(String recipeId, String stepId) {
    try {
      return _timers.firstWhere(
        (t) => t.recipeId == recipeId && t.stepId == stepId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
