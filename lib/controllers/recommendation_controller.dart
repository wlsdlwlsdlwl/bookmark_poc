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

  /// 장소 기반 추천 문자열
  Future<String> loadPlaceRec() async {
    // 1) 현재 장소 유형 한글로
    final placeType = await getCurrentPlaceType();  
    // 2) 해당 장소 기반 추천 북마크 제목
    final list = await getPlaceBasedRecommendation(userId);
    final title = list.isNotEmpty ? list.first : '없음';
    return '[$placeType]에서 추천 : $title';
  }

  Future<void> logView(
    String docId,          // 실제 Firestore 문서 ID
    List<String> tags,
  ) async {
    // 1) 순수 장소 유형 조회
    final placeType = await getCurrentPlaceType();

    // 2) 로그 기록
    final now = DateTime.now();
    final col = FirebaseFirestore.instance;
    await col.collection('logs').add({
      'userId': userId,
      'bookmarkDocId': docId,  // (선택) docId를 저장해도 좋습니다
      'tags': tags,
      'location': placeType,
      'hour': now.hour,
      'timestamp': Timestamp.now(),
    });

    // 3) wasOpened 업데이트: 쿼리 대신 바로 문서 ID로
    await col
        .collection('bookmarks')
        .doc(docId)
        .update({'wasOpened': true});
  }
}