import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de inicialización de Firebase generadas para el proyecto comiapp-fea78
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHxrITBu_xGMh7EpbWNlAVFpuysaFH7r8',
    appId: '1:474523548597:android:7bea65b7ee5ebf477037fc',
    messagingSenderId: '474523548597',
    projectId: 'comiapp-fea78',
    storageBucket: 'comiapp-fea78.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHxrITBu_xGMh7EpbWNlAVFpuysaFH7r8',
    appId: '1:474523548597:android:7bea65b7ee5ebf477037fc',
    messagingSenderId: '474523548597',
    projectId: 'comiapp-fea78',
    storageBucket: 'comiapp-fea78.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHxrITBu_xGMh7EpbWNlAVFpuysaFH7r8',
    appId: '1:474523548597:android:7bea65b7ee5ebf477037fc',
    messagingSenderId: '474523548597',
    projectId: 'comiapp-fea78',
    storageBucket: 'comiapp-fea78.firebasestorage.app',
  );
}
