import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_cache_service.dart';
import '../services/firebase_service.dart';

class CampusMapScreen extends StatefulWidget {
  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // Servis Tanımlamaları
  final LocationCacheService _cacheService = LocationCacheService();
  final FirebaseService _firebaseService = FirebaseService();

  // Varsayılan Koordinat (Sakarya Üni.)
  LatLng _currentMapPosition = LatLng(40.7410, 30.3330);
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _loadLastKnownLocation();
  }

  // Watchman Görevi: Uygulama açılırken internet yoksa son konumu diskten yükle
  Future<void> _loadLastKnownLocation() async {
    final lastPos = await _cacheService.getOfflineLocation();
    if (lastPos != null) {
      setState(() {
        _currentMapPosition = lastPos;
      });
    }
  }

  // Deprem Simülasyonu Tetikleyici
  Future<void> _simulateEmergency() async {
    setState(() => _isSimulating = true);

    try {
      // 1. Önce diske bak (Watchman'in kaydettiği en taze veri)
      final lastPos = await _cacheService.getOfflineLocation();
      
      if (lastPos != null) {
        // 2. Firebase'e 'Emergency Ping' olarak fırlat
        await _firebaseService.sendEmergencyPing(
          "demo_user_ali", // Bu kısım normalde Auth'dan gelir
          "sakarya_ekibi", 
          lastPos.latitude, 
          lastPos.longitude
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ACİL DURUM SİNYALİ GÖNDERİLDİ! (Lat: ${lastPos.latitude})"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception("Önbellekte konum bulunamadı!");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}")),
      );
    } finally {
      setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Afet İletişim - Watchman Mode"),
        backgroundColor: Colors.red[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLastKnownLocation, // Manuel konum yenileme
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _currentMapPosition,
          initialZoom: 16.0,
          maxZoom: 18.0,
          minZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.earthflu',
          ),
          MarkerLayer(
            markers: [
              // Kullanıcının Mevcut/Son Konumu
              Marker(
                point: _currentMapPosition,
                width: 60,
                height: 60,
                child: Icon(
                  Icons.person_pin_circle, 
                  color: Colors.blueAccent, 
                  size: 45
                ),
              ),
            ],
          ),
        ],
      ),
      // --- Watchman Simülasyon Butonu ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSimulating ? null : _simulateEmergency,
        backgroundColor: Colors.red,
        icon: _isSimulating 
            ? CircularProgressIndicator(color: Colors.white) 
            : Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text(
          _isSimulating ? "SİNYAL GÖNDERİLİYOR..." : "DEPREM SİMÜLASYONU",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}