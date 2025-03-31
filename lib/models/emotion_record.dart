import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionRecord {
  final String emotion;
  final String emoji;
  final DateTime timestamp;
  final String? details;
  final String? id;
  final String? userId;
  final List<String> tags; // 감정 태그 (업무, 가족, 건강 등)
  final bool isCustomEmotion; // 사용자 정의 감정 여부
  final String? imageUrl; // 이미지 첨부 URL
  final String? videoUrl; // 동영상 첨부 URL
  final String? audioUrl; // 음성 메모 첨부 URL
  final String? diaryContent; // 감정 일기 내용

  EmotionRecord({
    required this.emotion,
    required this.emoji,
    required this.timestamp,
    this.details,
    this.id,
    this.userId,
    this.tags = const [], // 기본값은 빈 목록
    this.isCustomEmotion = false, // 기본값은 false (기본 감정)
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.diaryContent,
  });

  // JSON 직렬화/역직렬화
  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    if (json['timestamp'] is String) {
      timestamp = DateTime.parse(json['timestamp']);
    } else if (json['timestamp'] is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else {
      timestamp = DateTime.now();
    }

    return EmotionRecord(
      emotion: json['emotion'] ?? '',
      emoji: json['emoji'] ?? '',
      timestamp: timestamp,
      details: json['details'],
      id: json['id'],
      userId: json['userId'],
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : [],
      isCustomEmotion: json['isCustomEmotion'] ?? false,
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      diaryContent: json['diaryContent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'emoji': emoji,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'tags': tags,
      'isCustomEmotion': isCustomEmotion,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'diaryContent': diaryContent,
    };
  }

  EmotionRecord copyWith({
    String? emotion,
    String? emoji,
    DateTime? timestamp,
    String? details,
    String? id,
    String? userId,
    List<String>? tags,
    bool? isCustomEmotion,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    String? diaryContent,
  }) {
    return EmotionRecord(
      emotion: emotion ?? this.emotion,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
      isCustomEmotion: isCustomEmotion ?? this.isCustomEmotion,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      diaryContent: diaryContent ?? this.diaryContent,
    );
  }

  @override
  String toString() {
    return 'EmotionRecord(emotion: $emotion, emoji: $emoji, timestamp: $timestamp, details: $details, id: $id, userId: $userId, tags: $tags, isCustomEmotion: $isCustomEmotion, imageUrl: $imageUrl, videoUrl: $videoUrl, audioUrl: $audioUrl, diaryContent: $diaryContent)';
  }
} 