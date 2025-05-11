// lib/views/bookmark_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';
import '../controllers/recommendation_controller.dart';

class BookmarkListView extends StatelessWidget {
  final RecommendationController controller;
  final Future<void> Function() onOpened;

  const BookmarkListView({
    Key? key,
    required this.controller,
    required this.onOpened,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: controller.userId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('저장된 북마크가 없습니다.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final docSnap = docs[i];
            final bm = Bookmark.fromJson(docSnap.data() as Map<String, dynamic>);
            final docId = docSnap.id;

            return ListTile(
              title: Text(bm.title),
              subtitle: Text('태그: ${bm.tags.join(', ')}'),
              trailing: ElevatedButton(
                onPressed: () async {
                  // 1) 로그 기록 & wasOpened 업데이트
                  await controller.logView(docId, bm.tags);
                  // 2) HomeView로 콜백 호출 → 추천 갱신
                  await onOpened();
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
