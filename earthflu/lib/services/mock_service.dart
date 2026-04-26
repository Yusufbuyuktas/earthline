import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_cache_service.dart';

class MockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocationCacheService _cache = LocationCacheService();

  // Hem yerel cache'i hem Firebase'i test verisiyle doldurur
  Future<void> setupMockEnvironment() async {
    // 1. Senin konumunu cache'e yaz (Buton hatasını çözer)
    await _cache.saveToOffline(40.7410, 30.3330);

    // 2. Firebase'e sahte aile üyeleri ekle
    List<Map<String, dynamic>> family = [
      {'id': 'f1', 'name': 'Anne', 'lat': 40.7425, 'lng': 30.3345},
      {'id': 'f2', 'name': 'Baba', 'lat': 40.7395, 'lng': 30.3315},
    ];

    for (var member in family) {
      await _db.collection('users').doc(member['id']).set({
        'name': member['name'],
        'group_id': 'sakarya_ekibi',
        'last_location': GeoPoint(member['lat'], member['lng']),
      });
    }
    print("Watchman: Mock ortamı hazır!");
  }
}