// lib/controllers/recommendation_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../services/time_recommender.dart';
import '../services/geo_recommender.dart';
import '../services/location_service.dart';

class RecommendationController {
  final String userId = 'test_user';
  final LocationService _locationService = LocationService();

  /// 시간 기반 추천 관련 캐시
  Timer? _timeTimer;
  int? _lastHour;
  String _lastTimeRec = '';

  /// 시 단위 시간 변경 감지하여 추천을 갱신
  void startTimeRecommendation(Function(String) onUpdated) {
    _updateTimeRecommendation(onUpdated); // 최초 실행
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeRecommendation(onUpdated);
    });
  }

  void _updateTimeRecommendation(Function(String) onUpdated) async {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (_lastHour != currentHour) {
      _lastHour = currentHour;
      final titles = await getTimeBasedRecommendation(userId);
      final result = titles.isNotEmpty
          ? '[$currentHour시]에 추천 : ${titles.first}'
          : '[$currentHour시]에 추천 : 없음';
      _lastTimeRec = result;
      onUpdated(result);
    } else {
      onUpdated(_lastTimeRec);
    }
  }

  void stopTimeRecommendation() {
    _timeTimer?.cancel();
  }

  /// 수동 호출 시 시간 추천 문자열 반환
  Future<String> loadTimeRec() async {
    final list = await getTimeBasedRecommendation(userId);
    final hour = DateTime.now().hour;
    final title = list.isNotEmpty ? list.first : '없음';
    return '[$hour시]에 추천 : $title';
  }

  /// 장소 기반 추천 문자열 반환
  Future<String> loadPlaceRec() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return '위치 정보 없음';

    final placeType = await getPlaceTypeFromPosition(position);
    final topTag = await _getTopTag(userId, placeType);

    if (topTag == null) return '[$placeType]에서 추천 : 없음';

    final bms = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: topTag)
        .where('wasOpened', isEqualTo: false)
        .get();

    final title = bms.docs.isNotEmpty ? bms.docs.first['title'] as String : '없음';
    return '[$placeType]에서 추천 : $title';
  }

  /// Firestore에서 장소 기반 로그 중 최빈 태그 추출
  Future<String?> _getTopTag(String userId, String placeType) async {
    final logs = await FirebaseFirestore.instance
        .collection('logs')
        .where('userId', isEqualTo: userId)
        .where('location', isEqualTo: placeType)
        .get();

    final tagCount = <String, int>{};
    for (var doc in logs.docs) {
      for (var tag in List<String>.from(doc['tags'])) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }

    if (tagCount.isEmpty) return null;
    return tagCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 북마크 열람 시 로그 기록
  Future<void> logView(
    String docId,
    List<String> tags,
  ) async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    final placeType = await getPlaceTypeFromPosition(position);

    final now = DateTime.now();
    final col = FirebaseFirestore.instance;
    await col.collection('logs').add({
      'userId': userId,
      'bookmarkDocId': docId,
      'tags': tags,
      'location': placeType,
      'hour': now.hour,
      'timestamp': Timestamp.now(),
    });

    await col.collection('bookmarks').doc(docId).update({'wasOpened': true});
  }

  /// 장소 캐시 무효화
  void invalidateLocationCache() {
    invalidatePlaceTypeCache();
  }

  /// 초기 위치 요청 (UI에서 호출)
  Future<void> initializeLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      print("🌍 초기 위치 확인: ${pos.latitude}, ${pos.longitude}");
    }
  }

  /// 위치 리스너 시작 (UI → View에서 콜백 전달)
  void startListeningLocation({
    required void Function(String placeRecommendation) onUpdate,
  }) {
    _locationService.startLocationListener(onLocationUpdate: (pos) async {
      invalidateLocationCache();
      final placeType = await getPlaceTypeFromPosition(pos);
      final topTag = await _getTopTag(userId, placeType);

      final rec = topTag == null
          ? '[$placeType]에서 추천 : 없음'
          : await _buildPlaceRecommendation(topTag, placeType);

      onUpdate(rec);
    });
  }

  /// 장소 기반 추천 문구 구성 로직 분리
  Future<String> _buildPlaceRecommendation(String topTag, String placeType) async {
    final bms = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('tags', arrayContains: topTag)
        .where('wasOpened', isEqualTo: false)
        .get();

    final title = bms.docs.isNotEmpty ? bms.docs.first['title'] as String : '없음';
    return '[$placeType]에서 추천 : $title';
  }

  /// 위치 리스너 종료
  void stopListeningLocation() {
    _locationService.stopLocationListener();
  }
}