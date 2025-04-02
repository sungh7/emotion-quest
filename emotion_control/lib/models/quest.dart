class Quest {
  final int id;
  final String title;
  final String emotion;
  final String task;
  final String difficulty;
  final int expReward;  // 난이도별 경험치 보상

  const Quest({
    required this.id,
    required this.title,
    required this.emotion,
    required this.task,
    required this.difficulty,
    required this.expReward,
  });

  // CSV 데이터로부터 Quest 객체 생성
  factory Quest.fromCsv(Map<String, dynamic> data) {
    // 필드 검증 및 기본값 설정
    final idStr = data[''] ?? '0';
    int id;
    try {
      id = int.parse(idStr);
    } catch (e) {
      id = 0;
      print('ID 파싱 오류: $idStr, 기본값 0으로 설정');
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
      id: id,
      title: title,
      emotion: emotion,
      task: task,
      difficulty: difficulty,
      expReward: exp,
    );
  }

  // 퀘스트 데이터를 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'emotion': emotion,
      'task': task,
      'difficulty': difficulty,
      'expReward': expReward,
    };
  }
} 