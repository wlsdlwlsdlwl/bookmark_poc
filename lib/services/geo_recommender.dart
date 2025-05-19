import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// 현재 위치를 얻어오는 유틸
Future<Position> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('🔒 위치 서비스가 비활성화되어 있어요.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('📍 위치 권한이 거부되었어요.');
    }
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.bestForNavigation,
  );
}

Future<PlaceRecommendationResult> getPlaceRecommendation(String userId) async {
  try {
    final position = await getCurrentLocation();

    final callable = FirebaseFunctions.instance.httpsCallable('geoRecommender');
    final result = await callable.call({
      'userId': userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    final data = result.data;
    final placeType = data['placeType'] ?? '알 수 없음';
    final recs = List<String>.from(data['recommendations'] ?? []);

    return PlaceRecommendationResult(placeType, recs);
  } catch (e) {
    print('❌ 장소 추천 실패: $e');
    return PlaceRecommendationResult('알 수 없음', []);
  }
}

class PlaceRecommendationResult {
  final String placeType;
  final List<String> recommendations;

  PlaceRecommendationResult(this.placeType, this.recommendations);
}