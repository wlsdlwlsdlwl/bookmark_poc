// lib/views/bookmark_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';
import '../controllers/recommendation_controller.dart';

class BookmarkListView extends StatelessWidget {
  const BookmarkListView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = RecommendationController(); // PoC라 간단히 새로 생성

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: ctrl.userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('저장된 북마크가 없습니다.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final docSnap = docs[i];
            final bm = Bookmark.fromJson(docSnap.data() as Map<String, dynamic>);
            final docId = docSnap.id; // Firestore 문서의 실제 ID

            return ListTile(
              title: Text(bm.title),
              subtitle: Text('태그: ${bm.tags.join(', ')}'),
              trailing: ElevatedButton(
                onPressed: () async {
                  // 1) 로그 기록 & wasOpened 업데이트
                  await ctrl.logView(docId, bm.tags);
                  // 2) (선택) HomeView의 추천을 즉시 갱신하려면 Context를 통해 호출
                  // final homeState = context.findAncestorStateOfType<_HomeViewState>();
                  // await homeState?._loadRecs();
                },
                child: const Text('열람'),
              ),
            );
          },
        );
      },
    );
  }
}
