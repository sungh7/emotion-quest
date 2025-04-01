import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  int level;
  int experience;
  int recordCount;
  DateTime lastRecordDate;

  // 생성자
  UserStats({
    this.level = 1,
    this.experience = 0,
    this.recordCount = 0,
    DateTime? lastRecordDate,
  }) : lastRecordDate = lastRecordDate ?? DateTime.now();

  // 다음 레벨에 필요한 경험치 계산
  int get nextLevelExp => level * 100;

  // 복사 생성자
  UserStats copyWith({
    int? level,
    int? experience,
    int? recordCount,
    DateTime? lastRecordDate,
  }) {
    return UserStats(
      level: level ?? this.level,
      experience: experience ?? this.experience,
      recordCount: recordCount ?? this.recordCount,
      lastRecordDate: lastRecordDate ?? this.lastRecordDate,
    );
  }

  // 경험치 추가 (레벨업 자동 계산)
  UserStats addExperience(int exp) {
    int newExp = experience + exp;
    int newLevel = level;
    
    // 레벨업 체크
    while (newExp >= nextLevelExp) {
      newExp -= nextLevelExp;
      newLevel++;
    }
    
    return copyWith(
      level: newLevel,
      experience: newExp,
    );
  }

  // 기록 카운트 증가
  UserStats incrementRecordCount() {
    return copyWith(
      recordCount: recordCount + 1,
      lastRecordDate: DateTime.now(),
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'experience': experience,
      'recordCount': recordCount,
      'lastRecordDate': lastRecordDate.millisecondsSinceEpoch,
    };
  }

  // JSON에서 생성
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      recordCount: json['recordCount'] ?? 0,
      lastRecordDate: json['lastRecordDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastRecordDate'])
          : DateTime.now(),
    );
  }
} 