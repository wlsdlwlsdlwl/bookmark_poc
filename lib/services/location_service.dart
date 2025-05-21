// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
    } catch (e) {
      print("❌ 현재 위치 요청 실패: $e");
      return null;
    }
  }

  void startLocationListener({
    required void Function(Position pos) onLocationUpdate,
  }) {
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 50,
    );

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(onLocationUpdate);
  }

  void stopLocationListener() {
    _positionSubscription?.cancel();
  }
}