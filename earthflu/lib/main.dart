import 'package:flutter/material.dart';
import 'screens/map_screen.dart'; // Eğer map_screen'i screens klasörüne koyduysan 'screens/map_screen.dart' yap

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Afet Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: CampusMapScreen(), // İlk açılacak ekran senin haritan
    );
  }
}