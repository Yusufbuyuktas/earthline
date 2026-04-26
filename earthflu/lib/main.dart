import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // Senin Harita Paketin
import 'package:workmanager/workmanager.dart'; // Arkadaşının Arka Plan Paketi
import 'screens/map_screen.dart';
import 'services/location_cache_service.dart'; // Arkadaşının Önbellek Servisi
import 'firebase_options.dart'; // Arkadaşının Firebase Ayarları

// --- WATCHMAN ARKA PLAN GÖREVİ (Arkadaşının Kodu) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final cache = LocationCacheService();
      // Arka plan simülasyonu için sabit konum kaydı
      await cache.saveToOffline(40.7410, 30.3330);
      print("Watchman: Arka plan görevi tetiklendi!");
      return Future.value(true);
    } catch (err) {
      print("Watchman Arka Plan Hatası: $err");
      return Future.value(false);
    }
  });
}

void main() async {
  // 1. Flutter sistemlerini başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase Başlatma (Arkadaşının Güvenli Yöntemi)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Watchman: Firebase hattı kuruldu.");
  } catch (e) {
    print("Firebase KRİTİK HATA: $e");
  }

  // 3. Çevrimdışı Harita Motorunu Başlatma (Senin Kodun)
  try {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('kampus_haritasi').manage.createAsync();
    print("Harita Motoru: Çevrimdışı harita deposu hazır.");
  } catch (e) {
    print("Harita Motoru Hatası: $e");
  }

  // 4. ÖNBELLEK DOLDURMA (Arkadaşının Simülasyon Kodu)
  try {
    final cache = LocationCacheService();
    await cache.saveToOffline(40.7410, 30.3330); // Sakarya Kampüs Koordinatı
    print("Watchman: İlk konum önbelleğe başarıyla yazıldı.");
  } catch (e) {
    print("Önbellek Hatası: $e");
  }

  // 5. Workmanager Başlatma (Arka Plan Görevleri)
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "watchman-location-task",
    "simplePeriodicTask",
    frequency: const Duration(minutes: 15),
    initialDelay: const Duration(seconds: 10),
  );

  // 6. Uygulamayı çalıştır
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Arkadaşının hazırladığı daha şık Material 3 Teması
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EarthFlu Afet Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red[800]!,
          secondary: Colors.amber,
        ),
      ),
      home: CampusMapScreen(), // İlk açılacak ekran yine senin haritan!
    );
  }
}