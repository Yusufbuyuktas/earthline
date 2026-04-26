import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class LocationCacheService {
  static const String _latKey = 'watchman_lat';
  static const String _lngKey = 'watchman_lng';

  // Konumu anlık olarak yerel hafızaya gömer
  Future<void> saveToOffline(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, lat);
    await prefs.setDouble(_lngKey, lng);
    print("Watchman: Konum çevrimdışı kullanım için kitlendi: $lat, $lng");
  }

  // İnternet yoksa haritayı başlatmak için son konumu çeker
  Future<LatLng?> getOfflineLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final double? lat = prefs.getDouble(_latKey);
    final double? lng = prefs.getDouble(_lngKey);

    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }
}