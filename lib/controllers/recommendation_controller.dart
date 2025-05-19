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
    return '[$hour시] 추천 : $title';
  }

  /// 장소 기반 추천 문자열 (Cloud Function 사용)
  Future<String> loadPlaceRec() async {
    final result = await getPlaceRecommendation(userId);
    final placeType = result.placeType;
    final recs = result.recommendations;
    final title = recs.isNotEmpty ? recs.first : '없음';
    return '[$placeType]에서 추천: $title';
  }

  /// 북마크 열람 로그 기록
  Future<void> logView(
    String docId,
    List<String> tags,
  ) async {
    final result = await getPlaceRecommendation(userId);
    final placeType = result.placeType;

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

    await col
        .collection('bookmarks')
        .doc(docId)
        .update({'wasOpened': true});
  }
}