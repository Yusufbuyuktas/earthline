import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/map_screen.dart';
import 'services/location_cache_service.dart';
import 'firebase_options.dart';

// --- WATCHMAN ARKA PLAN GÖREVİ ---
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
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase Başlatma
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Watchman: Firebase hattı kuruldu.");
  } catch (e) {
    print("Firebase KRİTİK HATA: $e");
  }

  // --- BURASI KRİTİK: ÖNBELLEK DOLDURMA ---
  // Uygulama ilk açıldığında butona basarsan hata almaman için 
  // kutuya "varsayılan" bir konum bırakıyoruz.
  final cache = LocationCacheService();
  await cache.saveToOffline(40.7410, 30.3330); // Sakarya Kampüs Koordinatı
  print("Watchman: İlk konum önbelleğe başarıyla yazıldı.");

  // 2. Workmanager Başlatma
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  Workmanager().registerPeriodicTask(
    "watchman-location-task",
    "simplePeriodicTask",
    frequency: Duration(minutes: 15),
    initialDelay: Duration(seconds: 10),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      home: CampusMapScreen(),
    );
  }
}