class QuestProgress {
  final String questId;
  final DateTime startTime;
  final List<String> checkPoints;
  final List<bool> completedCheckpoints;
  DateTime? completionTime;

  QuestProgress({
    required this.questId,
    required this.startTime,
    required this.checkPoints,
    this.completedCheckpoints = const [],
    this.completionTime,
  }) : assert(checkPoints.isNotEmpty);

  // 경과 시간 계산
  Duration get elapsedTime {
    final now = DateTime.now();
    return completionTime != null
        ? completionTime!.difference(startTime)
        : now.difference(startTime);
  }

  // 완료 여부 체크
  bool get isCompleted => completionTime != null;

  // 유효한 체크포인트 인덱스인지 확인
  bool isValidCheckpointIndex(int index) {
    return index >= 0 && index < checkPoints.length;
  }

  // 체크포인트 상태 조회
  bool isCheckpointCompleted(int index) {
    if (!isValidCheckpointIndex(index)) return false;
    if (completedCheckpoints.length <= index) return false;
    return completedCheckpoints[index];
  }

  // 체크포인트 완료 처리
  void completeCheckpoint(int index) {
    if (!isValidCheckpointIndex(index)) return;
    
    // 체크포인트 배열 크기 확장
    while (completedCheckpoints.length <= index) {
      completedCheckpoints.add(false);
    }
    
    completedCheckpoints[index] = true;
    
    // 모든 체크포인트가 완료되었는지 확인
    bool allCompleted = true;
    for (int i = 0; i < checkPoints.length; i++) {
      if (!isCheckpointCompleted(i)) {
        allCompleted = false;
        break;
      }
    }
    
    // 모든 체크포인트가 완료되면 퀘스트 완료 처리
    if (allCompleted) {
      complete();
    }
  }

  // 퀘스트 완료 처리
  void complete() {
    if (completionTime == null) {
      completionTime = DateTime.now();
    }
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'questId': questId,
      'startTime': startTime.toIso8601String(),
      'checkPoints': checkPoints,
      'completedCheckpoints': completedCheckpoints,
      'completionTime': completionTime?.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory QuestProgress.fromJson(Map<String, dynamic> json) {
    return QuestProgress(
      questId: json['questId'],
      startTime: DateTime.parse(json['startTime']),
      checkPoints: List<String>.from(json['checkPoints']),
      completedCheckpoints: List<bool>.from(json['completedCheckpoints'] ?? []),
      completionTime: json['completionTime'] != null
          ? DateTime.parse(json['completionTime'])
          : null,
    );
  }
} 