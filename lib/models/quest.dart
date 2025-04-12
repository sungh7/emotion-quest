import 'dart:convert';

class Quest {
  final String id;
  final String title;
  final String description;
  final String category;
  final int difficulty;
  final List<String> checkpoints;
  final String emoji;
  final int experiencePoints;
  final Map<String, dynamic>? rewards;
  final Map<String, dynamic>? metadata;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.checkpoints,
    required this.emoji,
    required this.experiencePoints,
    this.rewards,
    this.metadata,
  });

  // 복사 메서드
  Quest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? difficulty,
    List<String>? checkpoints,
    String? emoji,
    int? experiencePoints,
    Map<String, dynamic>? rewards,
    Map<String, dynamic>? metadata,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      checkpoints: checkpoints ?? this.checkpoints,
      emoji: emoji ?? this.emoji,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      rewards: rewards ?? this.rewards,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'checkpoints': checkpoints,
      'emoji': emoji,
      'experiencePoints': experiencePoints,
      'rewards': rewards,
      'metadata': metadata,
    };
  }

  // JSON에서 객체 생성
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      checkpoints: List<String>.from(json['checkpoints'] ?? []),
      emoji: json['emoji'],
      experiencePoints: json['experiencePoints'],
      rewards: json['rewards'],
      metadata: json['metadata'],
    );
  }

  // 문자열 표현
  @override
  String toString() {
    return 'Quest{id: $id, title: $title, category: $category, difficulty: $difficulty}';
  }
} 