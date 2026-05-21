import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBB2wc-EN_Go-kuN79IkAMT3p5TiRi1BiM',
    authDomain: 'hizmatai.firebaseapp.com',
    projectId: 'hizmatai',
    storageBucket: 'hizmatai.firebasestorage.app',
    messagingSenderId: '331814655614',
    appId: '1:331814655614:web:9551b3a5935b9df3192a2f',
    measurementId: 'G-X5S80XTF21',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAaakSPJamx369c4lXaALfxF8hbygqJPi8',
    projectId: 'hizmatai',
    storageBucket: 'hizmatai.firebasestorage.app',
    messagingSenderId: '331814655614',
    appId: '1:331814655614:android:8b025b4a6efcbd6f192a2f',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBzdg6qMtg3tXRFuGAjsAxnQEilGbYx9mM',
    projectId: 'hizmatai',
    storageBucket: 'hizmatai.firebasestorage.app',
    messagingSenderId: '331814655614',
    appId: '1:331814655614:ios:10597cbbcd21b2e0192a2f',
  );
}
