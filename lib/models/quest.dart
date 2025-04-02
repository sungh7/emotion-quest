// 타입 정의 명확화를 위한 export 추가
export 'quest.dart';

class Quest {
  final String id;
  final String title;
  final String description;
  final String category;
  final int rewardPoints;
  final bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.rewardPoints = 10,
    this.isCompleted = false,
  });

  // 추가된 emotion과 difficulty 게터
  String get emotion => category;
  String get difficulty => _getDifficultyFromPoints(rewardPoints);
  int get expReward => rewardPoints;

  String _getDifficultyFromPoints(int points) {
    if (points >= 100) return '상';
    if (points >= 50) return '중';
    return '하';
  }

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? rewardPoints,
    bool? isCompleted,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // CSV 데이터로부터 Quest 객체 생성
  factory Quest.fromCsv(Map<String, dynamic> data) {
    // 고유 ID 생성 로직
    String uniqueId;
    
    // ID 필드 시도
    final idStr = data[''] ?? '';
    
    if (idStr.isNotEmpty) {
      // ID 필드가 있으면 사용
      uniqueId = idStr;
    } else {
      // 없으면 퀘스트 내용 기반 해시 생성
      final hashContent = '${data['감정'] ?? ''}|${data['퀘스트'] ?? ''}|${DateTime.now().millisecondsSinceEpoch}';
      uniqueId = hashContent.hashCode.toString();
    }

    final emotion = data['감정'] ?? '알 수 없음';
    final task = data['퀘스트'] ?? '알 수 없음';
    final title = data['감정 기반 퀘스트'] ?? '[$emotion] $task';
    final difficulty = data['난이도'] ?? '중';

    // 난이도별 경험치 보상 설정
    int exp;
    switch (difficulty) {
      case '상':
        exp = 100;
        break;
      case '중':
        exp = 50;
        break;
      case '하':
        exp = 30;
        break;
      default:
        exp = 20;
    }

    return Quest(
      id: uniqueId,
      title: title,
      description: task,
      category: emotion,
      rewardPoints: exp,
      isCompleted: false,
    );
  }

  // 퀘스트 데이터를 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'rewardPoints': rewardPoints,
      'isCompleted': isCompleted,
    };
  }

  // JSON 데이터로부터 Quest 객체 생성
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      rewardPoints: json['rewardPoints'] ?? 10,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
} 