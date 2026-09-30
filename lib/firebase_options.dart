// ═══════════════════════════════════════════════════════════════════════════════
// Firebase Options for MAIN Islam114 App
// ═══════════════════════════════════════════════════════════════════════════════
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

const FirebaseOptions androidOptions = FirebaseOptions(
  apiKey: 'AIzaSyA08GXRaQvvC6h8PCX1_SUmuNgcTssN0lI',
  appId: '1:345178253147:android:df86e9e27efdfcee25dc7e', // MAIN App ID
  messagingSenderId: '345178253147',
  projectId: 'islam114-7ba9c',
  storageBucket: 'islam114-7ba9c.firebasestorage.app',
);

const FirebaseOptions iosOptions = FirebaseOptions(
  apiKey: 'AIzaSyA08GXRaQvvC6h8PCX1_SUmuNgcTssN0lI',
  appId: '1:345178253147:android:df86e9e27efdfcee25dc7e',
  messagingSenderId: '345178253147',
  projectId: 'islam114-7ba9c',
  storageBucket: 'islam114-7ba9c.firebasestorage.app',
);

FirebaseOptions get currentPlatform {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return androidOptions;
    case TargetPlatform.iOS:
      return iosOptions;
    case TargetPlatform.macOS:
      return iosOptions;
    default:
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for ${defaultTargetPlatform.name}.',
      );
  }
}