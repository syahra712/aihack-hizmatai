import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Returns the device's current GPS position after requesting permission if
  /// needed. Returns `null` if permission is denied or a platform error occurs.
  Future<Position?> getCurrentPosition() async {
    final permissionError = await requestPermission();
    if (permissionError != null) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  /// Streams position updates every [intervalMs] milliseconds.
  Stream<Position> positionStream({int intervalMs = 30000}) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(milliseconds: intervalMs),
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// Haversine distance between two lat/lng points in kilometres.
  double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLng = _deg2rad(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  /// Requests location permission.
  /// Returns `null` if permission is granted, or an error string if denied.
  Future<String?> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. '
          'Please enable it in device settings.';
    }

    return null; // granted
  }
}
