// lib/services/geo_recommender.dart

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

String? _cachedPlaceType;
DateTime? _cacheTime;

/// 내부: Google Places API를 통해 장소 유형(한글)을 가져오는 함수
Future<String> _fetchPrimaryPlaceType(Position position) async {
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

/// 외부에서 위치(Position)를 받아 장소 유형을 반환 (캐시 사용 포함)
Future<String> getPlaceTypeFromPosition(Position position) async {
  // ① 캐시가 유효하면 반환
  if (_cachedPlaceType != null && _cacheTime != null) {
    final diff = DateTime.now().difference(_cacheTime!);
    if (diff.inMinutes < 10) {
      print("⚡ 캐시된 장소 유형 사용: $_cachedPlaceType");
      return _cachedPlaceType!;
    }
  }

  // ② 새로 호출
  final placeType = await _fetchPrimaryPlaceType(position);
  _cachedPlaceType = placeType;
  _cacheTime = DateTime.now();
  print("🆕 새 장소 유형 캐시됨: $placeType");
  return placeType;
}

/// 외부에서 호출: 장소 캐시 무효화
void invalidatePlaceTypeCache() {
  _cachedPlaceType = null;
  _cacheTime = null;
}