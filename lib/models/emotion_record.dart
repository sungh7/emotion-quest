class EmotionRecord {
  final String id;
  final String emotion;
  final String emoji;
  final double intensity;
  final String notes;
  final DateTime timestamp;
  final List<String> tags;
  final String userId;
  final Map<String, dynamic>? metadata;

  EmotionRecord({
    required this.id,
    required this.emotion,
    required this.emoji,
    required this.intensity,
    this.notes = '',
    required this.timestamp,
    this.tags = const [],
    required this.userId,
    this.metadata,
  });

  // 복사 메서드 - 필드 업데이트에 필요
  EmotionRecord copyWith({
    String? id,
    String? emotion,
    String? emoji,
    double? intensity,
    String? notes,
    DateTime? timestamp,
    List<String>? tags,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return EmotionRecord(
      id: id ?? this.id,
      emotion: emotion ?? this.emotion,
      emoji: emoji ?? this.emoji,
      intensity: intensity ?? this.intensity,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      tags: tags ?? this.tags,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emotion': emotion,
      'emoji': emoji,
      'intensity': intensity,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'tags': tags,
      'userId': userId,
      'metadata': metadata,
    };
  }

  // JSON에서 객체 생성
  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      id: json['id'],
      emotion: json['emotion'],
      emoji: json['emoji'],
      intensity: (json['intensity'] is int)
          ? (json['intensity'] as int).toDouble()
          : json['intensity'],
      notes: json['notes'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      tags: List<String>.from(json['tags'] ?? []),
      userId: json['userId'],
      metadata: json['metadata'],
    );
  }

  // 문자열 표현
  @override
  String toString() {
    return 'EmotionRecord{id: $id, emotion: $emotion, emoji: $emoji, intensity: $intensity, timestamp: $timestamp}';
  }
} 