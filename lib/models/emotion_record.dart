class EmotionRecord {
  final String emotion;
  final String emoji;
  final DateTime timestamp;
  final String? details;
  final String? id;
  final String? userId;

  EmotionRecord({
    required this.emotion,
    required this.emoji,
    required this.timestamp,
    this.details,
    this.id,
    this.userId,
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
    };
  }

  EmotionRecord copyWith({
    String? emotion,
    String? emoji,
    DateTime? timestamp,
    String? details,
    String? id,
    String? userId,
  }) {
    return EmotionRecord(
      emotion: emotion ?? this.emotion,
      emoji: emoji ?? this.emoji,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      id: id ?? this.id,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'EmotionRecord(emotion: $emotion, emoji: $emoji, timestamp: $timestamp, details: $details, id: $id, userId: $userId)';
  }
} 