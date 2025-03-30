// 디지털 웰빙 데이터를 저장하는 모델
class DigitalWellbeingData {
  final DateTime date;
  final String? id;
  final String? userId;
  final Map<String, int> appUsage; // 앱별 사용 시간(초)
  final int totalScreenTime; // 총 스크린 타임(초)
  final int unlockCount; // 스마트폰 잠금 해제 횟수
  final int notificationCount; // 알림 수신 횟수
  final DateTime? wakeupTime; // 기상 시간
  final DateTime? sleepTime; // 취침 시간
  final Map<String, int>? hourlyUsage; // 시간대별 사용 시간(초)
  final Map<String, dynamic>? additionalData; // 확장성을 위한 추가 데이터

  DigitalWellbeingData({
    required this.date,
    this.id,
    this.userId,
    required this.appUsage,
    required this.totalScreenTime,
    this.unlockCount = 0,
    this.notificationCount = 0,
    this.wakeupTime,
    this.sleepTime,
    this.hourlyUsage,
    this.additionalData,
  });

  // JSON 직렬화/역직렬화
  factory DigitalWellbeingData.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final DateTime date = dateStr != null 
        ? DateTime.parse(dateStr) 
        : DateTime.now();
    
    final Map<String, dynamic> rawAppUsage = json['appUsage'] as Map<String, dynamic>? ?? {};
    final Map<String, int> appUsage = {};
    rawAppUsage.forEach((key, value) {
      if (value is int) {
        appUsage[key] = value;
      } else if (value is String) {
        appUsage[key] = int.tryParse(value) ?? 0;
      }
    });
    
    final Map<String, dynamic>? rawHourlyUsage = json['hourlyUsage'] as Map<String, dynamic>?;
    final Map<String, int>? hourlyUsage = rawHourlyUsage != null ? {} : null;
    if (rawHourlyUsage != null) {
      rawHourlyUsage.forEach((key, value) {
        if (value is int) {
          hourlyUsage![key] = value;
        } else if (value is String) {
          hourlyUsage![key] = int.tryParse(value) ?? 0;
        }
      });
    }
    
    return DigitalWellbeingData(
      date: date,
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      appUsage: appUsage,
      totalScreenTime: json['totalScreenTime'] as int? ?? 0,
      unlockCount: json['unlockCount'] as int? ?? 0,
      notificationCount: json['notificationCount'] as int? ?? 0,
      wakeupTime: json['wakeupTime'] != null 
          ? DateTime.parse(json['wakeupTime'] as String) 
          : null,
      sleepTime: json['sleepTime'] != null 
          ? DateTime.parse(json['sleepTime'] as String) 
          : null,
      hourlyUsage: hourlyUsage,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'appUsage': appUsage,
      'totalScreenTime': totalScreenTime,
      'unlockCount': unlockCount,
      'notificationCount': notificationCount,
      if (wakeupTime != null) 'wakeupTime': wakeupTime!.toIso8601String(),
      if (sleepTime != null) 'sleepTime': sleepTime!.toIso8601String(),
      if (hourlyUsage != null) 'hourlyUsage': hourlyUsage,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }

  DigitalWellbeingData copyWith({
    DateTime? date,
    String? id,
    String? userId,
    Map<String, int>? appUsage,
    int? totalScreenTime,
    int? unlockCount,
    int? notificationCount,
    DateTime? wakeupTime,
    DateTime? sleepTime,
    Map<String, int>? hourlyUsage,
    Map<String, dynamic>? additionalData,
  }) {
    return DigitalWellbeingData(
      date: date ?? this.date,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appUsage: appUsage ?? this.appUsage,
      totalScreenTime: totalScreenTime ?? this.totalScreenTime,
      unlockCount: unlockCount ?? this.unlockCount,
      notificationCount: notificationCount ?? this.notificationCount,
      wakeupTime: wakeupTime ?? this.wakeupTime,
      sleepTime: sleepTime ?? this.sleepTime,
      hourlyUsage: hourlyUsage ?? this.hourlyUsage,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  @override
  String toString() {
    return 'DigitalWellbeingData(date: $date, id: $id, userId: $userId, totalScreenTime: $totalScreenTime, unlockCount: $unlockCount, appUsage: $appUsage)';
  }
} 