class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int expReward;
  final int pointReward;
  final bool isSecret;  // 숨겨진 업적 여부
  
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.expReward = 100,
    this.pointReward = 50,
    this.isSecret = false,
  });
}

// 사전 정의된 업적 목록
class Achievements {
  // 감정 기록 관련 업적
  static const firstRecord = Achievement(
    id: 'first_record',
    title: '첫 감정 기록',
    description: '첫 번째 감정을 기록했습니다.',
    icon: '📝',
    expReward: 100,
    pointReward: 100,
  );
  
  static const recordStreak3 = Achievement(
    id: 'record_streak_3',
    title: '3일 연속 기록',
    description: '3일 연속으로 감정을 기록했습니다.',
    icon: '🔥',
    expReward: 150,
    pointReward: 100,
  );
  
  static const recordStreak7 = Achievement(
    id: 'record_streak_7',
    title: '일주일 연속 기록',
    description: '7일 연속으로 감정을 기록했습니다.',
    icon: '🌟',
    expReward: 300,
    pointReward: 200,
  );
  
  static const recordStreak30 = Achievement(
    id: 'record_streak_30',
    title: '한 달 연속 기록',
    description: '30일 연속으로 감정을 기록했습니다.',
    icon: '👑',
    expReward: 1000,
    pointReward: 500,
  );
  
  // 감정 다양성 관련 업적
  static const emotionCollector = Achievement(
    id: 'emotion_collector',
    title: '감정 수집가',
    description: '10가지 서로 다른 감정을 기록했습니다.',
    icon: '🎭',
    expReward: 200,
    pointReward: 150,
  );
  
  static const emotionMaster = Achievement(
    id: 'emotion_master',
    title: '감정 마스터',
    description: '30가지 서로 다른 감정을 기록했습니다.',
    icon: '🎯',
    expReward: 500,
    pointReward: 300,
  );
  
  // 미디어 관련 업적
  static const mediaCollector = Achievement(
    id: 'media_collector',
    title: '미디어 수집가',
    description: '사진, 비디오, 오디오를 모두 한 번 이상 기록했습니다.',
    icon: '📸',
    expReward: 200,
    pointReward: 150,
  );
  
  // 태그 관련 업적
  static const tagMaster = Achievement(
    id: 'tag_master',
    title: '태그 마스터',
    description: '20개의 서로 다른 태그를 사용했습니다.',
    icon: '🏷️',
    expReward: 300,
    pointReward: 200,
  );
  
  // 숨겨진 업적
  static const midnightWriter = Achievement(
    id: 'midnight_writer',
    title: '한밤의 작가',
    description: '자정에 감정을 기록했습니다.',
    icon: '🌙',
    expReward: 150,
    pointReward: 100,
    isSecret: true,
  );
  
  static const allWeatherRecorder = Achievement(
    id: 'all_weather_recorder',
    title: '올웨더 기록가',
    description: '비 오는 날에도 감정을 기록했습니다.',
    icon: '☔',
    expReward: 150,
    pointReward: 100,
    isSecret: true,
  );
  
  // 모든 업적 목록
  static const List<Achievement> all = [
    firstRecord,
    recordStreak3,
    recordStreak7,
    recordStreak30,
    emotionCollector,
    emotionMaster,
    mediaCollector,
    tagMaster,
    midnightWriter,
    allWeatherRecorder,
  ];
  
  // ID로 업적 찾기
  static Achievement? findById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
} 