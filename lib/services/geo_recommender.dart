import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

String? _cachedPlaceType;
DateTime? _cacheTime;

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

/// 공통: Places API로부터 현재 장소 유형(한글)만 가져오는 내부 헬퍼
Future<String> _fetchPrimaryPlaceType() async {
  final position = await getCurrentLocation();
  final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY']!;
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

  final headers = {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': 'places.primaryTypeDisplayName.text',
  };
  final body = jsonEncode({
    'languageCode': 'ko',
    'maxResultCount': 1,
    'locationRestriction': {
      'circle': {
        'center': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'radius': 100.0,
      }
    }
  });

  final resp = await http.post(url, headers: headers, body: body);
  if (resp.statusCode != 200) return '알 수 없음';
  final data = jsonDecode(resp.body);
  return (data['places']?[0]?['primaryTypeDisplayName']?['text'] as String?) ?? '알 수 없음';
}

/// 캐싱된 장소 유형 반환
Future<String> getCurrentPlaceType() async {
  // ① 10분 이내 캐시가 있으면 그대로 반환
  if (_cachedPlaceType != null && _cacheTime != null) {
    final diff = DateTime.now().difference(_cacheTime!);
    if (diff.inMinutes < 10) {
      print("⚡ 캐시된 장소 유형 사용: $_cachedPlaceType");
      return _cachedPlaceType!;
    }
  }

  // ② 없으면 새로 불러오고, 캐시에 저장
  final placeType = await _fetchPrimaryPlaceType();
  _cachedPlaceType = placeType;
  _cacheTime = DateTime.now();
  print("🆕 새 장소 유형 캐시됨: $placeType");
  return placeType;
}

/// 외부에서 호출: 캐시 무효화
void invalidatePlaceTypeCache() {
  _cachedPlaceType = null;
  _cacheTime = null;
}