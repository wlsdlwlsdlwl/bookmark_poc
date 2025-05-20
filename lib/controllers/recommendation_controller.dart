// lib/controllers/recommendation_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/time_recommender.dart';
import '../services/geo_recommender.dart';

class RecommendationController {
  final String userId = 'test_user';

  /// 시간 기반 추천 문자열
  Future<String> loadTimeRec() async {
    final list = await getTimeBasedRecommendation(userId);
    final hour = DateTime.now().hour;
    final title = list.isNotEmpty ? list.first : '없음';
    return '[$hour시]에 추천 : $title';
  }

  /// 장소 기반 추천 문자열
  Future<String> loadPlaceRec() async {
    final placeType = await getCurrentPlaceType();
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

  /// 열람 로그 기록
  Future<void> logView(
    String docId,
    List<String> tags,
  ) async {
    final placeType = await getCurrentPlaceType();

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

  void invalidateLocationCache() {
    invalidatePlaceTypeCache();
  }
}