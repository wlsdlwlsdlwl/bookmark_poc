import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 파싱을 위한 것도 같이 필요

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

  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

Future<List<String>> getPlaceBasedRecommendation(String userId) async {
  // 1. 현재 위치 획득
  final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.bestForNavigation,
);
  print("📍 현재 위치: ${position.latitude}, ${position.longitude}");

  // 2. Google Places API (v1) - Nearby Search 호출
  final url = Uri.parse('https://places.googleapis.com/v1/places:searchNearby');

  final headers = {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': 'AIzaSyCTdKtW-AzcRR8IDjxk_B-bIwy5tNoCi3Y', // 보안상 환경 변수로 관리 권장
    'X-Goog-FieldMask': 'places.primaryTypeDisplayName',
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
        'radius': 100.0
      }
    }
  });

  final response = await http.post(url, headers: headers, body: body);
  if (response.statusCode != 200) {
    print("❌ API 요청 실패: ${response.body}");
    return [];
  }

  final jsonData = jsonDecode(response.body);
  final displayName = jsonData['places']?[0]?['primaryTypeDisplayName']?['text'];
  print("🗂 장소 유형 (한글): $displayName");

  final location = displayName ?? '알 수 없음';

  // 3. logs 컬렉션에서 해당 장소에서 자주 본 태그 찾기
  final logsSnapshot = await FirebaseFirestore.instance
      .collection('logs')
      .where('userId', isEqualTo: userId)
      .where('location', isEqualTo: location)
      .get();

  final tagCount = <String, int>{};
  for (var doc in logsSnapshot.docs) {
    final tags = List<String>.from(doc['tags']);
    for (var tag in tags) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }

  if (tagCount.isEmpty) return [];

  // 4. 가장 많이 본 태그 선정
  final topTag = tagCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  // 5. 북마크 컬렉션에서 해당 태그 + wasOpened == false 조건으로 추천
  final bookmarksSnapshot = await FirebaseFirestore.instance
      .collection('bookmarks')
      .where('userId', isEqualTo: userId)
      .where('tags', arrayContains: topTag)
      .where('wasOpened', isEqualTo: false)
      .get();

  final recommended = bookmarksSnapshot.docs
        .where((doc) {
          final tags = List<String>.from(doc['tags']);
          return tags.contains(topTag);
        })
        .map((doc) => doc['title'] as String)
        .toList();

    return recommended;
}