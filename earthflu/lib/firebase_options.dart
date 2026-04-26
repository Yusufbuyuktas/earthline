import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Windows üzerinde çalıştığın için doğrudan bu konfigürasyonu döndürüyoruz
    return androidConfigAsWindows;
  }

  // JSON dosyasından aldığımız bilgilerle oluşturulan konfigürasyon
  static const FirebaseOptions androidConfigAsWindows = FirebaseOptions(
    apiKey: 'AIzaSyB2gCUYkPa8oLa8GDvgA-rj9CIi_QzQGZs',
    appId: '1:510738676073:android:b38d017e353a023f0d65f8',
    messagingSenderId: '510738676073',
    projectId: 'quakeline-55635',
    storageBucket: 'quakeline-55635.firebasestorage.app',
  );
}