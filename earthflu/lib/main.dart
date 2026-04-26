import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'screens/map_screen.dart';

void main() async {
  // 1. Sistemleri başlatıyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat
  await Firebase.initializeApp();

  // 3. Çevrimdışı harita motorunu başlat
  await FMTCObjectBoxBackend().initialise();

  // 4. İŞTE BİZİ KURTARACAK O EKSİK SATIR (Depoyu oluştur)
  await FMTCStore('kampus_haritasi').manage.createAsync();

  // 5. Uygulamayı çalıştır
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afet Demo',
      theme: ThemeData(primarySwatch: Colors.red),
      home: CampusMapScreen(),
    );
  }
}