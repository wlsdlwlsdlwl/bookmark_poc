import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

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
        'radius': 50.0,
      }
    }
  });

  final resp = await http.post(url, headers: headers, body: body);
  if (resp.statusCode != 200) return '알 수 없음';
  final data = jsonDecode(resp.body);
  return (data['places']?[0]?['primaryTypeDisplayName']?['text'] as String?) ?? '알 수 없음';
}

/// 외부에 노출: 순수 장소 유형만 필요할 때
Future<String> getCurrentPlaceType() {
  return _fetchPrimaryPlaceType();
}

/// 외부에 노출: 장소 기반 추천이 필요할 때
Future<List<String>> getPlaceBasedRecommendation(String userId) async {
  // 1) 장소 유형만 꺼내고
  final placeType = await _fetchPrimaryPlaceType();

  // 2) logs에서 태그 집계
  final logs = await FirebaseFirestore.instance
      .collection('logs')
      .where('userId', isEqualTo: userId)
      .where('location', isEqualTo: placeType)
      .get();
  final tagCount = <String,int>{};
  for (var doc in logs.docs) {
    for (var tag in List<String>.from(doc['tags'])) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }
  if (tagCount.isEmpty) return [];

  final topTag = tagCount.entries.reduce((a,b) => a.value>b.value ? a : b).key;

  // 3) 북마크에서 추천 후보 추출
  final bms = await FirebaseFirestore.instance
      .collection('bookmarks')
      .where('userId', isEqualTo: userId)
      .where('tags', arrayContains: topTag)
      .where('wasOpened', isEqualTo: false)
      .get();

  return bms.docs.map((d) => d['title'] as String).toList();
}