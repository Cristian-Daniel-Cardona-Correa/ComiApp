/// Constantes globales de comiAPP
class AppConstants {
  AppConstants._();

  static const String appName = 'comiAPP';
  static const String appTagline = 'Tu asistente inteligente en la cocina';

  // Gemini Live API Audio / Video Specs (según especificación técnica oficial)
  // Audio de entrada: PCM 16-bit little-endian mono a 16000 Hz
  static const int inputSampleRate = 16000;
  static const String inputAudioMimeType = 'audio/pcm;rate=16000';

  // Audio de salida: PCM 16-bit little-endian mono a 24000 Hz
  static const int outputSampleRate = 24000;
  static const String outputAudioMimeType = 'audio/pcm;rate=24000';

  // Video / Cámara: 1 FPS JPEG (768x768 recomendado)
  static const double cameraFps = 1.0;
  static const int cameraJpegQuality = 80;
  static const int cameraImageDimension = 768;

  // Modelo Gemini Live recomendado por defecto
  static const String defaultGeminiLiveModel =
      'gemini-2.5-flash-native-audio-preview-12-2025';

  // Límites de sesión Gemini Live
  static const int maxAudioSessionMinutes = 15;
  static const int maxVideoSessionMinutes = 2;
  static const int sessionTimeoutWarningSeconds = 60;

  // Habeas Data / Política de Privacidad (Ley 1581 de 2012)
  static const String habeasDataPolicy = '''
En cumplimiento de la Ley 1581 de 2012 de Colombia (Habeas Data):
1. comiAPP solicita acceso a micrófono y cámara exclusivamente para interactuar en tiempo real con el Asistente Culinario Gemini Live.
2. Los fragmentos de audio y video se transmiten de manera efímera a los servidores de procesamiento seguro de Google Gemini y NO son almacenados localmente ni en bases de datos de Firestore.
3. El usuario puede revocar estos permisos en cualquier momento desde la configuración de su dispositivo.
4. Las preferencias culinarias y recetas favoritas se almacenan de manera segura bajo el perfil del usuario.
''';
}
