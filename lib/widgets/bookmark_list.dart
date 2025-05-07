import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/time_recommender.dart';
import '../services/geo_recommender.dart';

class BookmarkList extends StatefulWidget {
  const BookmarkList({super.key});

  @override
  State<BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends State<BookmarkList> {
  final String _userId = 'test_user';

  String? _timeRecommendation;
  String? _locationRecommendation;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    // 1) 시간 기반 추천 불러오기
    final timeRecs = await getTimeBasedRecommendation(_userId);
    // 2) 위치 기반 추천 불러오기
    final placeRecs = await getPlaceBasedRecommendation(_userId);

    setState(() {
      _timeRecommendation =
          timeRecs.isNotEmpty ? '${DateTime.now().hour}시 추천: ${timeRecs.first}' : null;
      _locationRecommendation =
          placeRecs.isNotEmpty ? '📍 추천: ${placeRecs.first}' : null;
    });
  }

  void _logBookmarkView(String bookmarkId, List<String> tags) async {
    final now = DateTime.now();
    // 1) logs 컬렉션에 열람 기록 저장
    await FirebaseFirestore.instance.collection('logs').add({
      'userId': _userId,
      'bookmarkId': bookmarkId,
      'tags': tags,
      'location': _locationRecommendation ?? '알 수 없음',
      'hour': now.hour,
      'timestamp': Timestamp.now(),
    });

    // 2) 해당 북마크의 wasOpened 업데이트
    final snap = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: _userId)
        .where('id', isEqualTo: bookmarkId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('bookmarks')
          .doc(snap.docs.first.id)
          .update({'wasOpened': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 기반 추천
        if (_timeRecommendation != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '🕒 $_timeRecommendation',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        // 위치 기반 추천
        if (_locationRecommendation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _locationRecommendation!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        // 기존 Bookmark 리스트
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookmarks')
                .where('userId', isEqualTo: _userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('저장된 북마크가 없습니다.'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final title = doc['title'] as String;
                  final tags = List<String>.from(doc['tags'] as List);
                  final bid = doc['id'] as String;

                  return ListTile(
                    title: Text(title),
                    subtitle: Text('태그: ${tags.join(', ')}'),
                    trailing: ElevatedButton(
                      onPressed: () => _logBookmarkView(bid, tags),
                      child: const Text('열람'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
