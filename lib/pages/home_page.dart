// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../widgets/recommend_buttons.dart';
import '../widgets/bookmark_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReMark 홈')),
      body: Column(
        children: const [
          RecommendButtons(),   // 시간·위치 기반 추천 버튼
          Expanded(child: BookmarkList()),  // 북마크 리스트
        ],
      ),
    );
  }
}