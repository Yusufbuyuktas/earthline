import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
class CampusMapScreen extends StatefulWidget {
  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  LatLng? myLocation; // Kendi konumumuz
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _determinePosition(); // Uygulama açılınca konumumuzu al
  }

  // KENDİ KONUMUMUZU ALAN FONKSİYON
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    print("📍 DEDEKTİF: GPS Konumu başarıyla alındı! Enlem: ${position.latitude}, Boylam: ${position.longitude}");
    setState(() {
      myLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Afet İletişim")),
      body: StreamBuilder<QuerySnapshot>(
        // ARKADAŞININ YAZDIĞI SERVİSİ BURADA DİNLİYORUZ
        stream: _firebaseService.getEmergencyPings("aile_grubu_1"),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            print("🔥 DEDEKTİF: Firebase'den veri bekleniyor (Yükleniyor)...");
          }
          if (snapshot.hasError) {
            print("🔥 DEDEKTİF: FİREBASE HATASI! Veri çekilemedi: ${snapshot.error}");
          }
          if (snapshot.hasData) {
            print("🔥 DEDEKTİF: Firebase verisi geldi! Toplam Acil Durum Pini sayısı: ${snapshot.data!.docs.length}");
          }

          List<Marker> allMarkers = [];

          // 1. KENDİ KONUMUMUZU EKLEYELİM (MAVİ PİN)
          if (myLocation != null) {
            allMarkers.add(
              Marker(
                point: myLocation!,
                width: 50,
                height: 50,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 35),
              ),
            );
          }

          // 2. FİREBASE'DEN GELEN DİĞER KULLANICILARI EKLEYELİM (KIRMIZI PİNLER)
          // 2. FİREBASE'DEN GELEN DİĞER KULLANICILARI EKLEYELİM
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;

              if (data['location'] != null && data['location'] is GeoPoint) {
                GeoPoint geoPoint = data['location'];

                // 🚨 SON AJAN: Kırmızı pin tam olarak dünyanın neresinde?
                print("🚨 KIRMIZI PİN DÜNYANIN ŞU NOKTASINA DÜŞTÜ: Enlem: ${geoPoint.latitude}, Boylam: ${geoPoint.longitude}");

                allMarkers.add(
                  Marker(
                    point: LatLng(
                      geoPoint.latitude,
                      geoPoint.longitude,
                    ),
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
              initialCenter: myLocation ?? const LatLng(40.7410, 30.3330), // Varsa benim konumum, yoksa kampüs
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.quakeline',
                tileProvider: FMTCStore('kampus_haritasi').getTileProvider(),
              ),
              MarkerLayer(markers: allMarkers), // TÜM PİNLER BURADA GÖSTERİLİYOR
            ],
          );
        },
      ),
    );
  }
}