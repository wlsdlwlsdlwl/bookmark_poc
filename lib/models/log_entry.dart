// lib/models/log_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LogEntry {
  final String id;           // Firestore 문서 ID
  final String userId;       // 사용자 ID
  final String bookmarkId;   // 열람한 북마크의 ID
  final List<String> tags;   // 해당 로그에 기록된 태그 리스트
  final String location;     // 장소 유형 (예: '카페', '약국')
  final int hour;            // 열람 시각 (0~23)
  final DateTime timestamp;  // 정확한 열람 시각 타임스탬프

  LogEntry({
    required this.id,
    required this.userId,
    required this.bookmarkId,
    required this.tags,
    required this.location,
    required this.hour,
    required this.timestamp,
  });

  /// Firestore 문서를 LogEntry로 변환
  factory LogEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogEntry(
      id: doc.id,
      userId: data['userId'] as String,
      bookmarkId: data['bookmarkId'] as String,
      tags: List<String>.from(data['tags'] as List),
      location: data['location'] as String,
      hour: data['hour'] as int,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// LogEntry를 Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'bookmarkId': bookmarkId,
        'tags': tags,
        'location': location,
        'hour': hour,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}