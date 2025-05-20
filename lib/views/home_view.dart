// lib/views/home_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  Timer? _timer;                            // 시간 업데이트용
  StreamSubscription<Position>? _posSub;    // 위치 업데이트용

  @override
  void initState() {
    super.initState();
    _triggerInitialLocation(); // 👉 추가
    _scheduleTimeUpdates();
    _listenLocationUpdates();
  }

  void _triggerInitialLocation() async {
  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    print("🌍 초기 위치 확인: ${pos.latitude}, ${pos.longitude}");
  } catch (e) {
    print("❌ 초기 위치 확인 실패: $e");
  }
}

  /// 1) 시간 기반 추천을 매 분마다 재계산
  void _scheduleTimeUpdates() {
    // 즉시 한 번 실행
    _updateTimeRec();
    // 매 1분마다, 또는 분이 달라지면 재계산
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeRec();
    });
  }

  Future<void> _updateTimeRec() async {
    final rec = await _ctrl.loadTimeRec();
    setState(() => _timeRec = rec);
  }

  /// 2) 위치 변화가 감지될 때마다 장소 추천 재계산
  void _listenLocationUpdates() {
    // 권한 등은 컨트롤러 안에서 이미 처리한다고 가정
    final settings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 50, // 50m 이상 이동 시만 이벤트 발생
    );
    _posSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((_) async {
        _ctrl.invalidateLocationCache(); // ✅ 컨트롤러 경유 호출

      final rec = await _ctrl.loadPlaceRec();
      if (mounted) setState(() => _placeRec = rec);
    });
  }


  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReMark 홈')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 라이브 시간 추천
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_timeRec, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          // 라이브 위치 추천
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _placeRec.isEmpty ? "📡 위치 기반 추천 불러오는 중..." : _placeRec,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // 북마크 리스트
          Expanded(
            child: BookmarkListView(
              controller: _ctrl,
              onOpened: _updateTimeRec, // “열람” 시에도 시간 추천 즉시 업데이트
            ),
          ),
        ],
      ),
    );
  }
}