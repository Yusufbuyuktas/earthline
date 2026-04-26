import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import '../services/firebase_service.dart';
import '../services/location_cache_service.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // --- SERVİSLER ---
  final LocationCacheService _cacheService = LocationCacheService();
  final FirebaseService _firebaseService = FirebaseService();

  // --- KONUM DEĞİŞKENLERİ ---
  LatLng? myLiveLocation; // Kendi CANLI konumumuz (Senin kodun)
  LatLng _cachedMapPosition = const LatLng(40.7410, 30.3330); // Önbellek / Varsayılan (Arkadaşının kodu)
  
  bool _isSimulating = false; // Butonun bekleme durumu

  @override
  void initState() {
    super.initState();
    _initializeLocationSystem();
  }

  // Hem önbelleği hem canlı GPS'i sırayla başlatan Voltran Fonksiyonu
  Future<void> _initializeLocationSystem() async {
    await _loadLastKnownLocation(); // 1. Önce önbelleği yükle (Harita hemen açılsın)
    await _determinePosition();     // 2. Ardından canlı GPS'i bulup haritayı güncelle
  }

  // --- ARKADAŞININ FONKSİYONU: Önbellekten Konum Yükleme ---
  Future<void> _loadLastKnownLocation() async {
    final lastPos = await _cacheService.getOfflineLocation();
    if (lastPos != null) {
      setState(() {
        _cachedMapPosition = lastPos;
      });
      print("💾 WATCHMAN: Önbellekten son konum yüklendi: ${lastPos.latitude}, ${lastPos.longitude}");
    }
  }

  // --- SENİN FONKSİYONUN: Canlı GPS Alma ---
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    print("📍 DEDEKTİF: GPS Konumu başarıyla alındı! Enlem: ${position.latitude}, Boylam: ${position.longitude}");
    
    setState(() {
      myLiveLocation = LatLng(position.latitude, position.longitude);
      _cachedMapPosition = myLiveLocation!; // Canlı konum gelince varsayılanı da güncelle
    });
  }

  // --- ARKADAŞININ FONKSİYONU: Deprem Simülasyonu (SOS Butonu) ---
  Future<void> _simulateEmergency() async {
    setState(() => _isSimulating = true);

    try {
      // Sinyali atarken CANLI konum varsa onu kullan, yoksa ÖNBELLEKTEKİ konumu kullan
      final targetPos = myLiveLocation ?? _cachedMapPosition;
      
      // Firebase'e sinyal gönder (Grup ID'sini senin dinlediğin ile aynı yaptık ki haritada görünsün)
      await _firebaseService.sendEmergencyPing(
        "demo_user_ali", 
        "aile_grubu_1", // Önceden 'sakarya_ekibi'ydi, haritada görünsün diye eşitledik!
        targetPos.latitude, 
        targetPos.longitude
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ACİL DURUM SİNYALİ GÖNDERİLDİ! (Lat: ${targetPos.latitude.toStringAsFixed(4)})"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSimulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Haritanın merkezini belirliyoruz (Canlı konum varsa o, yoksa önbellek)
    final currentCenter = myLiveLocation ?? _cachedMapPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Afet İletişim - Watchman Mode"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeLocationSystem, // Yenileye basınca hem GPS hem Önbellek güncellenir
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getEmergencyPings("aile_grubu_1"),
        builder: (context, snapshot) {
          
          List<Marker> allMarkers = [];

          // 1. KENDİ KONUMUMUZ (Mavi Pin)
          allMarkers.add(
            Marker(
              point: currentCenter,
              width: 60,
              height: 60,
              child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 45),
            ),
          );

          // 2. FİREBASE'DEN GELEN ACİL DURUM SİNYALLERİ (Kırmızı Pinler)
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              // GeoPoint kontrolü (Senin mükemmel ajan çözümün)
              if (data['location'] != null && data['location'] is GeoPoint) {
                GeoPoint geoPoint = data['location'];

                allMarkers.add(
                  Marker(
                    point: LatLng(geoPoint.latitude, geoPoint.longitude),
                    width: 50,
                    height: 50,
                    // Titreşim hissi veren kırmızı afet ikonu
                    child: const Icon(Icons.warning, color: Colors.red, size: 40),
                  ),
                );
              }
            }
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: currentCenter,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.earthflu',
                tileProvider: FMTCStore('kampus_haritasi').getTileProvider(), // Çevrimdışı Harita Motorun
              ),
              MarkerLayer(markers: allMarkers),
            ],
          );
        },
      ),
      // --- DEPREM SİMÜLASYON BUTONU ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSimulating ? null : _simulateEmergency,
        backgroundColor: Colors.red,
        icon: _isSimulating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text(
          _isSimulating ? "SİNYAL GÖNDERİLİYOR..." : "DEPREM SİMÜLASYONU",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}