import 'package:cloud_firestore/cloud_firestore.dart';

class QuestProgress {
  final int questId;
  final DateTime startTime;
  DateTime? completionTime;
  final List<String> checkPoints;
  bool isCompleted;

  QuestProgress({
    required this.questId,
    required this.startTime,
    this.completionTime,
    List<String>? checkPoints,
    this.isCompleted = false,
  }) : checkPoints = checkPoints ?? [];

  // 진행률 계산 (완료된 체크포인트 / 전체 체크포인트)
  double get progress {
    if (checkPoints.isEmpty) return 0.0;
    int completedCount = checkPoints.where((cp) => cp.startsWith('✓')).length;
    return completedCount / checkPoints.length;
  }

  // 경과 시간 계산
  Duration get elapsedTime {
    final endTime = completionTime ?? DateTime.now();
    return endTime.difference(startTime);
  }

  // JSON 변환
  Map<String, dynamic> toJson() => {
    'questId': questId,
    'startTime': startTime.millisecondsSinceEpoch,
    'completionTime': completionTime?.millisecondsSinceEpoch,
    'checkPoints': checkPoints,
    'isCompleted': isCompleted,
  };

  // JSON에서 생성
  factory QuestProgress.fromJson(Map<String, dynamic> json) => QuestProgress(
    questId: json['questId'],
    startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
    completionTime: json['completionTime'] != null 
      ? DateTime.fromMillisecondsSinceEpoch(json['completionTime'])
      : null,
    checkPoints: List<String>.from(json['checkPoints'] ?? []),
    isCompleted: json['isCompleted'] ?? false,
  );
  
  // Firestore에서 생성
  factory QuestProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestProgress.fromJson(data);
  }

  // 체크포인트 완료 처리
  void completeCheckpoint(int index) {
    if (index >= 0 && index < checkPoints.length) {
      if (!checkPoints[index].startsWith('✓')) {
        checkPoints[index] = '✓ ${checkPoints[index]}';
      }
    }
  }

  // 퀘스트 완료 처리
  void complete() {
    isCompleted = true;
    completionTime = DateTime.now();
  }
} 