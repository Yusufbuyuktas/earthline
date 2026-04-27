import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'dart:async';

import '../services/firebase_service.dart';
import '../services/location_cache_service.dart';
import '../services/location_service.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  final LocationCacheService _cacheService = LocationCacheService();
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  List<DocumentSnapshot> _dbUsers = [];
  String? _selectedUserId;
  bool _isUsersLoading = true;

  LatLng? myLiveLocation;
  LatLng _cachedMapPosition = const LatLng(40.7410, 30.3330);
  bool _isSimulating = false;
  bool _hasLocationPermission = true;
  bool _sosSent = false;

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeSystem() async {
    await _fetchUsersFromDb();
    await _loadLastKnownLocation();
    await _determinePosition();
  }

  Future<void> _fetchUsersFromDb() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('group_id', isEqualTo: 'aile_grubu_1')
          .get();

      setState(() {
        _dbUsers = snapshot.docs;
        if (_dbUsers.isNotEmpty) {
          _selectedUserId = _dbUsers[0].id;
        }
        _isUsersLoading = false;
      });
    } catch (e) {
      setState(() => _isUsersLoading = false);
    }
  }

  Future<void> _loadLastKnownLocation() async {
    final lastPos = await _cacheService.getOfflineLocation();
    if (lastPos != null) {
      setState(() {
        _cachedMapPosition = lastPos;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool hasPermission = await _locationService.checkAndRequestPermission();
    setState(() {
      _hasLocationPermission = hasPermission;
    });
    if (!hasPermission) return;

    _positionStreamSubscription = _locationService.getOptimizedLocationStream().listen((Position position) {
      setState(() {
        myLiveLocation = LatLng(position.latitude, position.longitude);
        _cachedMapPosition = myLiveLocation!;
      });
    });
  }

  Future<void> _simulateEmergency() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen önce bir kullanıcı seçin!")),
      );
      return;
    }

    setState(() => _isSimulating = true);

    try {
      final targetPos = myLiveLocation ?? _cachedMapPosition;
      await _firebaseService.sendEmergencyPing(
          _selectedUserId!,
          "aile_grubu_1",
          targetPos.latitude,
          targetPos.longitude
      );

      setState(() {
        _sosSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("DURUMUNUZ BİLDİRİLDİ! Diğerleri görünüyor."),
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
    if (!_hasLocationPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 80, color: Colors.red),
              const Text("Konum İzni Gerekli!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton(onPressed: () => _initializeSystem(), child: const Text("İzni Tekrar İste"))
            ],
          ),
        ),
      );
    }

    final currentCenter = myLiveLocation ?? _cachedMapPosition;

    // SEÇİLİ KULLANICININ İSMİNİ BULMA (Mavi Pin Altı İçin)
    String mySelectedName = "Seçili Kullanıcı";
    if (_selectedUserId != null && _dbUsers.isNotEmpty) {
      try {
        final me = _dbUsers.firstWhere((u) => u.id == _selectedUserId);
        mySelectedName = (me.data() as Map<String, dynamic>)['name'] ?? "Ben";
      } catch (e) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Afet İletişim"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        actions: [
          if (!_isUsersLoading && _dbUsers.isNotEmpty)
            DropdownButton<String>(
              dropdownColor: Colors.red[800],
              value: _selectedUserId,
              style: const TextStyle(color: Colors.white),
              items: _dbUsers.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(value: doc.id, child: Text(data['name'] ?? 'Bilinmeyen'));
              }).toList(),
              onChanged: (val) => setState(() {
                _selectedUserId = val;
                _sosSent = false; // Kullanıcı değişince haritayı sıfırla
              }),
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getEmergencyPings("aile_grubu_1"),
        builder: (context, snapshot) {
          List<Marker> allMarkers = [];

          // 1. MAVİ PİN (SEÇİLİ KULLANICI - İSİMLİ)
          allMarkers.add(
            Marker(
              point: currentCenter,
              width: 100, height: 100,
              child: Column(
                children: [
                  const Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 45),
                  Text(mySelectedName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
          );

          // 2. KIRMIZI PİNLER (DİĞERLERİ)
          if (_sosSent && snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              // KRİTİK DÜZELTME: Veri tabanından gelen ID'yi metne çevirip karşılaştır
              final String pingId = data['user_id'].toString();

              if (pingId != _selectedUserId && data['location'] is GeoPoint) {
                GeoPoint geoPoint = data['location'];
                String markerName = "Kullanıcı";

                try {
                  // KRİTİK DÜZELTME: Karşılaştırmayı String tipinde yap
                  final matchedUser = _dbUsers.firstWhere((user) => user.id == pingId);
                  markerName = (matchedUser.data() as Map<String, dynamic>)['name'] ?? "İsimsiz";
                } catch (e) {
                  markerName = "Bilinmeyen ($pingId)"; // ID'yi görelim ki hata anlaşılsın
                }

                allMarkers.add(
                  Marker(
                    point: LatLng(geoPoint.latitude, geoPoint.longitude),
                    width: 100, height: 100,
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 40),
                        Container(
                          padding: const EdgeInsets.all(2),
                          color: Colors.white70,
                          child: Text(markerName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          }

          return FlutterMap(
            options: MapOptions(initialCenter: currentCenter, initialZoom: 15.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
        label: Text(_isSimulating ? "SİNYAL GÖNDERİLİYOR..." : "DEPREM SİMÜLASYONU"),
      ),
    );
  }
}