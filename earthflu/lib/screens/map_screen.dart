import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CampusMapScreen extends StatefulWidget {
  @override
  _CampusMapScreenState createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // Kampüs Koordinatları (Şu an Sakarya Üni. merkezli)
  final LatLng kampusMerkez = LatLng(40.7410, 30.3330);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Afet İletişim - Demo"),
        backgroundColor: Colors.red[800],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: kampusMerkez,
          initialZoom: 16.0,
          maxZoom: 18.0,
          minZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.afet_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: kampusMerkez,
                width: 60,
                height: 60,
                child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}