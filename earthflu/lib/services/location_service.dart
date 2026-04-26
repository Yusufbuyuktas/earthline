import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<Position?> getHighAccuracyLocation() async {
    bool hasPermission = await checkAndRequestPermission();

    if (!hasPermission) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Stream<Position> getOptimizedLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    );
  }
}