import 'package:flutter/material.dart';
import '../services/time_recommender.dart';
import '../services/geo_recommender.dart';

class RecommendButtons extends StatelessWidget {
  const RecommendButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final rec = await getTimeBasedRecommendation('test_user');
            final msg = rec.isEmpty ? '추천할 콘텐츠가 없습니다.' : '시간 추천: ${rec.first}';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          },
          child: const Text('🕒 시간대 기반 추천 보기'),
        ),
        ElevatedButton(
          onPressed: () async {
            final rec = await getPlaceBasedRecommendation('test_user');
            final msg = rec.isEmpty ? '추천할 콘텐츠가 없습니다.' : '위치 추천: ${rec.first}';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          },
          child: const Text('📍 위치 기반 추천 보기'),
        ),
      ],
    );
  }
}