// lib/views/home_view.dart

import 'package:flutter/material.dart';
import '../controllers/recommendation_controller.dart';
import 'bookmark_list_view.dart';

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

    // 초기 위치 요청 (위치 캐시 warm-up 용)
    _ctrl.initializeLocation();

    // 시간 기반 추천: 시 단위 변화 감지하여 자동 갱신
    _ctrl.startTimeRecommendation((rec) {
      if (mounted) setState(() => _timeRec = rec);
    });

    // 위치 기반 추천: 일정 거리 이상 이동 시 갱신
    _ctrl.startListeningLocation(onUpdate: (rec) {
      if (mounted) setState(() => _placeRec = rec);
    });
  }

  @override
  void dispose() {
    // 위치 리스너 종료
    _ctrl.stopListeningLocation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReMark 홈')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 기반 추천 문구
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _timeRec,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 위치 기반 추천 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _placeRec.isEmpty ? "📡 위치 기반 추천 불러오는 중..." : _placeRec,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 북마크 리스트 영역
          Expanded(
            child: BookmarkListView(
              controller: _ctrl,
              onOpened: () async {
                final rec = await _ctrl.loadTimeRec();
                if (mounted) setState(() => _timeRec = rec);
              },
            ),
          ),
        ],
      ),
    );
  }
}
