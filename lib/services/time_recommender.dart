import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<String>> getTimeBasedRecommendation(String userId) async {
  final now = DateTime.now();
  final currentHour = now.hour;

  // 1. 현재 시간대에 열람한 로그 가져오기
  final logsSnapshot = await FirebaseFirestore.instance
      .collection('logs')
      .where('userId', isEqualTo: userId)
      .where('hour', isEqualTo: currentHour) // 그냥 정확히 맞추자 (PoC니까)
      .get();

  final Map<String, int> tagCount = {};
  for (var doc in logsSnapshot.docs) {
    final tags = List<String>.from(doc['tags']);
    for (var tag in tags) {
      tagCount[tag] = (tagCount[tag] ?? 0) + 1;
    }
  }

  if (tagCount.isEmpty) return [];

  final topTag = (tagCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value)))
      .first.key;

  // 2. 아직 열람하지 않은 북마크 중 해당 태그 가진 것 추천
  final bookmarksSnapshot = await FirebaseFirestore.instance
      .collection('bookmarks')
      .where('userId', isEqualTo: userId)
      .where('wasOpened', isEqualTo: false)
      .get();

  final recommendedTitles = bookmarksSnapshot.docs
      .where((doc) {
        final tags = List<String>.from(doc['tags']);
        return tags.contains(topTag);
      })
      .map((doc) => doc['title'] as String)
      .toList();

  return recommendedTitles;
}
