// lib/services/time_recommender.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// 시간 기반 추천: 주 함수
Future<List<String>> getTimeBasedRecommendation(String userId) async {
  final currentHour = DateTime.now().hour;

  // 1) 해당 시간대의 태그별 열람 횟수 집계
  final tagCount = await _countTags(
    userId: userId,
    field: 'hour',
    value: currentHour,
  );

  if (tagCount.isEmpty) return [];

  // 2) 최다 열람 태그 선택
  final topTag = _selectTopTag(tagCount);

  // 3) 상위 태그 기반 미열람 북마크 제목 반환
  return _fetchUnopenedBookmarkTitles(userId, topTag);
}

/// 로그에서 주어진 필드에 해당하는 태그별 집계 생성
Future<Map<String, int>> _countTags({
  required String userId,
  required String field,
  required Object value,
}) async {
  final snap = await FirebaseFirestore.instance
      .collection('logs')
      .where('userId', isEqualTo: userId)
      .where(field, isEqualTo: value)
      .get();

  final counts = <String, int>{};
  for (var doc in snap.docs) {
    for (var tag in List<String>.from(doc['tags'])) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
}

/// 태그별 집계에서 최다 태그를 선택
String _selectTopTag(Map<String, int> counts) {
  return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

/// 미열람 상태인 북마크 중 특정 태그를 가진 제목 목록 조회
Future<List<String>> _fetchUnopenedBookmarkTitles(
    String userId, String tag) async {
  final snap = await FirebaseFirestore.instance
      .collection('bookmarks')
      .where('userId', isEqualTo: userId)
      .where('tags', arrayContains: tag)
      .where('wasOpened', isEqualTo: false)
      .get();

  return snap.docs.map((d) => d['title'] as String).toList();
}