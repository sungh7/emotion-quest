import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final int level;
  final int experience;
  final List<String> completedQuests;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.level = 1,
    this.experience = 0,
    this.completedQuests = const [],
    this.preferences = const {},
    this.metadata = const {},
    required this.createdAt,
    required this.lastLogin,
  });

  // 객체 복사 및 수정을 위한 메서드
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    int? level,
    int? experience,
    List<String>? completedQuests,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      completedQuests: completedQuests ?? this.completedQuests,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'level': level,
      'experience': experience,
      'completedQuests': completedQuests,
      'preferences': preferences,
      'metadata': metadata,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  // JSON 역직렬화
  factory User.fromJson(Map<String, dynamic> json) {
    // Timestamp -> DateTime 변환 처리
    DateTime parseDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      }
      return DateTime.now(); // 기본값
    }

    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoURL: json['photoURL'] as String?,
      level: json['level'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      completedQuests: json['completedQuests'] != null
          ? List<String>.from(json['completedQuests'])
          : [],
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: parseDateTime(json['createdAt']),
      lastLogin: parseDateTime(json['lastLogin']),
    );
  }

  // 문자열 표현
  @override
  String toString() {
    return 'User{id: $id, email: $email, displayName: $displayName, level: $level, experience: $experience}';
  }
} 