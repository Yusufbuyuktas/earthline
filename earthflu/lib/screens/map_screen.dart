import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'dart:async'; // Stream için gerekli

import '../services/firebase_service.dart';
import '../services/location_cache_service.dart';
import '../services/location_service.dart'; // YENİ SERVİSİNİ EKLEDİK

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // --- SERVİSLER ---
  final LocationCacheService _cacheService = LocationCacheService();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService(); // YENİ SERVİS

  // --- DEĞİŞKENLER ---
  LatLng? myLiveLocation;
  LatLng _cachedMapPosition = const LatLng(40.7410, 30.3330);
  bool _isSimulating = false;

  // GÖREV 2: Uygulamayı İşlevsiz Bırakma Kilidi
  bool _hasLocationPermission = true;

  bool _sosSent = false; // Kullanıcı sinyal gönderdi mi?

  // Canlı GPS Dinleyicisi
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocationSystem();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Bellek sızıntısını önlemek için
    super.dispose();
  }

  // Hem önbelleği hem canlı GPS'i sırayla başlatan sistem
  Future<void> _initializeLocationSystem() async {
    await _loadLastKnownLocation();
    await _determinePosition();
  }

  Future<void> _loadLastKnownLocation() async {
    final lastPos = await _cacheService.getOfflineLocation();
    if (lastPos != null) {
      setState(() {
        _cachedMapPosition = lastPos;
      });
    }
  }

  // --- GÜNCELLENEN FONKSİYON: İzin Kontrolü ve Optimize Canlı Takip ---
  Future<void> _determinePosition() async {
    // 1. İZİN KONTROLÜ (GÖREV 2)
    bool hasPermission = await _locationService.checkAndRequestPermission();

    setState(() {
      _hasLocationPermission = hasPermission;
    });

    // GUARD YAPISI: İzin yoksa fonksiyonu tamamen durdur.
    if (!hasPermission) {
      print("🚨 GUARD: İzin verilmedi, sistem kilitlendi.");
      return;
    }

    // 2. ENERJİ OPTİMİZASYONLU CANLI TAKİP (GÖREV 1 ve 4)
    // Sadece ilk konumu almak yerine kullanıcının 25 metre hareket etmesini dinliyoruz.
    _positionStreamSubscription = _locationService.getOptimizedLocationStream().listen((Position position) {
      print("📍 DEDEKTİF (OPTİMİZE): GPS Konumu Güncellendi! ${position.latitude}, ${position.longitude}");

      setState(() {
        myLiveLocation = LatLng(position.latitude, position.longitude);
        _cachedMapPosition = myLiveLocation!; // Merkeze al
      });
    });
  }

  Future<void> _simulateEmergency() async {
    setState(() => _isSimulating = true);

    try {
      final targetPos = myLiveLocation ?? _cachedMapPosition;

      await _firebaseService.sendEmergencyPing(
          "demo_user_ali",
          "aile_grubu_1",
          targetPos.latitude,
          targetPos.longitude
      );

      // SİNYAL BAŞARIYLA GİTTİĞİNDE DURUMU GÜNCELLE
      setState(() {
        _sosSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("DURUMUNUZ BİLDİRİLDİ! Artık diğerlerini görebilirsiniz."),
            backgroundColor: Colors.green,
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
    // --- GÖREV 2: İZİN YOKSA UYGULAMAYI İŞLEVSİZ BIRAKMA (KİLİT EKRANI) ---
    if (!_hasLocationPermission) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Konum İzni Gerekli!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Afet anında size ulaşılabilmesi için bu uygulamanın konum iznine 'Her Zaman' veya 'Kullanırken' şeklinde izin vermelisiniz. Aksi takdirde uygulama kullanılamaz.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _initializeLocationSystem,
                  icon: const Icon(Icons.refresh),
                  label: const Text("İzni Tekrar İste / Ayarları Aç"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    // --- İZİN VARSA NORMAL HARİTA EKRANI ---
    final currentCenter = myLiveLocation ?? _cachedMapPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Afet İletişim"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getEmergencyPings("aile_grubu_1"),
        builder: (context, snapshot) {

          List<Marker> allMarkers = [];

          allMarkers.add(
            Marker(
              point: currentCenter,
              width: 60,
              height: 60,
              child: const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 45),
            ),
          );

          // 2. DİĞERLERİNİ GÖSTERME MANTIĞI (Filtreli)
          // Şart: Sadece kullanıcı SOS gönderdiyse (_sosSent == true) göster
          if (_sosSent && snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              // KURAL 1: Gelen veri senin kendi user_id'n olmamalı (kırmızı pin gelmesin)
              // KURAL 2: Veri bir GeoPoint olmalı
              if (data['user_id'] != "demo_user_ali" &&
                  data['location'] != null &&
                  data['location'] is GeoPoint) {

                GeoPoint geoPoint = data['location'];

                allMarkers.add(
                  Marker(
                    point: LatLng(geoPoint.latitude, geoPoint.longitude),
                    width: 50,
                    height: 50,
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
                tileProvider: FMTCStore('kampus_haritasi').getTileProvider(),
              ),
              MarkerLayer(markers: allMarkers),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSimulating ? null : _simulateEmergency,
        backgroundColor: Colors.red,
        icon: _isSimulating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: Text(
          _isSimulating ? "SİNYAL GÖNDERİLİYOR..." : "DEPREM SİMÜLASYONU",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}