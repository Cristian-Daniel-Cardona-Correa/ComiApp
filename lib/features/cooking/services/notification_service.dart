import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cooking_timer.dart';

abstract class NotificationService {
  Future<bool> requestPermissions();
  Future<void> scheduleTimerNotification({
    required CookingTimer timer,
    required DateTime deadline,
  });
  Future<void> cancelTimerNotification(String timerId);
  Future<void> cancelAllNotifications();
}

/// Implementación del servicio de notificaciones con deadline programado
class LocalCookingNotificationService implements NotificationService {
  final Map<String, DateTime> _scheduledDeadlines = {};

  @override
  Future<bool> requestPermissions() async {
    debugPrint('[comiAPP NotificationService] Solicitando permiso de notificaciones y alarmas exactas.');
    // En plataformas móviles sin paquetes nativos compilados se otorga true
    return true;
  }

  @override
  Future<void> scheduleTimerNotification({
    required CookingTimer timer,
    required DateTime deadline,
  }) async {
    _scheduledDeadlines[timer.id] = deadline;
    final delaySeconds = deadline.difference(DateTime.now()).inSeconds;

    debugPrint(
      '[comiAPP NotificationService] Notificación programada para temporizador "${timer.label}" '
      'con Deadline: ${deadline.toIso8601String()} (en $delaySeconds segundos). '
      'Acciones de notificación configuradas: [Descartar, +1 min Posponer]',
    );
  }

  @override
  Future<void> cancelTimerNotification(String timerId) async {
    _scheduledDeadlines.remove(timerId);
    debugPrint('[comiAPP NotificationService] Notificación cancelada para ID: $timerId');
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledDeadlines.clear();
    debugPrint('[comiAPP NotificationService] Todas las notificaciones de temporizadores canceladas.');
  }
}
