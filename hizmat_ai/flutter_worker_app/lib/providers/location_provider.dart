import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

class LocationNotifier extends StateNotifier<Position?> {
  LocationNotifier() : super(null);

  Future<void> fetchCurrentLocation(LocationService service) async {
    final pos = await service.getCurrentPosition();
    state = pos;
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, Position?>((ref) {
  return LocationNotifier();
});
