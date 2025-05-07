// lib/views/home_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/recommendation_controller.dart';
import '../models/bookmark.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _ctrl = RecommendationController();
  String _timeRec = '';
  String _placeRec = '';

  @override
  void initState() {
    super.initState();
    _loadRecs();
  }

  Future<void> _loadRecs() async {
    final t = await _ctrl.loadTimeRec();
    final p = await _ctrl.loadPlaceRec();
    setState(() {
      _timeRec = t;
      _placeRec = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReMark 홈')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 기반 추천 텍스트
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _timeRec,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 위치 기반 추천 텍스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _placeRec,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 북마크 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookmarks')
                  .where('userId', isEqualTo: _ctrl.userId)
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
                    final docId = docSnap.id; // Firestore 문서 ID

                    return ListTile(
                      title: Text(bm.title),
                      subtitle: Text('태그: ${bm.tags.join(', ')}'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          // 1) 먼저 시간 기반 추천을 새로 계산해서 _timeRec에 반영
                          await _loadRecs();
                          // 2) 그 다음 열람 처리를 해서 wasOpened=true로 업데이트
                          await _ctrl.logView(docId, bm.tags);
                        },
                        child: const Text('열람'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
