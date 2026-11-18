import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Utilidad para solicitar permisos de micrófono y cámara silenciosamente
/// (sin mostrar ningún diálogo de la app — solo los diálogos del sistema Android).
class AiPermissionsDialog {
  AiPermissionsDialog._();

  /// Solicita permisos de micrófono y cámara directamente al sistema Android.
  /// No muestra ningún diálogo propio de la aplicación.
  /// Retorna true siempre para no bloquear el flujo (los permisos del sistema
  /// se manejan de forma independiente).
  static Future<bool> requestPermissions() async {
    try {
      await Permission.microphone.request();
      await Permission.camera.request();
    } catch (e) {
      debugPrint('[comiAPP] Error solicitando permisos: $e');
    }
    return true;
  }

  /// Alias de [requestPermissions] para compatibilidad con llamadas existentes
  /// que aún pasen un BuildContext (el contexto es ignorado).
  static Future<bool> requestConsent(BuildContext context) =>
      requestPermissions();
}
