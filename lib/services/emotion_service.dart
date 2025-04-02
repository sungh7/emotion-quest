import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/emotion_record.dart';
import '../repositories/emotion_repository.dart';
import 'firebase_service.dart';

/// 감정 관리 서비스
///
/// 감정 기록과 관련된 비즈니스 로직을 처리합니다.
class EmotionService extends ChangeNotifier {
  final EmotionRepository _repository;
  List<EmotionRecord> _emotionRecords = [];
  
  // 기본 감정 목록
  final List<Map<String, dynamic>> baseEmotions = [
    {'emotion': '기쁨', 'emoji': '😊', 'color': Colors.yellow},
    {'emotion': '감사', 'emoji': '🙏', 'color': Colors.green},
    {'emotion': '무기력', 'emoji': '😔', 'color': Colors.grey},
    {'emotion': '불안', 'emoji': '😨', 'color': Colors.purple},
    {'emotion': '우울', 'emoji': '😞', 'color': Colors.blue},
    {'emotion': '집중', 'emoji': '🧐', 'color': Colors.orange},
    {'emotion': '짜증', 'emoji': '😡', 'color': Colors.red},
    {'emotion': '평온', 'emoji': '😌', 'color': Colors.teal},
  ];
  
  // 사용자 정의 감정 목록
  List<Map<String, dynamic>> _customEmotions = [];

  // 기본 감정 점수
  Map<String, double> _defaultEmotionScores = {
    '기쁨': 1.0,
    '감사': 1.0,
    '평온': 0.9,
    '집중': 0.7,
    '중립': 0.5,
    '우울': 0.2,
    '짜증': 0.2,
    '불안': 0.3,
    '무기력': 0.2,
  };
  
  // 사용자 정의 감정 점수
  Map<String, double> _customEmotionScores = {};
  
  // 커스텀 감정 게터 추가
  List<Map<String, dynamic>> get customEmotions => _customEmotions;
  
  // 감정 점수 게터
  Map<String, double> get emotionScores {
    // 기본 감정 점수와 사용자 정의 점수 병합
    return {..._defaultEmotionScores, ..._customEmotionScores};
  }

  EmotionService({EmotionRepository? repository}) 
    : _repository = repository ?? EmotionRepository() {
    // 서비스 생성 시 사용자 정의 감정 불러오기 시도
    loadCustomEmotions();
    // 사용자 정의 감정 점수 불러오기
    loadCustomEmotionScores();
  }
  
  // 모든 감정 목록 (기본 + 사용자 정의)
  List<Map<String, dynamic>> get allEmotions => [
    ...baseEmotions,
    ..._customEmotions,
  ];
  
  /// 로그인 시 사용자 정의 감정 목록 불러오기
  Future<void> loadCustomEmotions() async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      _customEmotions = [];
      notifyListeners();
      return;
    }

    try {
      // 사용자의 커스텀 감정 불러오기
      final result = await FirebaseService.getCollection(
        'custom_emotions',
        queryField: 'userId',
        queryValue: user.uid
      );

      // 결과 변환
      _customEmotions = result.map((doc) {
        // 색상 값을 Color 객체로 변환
        final colorValue = doc['colorValue'] as int?;
        final color = colorValue != null 
          ? Color(colorValue) 
          : Colors.blueGrey; // 기본값
        
        return {
          'emotion': doc['emotion'] ?? '',
          'emoji': doc['emoji'] ?? '',
          'color': color,
          'isCustom': true,
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('사용자 정의 감정 불러오기 오류: $e');
      // 오류 발생 시 빈 목록 사용
      _customEmotions = [];
      notifyListeners();
    }
  }

  /// 사용자 정의 감정 점수 불러오기
  Future<void> loadCustomEmotionScores() async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      _customEmotionScores = {};
      notifyListeners();
      return;
    }

    try {
      // 사용자의 커스텀 감정 점수 불러오기
      final result = await FirebaseService.getDocument(
        'emotion_scores',
        user.uid
      );

      if (result != null && result['scores'] != null) {
        // 결과 변환
        final Map<String, dynamic> scores = result['scores'];
        _customEmotionScores = scores.map((key, value) => MapEntry(key, (value as num).toDouble()));
      } else {
        // 'scores' 필드가 없는 경우 생성
        print('사용자 정의 감정 점수가 없습니다. 기본값 생성 중...');
        _customEmotionScores = {};
        
        // 커스텀 감정에 대한 기본 점수 생성
        for (var emotion in _customEmotions) {
          final String emotionName = emotion['emotion'];
          if (emotionName.isNotEmpty) {
            _customEmotionScores[emotionName] = 0.5; // 기본 중립값
          }
        }
        
        // Firestore에 새로운 점수 문서 저장
        await FirebaseService.setDocument(
          'emotion_scores',
          user.uid,
          {'scores': _customEmotionScores}
        );
        print('기본 감정 점수 생성 완료: ${_customEmotionScores.length}개');
      }

      notifyListeners();
    } catch (e) {
      print('사용자 정의 감정 점수 불러오기 오류: $e');
      // 오류 발생 시 빈 맵 사용
      _customEmotionScores = {};
      notifyListeners();
    }
  }
  
  /// 감정 기록 목록 가져오기
  List<EmotionRecord> get emotionRecords => _emotionRecords;
  
  /// 오늘 감정 기록 카운트
  int getTodayEmotionCount() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _emotionRecords.where((record) {
      return record.timestamp.isAfter(startOfDay);
    }).length;
  }
  
  /// 오늘 기록된 감정 중 경험치를 받을 수 있는 횟수 (최대 5회)
  int getExperienceEligibleEmotionCount() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    int count = _emotionRecords.where((record) {
      return record.timestamp.isAfter(startOfDay);
    }).length;
    
    return count > 5 ? 5 : count;
  }
  
  /// 감정 기록 불러오기
  Future<void> loadEmotionRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      _emotionRecords = [];
      notifyListeners();
      return;
    }
    
    try {
      final records = await _repository.getEmotionRecords(
        userId: user.uid,
        startDate: startDate,
        endDate: endDate,
      );
      
      _emotionRecords = records.map((record) => EmotionRecord.fromJson(record)).toList();
      notifyListeners();
    } catch (e) {
      print('감정 기록 불러오기 오류: $e');
      _emotionRecords = [];
      notifyListeners();
      rethrow;
    }
  }
  
  /// 감정 기록 데이터 조회
  Future<List<EmotionRecord>> getEmotionRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      return [];
    }
    
    try {
      final records = await _repository.getEmotionRecords(
        userId: user.uid,
        startDate: startDate,
        endDate: endDate,
      );
      
      return records.map((record) => EmotionRecord.fromJson(record)).toList();
    } catch (e) {
      print('감정 기록 조회 오류: $e');
      return [];
    }
  }

  /// 전체 감정 태그 조회
  Future<List<String>> getAllTags() async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      return [];
    }
    
    try {
      // 모든 감정 기록 가져오기
      final records = await _repository.getEmotionRecords(userId: user.uid);
      
      // 모든 태그 수집
      final Set<String> tags = {};
      for (final record in records) {
        if (record['tags'] != null) {
          final recordTags = List<String>.from(record['tags']);
          tags.addAll(recordTags);
        }
      }
      
      return tags.toList();
    } catch (e) {
      print('태그 조회 오류: $e');
      return [];
    }
  }
  
  /// 감정 기록 저장
  Future<String?> saveEmotionRecord(EmotionRecord record) async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      return null;
    }
    
    try {
      // userId 추가
      final updatedRecord = record.copyWith(userId: user.uid);
      
      // 저장 요청
      final recordId = await _repository.saveEmotionRecord(updatedRecord.toJson());
      
      if (recordId != null) {
        // 로컬 목록에 추가
        final recordWithId = updatedRecord.copyWith(id: recordId);
        _emotionRecords.insert(0, recordWithId);
        notifyListeners();
      }
      
      return recordId;
    } catch (e) {
      print('감정 기록 저장 오류: $e');
      return null;
    }
  }
  
  /// 사용자 정의 감정 추가
  Future<bool> addCustomEmotion(String emotion, String emoji, Color color) async {
    // 이미 존재하는지 확인
    final exists = _customEmotions.any((e) => 
      e['emotion'] == emotion || e['emoji'] == emoji
    );
    
    if (exists) {
      return false;
    }
    
    // 메모리에 추가
    final newEmotion = {
      'emotion': emotion,
      'emoji': emoji,
      'color': color,
      'isCustom': true,
    };
    
    _customEmotions.add(newEmotion);
    
    // Firebase에 저장 시도
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        // 색상을 저장할 수 있는 형태로 변환
        final firebaseEmotion = {
          'emotion': emotion,
          'emoji': emoji,
          'colorValue': color.value,
          'isCustom': true,
          'userId': user.uid,
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        await FirebaseService.setDocument(
          'custom_emotions', 
          '${user.uid}_${emotion.replaceAll(' ', '_')}',
          firebaseEmotion
        );
      } catch (e) {
        print('사용자 정의 감정 저장 오류: $e');
        // Firebase 저장 실패해도 UI에는 표시
      }
    }
    
    notifyListeners();
    return true;
  }
  
  /// 사용자 정의 감정 삭제
  Future<bool> removeCustomEmotion(Map<String, dynamic> emotion) async {
    final emotionName = emotion['emotion'] as String;
    _customEmotions.removeWhere((e) => e['emotion'] == emotionName);
    
    // Firebase에서도 삭제
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        await FirebaseService.deleteDocument(
          'custom_emotions',
          '${user.uid}_${emotionName.replaceAll(' ', '_')}'
        );
      } catch (e) {
        print('사용자 정의 감정 삭제 오류: $e');
        // Firebase 삭제 실패해도 UI에서는 제거
      }
    }
    
    notifyListeners();
    return true;
  }
  
  /// 특정 기간 감정 통계 계산
  Map<String, int> calculateEmotionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // 필터링
    List<EmotionRecord> filtered = _emotionRecords;
    
    if (startDate != null) {
      filtered = filtered.where((record) => 
        record.timestamp.isAfter(startDate) || 
        record.timestamp.isAtSameMomentAs(startDate)
      ).toList();
    }
    
    if (endDate != null) {
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      filtered = filtered.where((record) => 
        record.timestamp.isBefore(endOfDay)
      ).toList();
    }
    
    // 통계 계산
    final stats = <String, int>{};
    
    for (final record in filtered) {
      if (stats.containsKey(record.emotion)) {
        stats[record.emotion] = stats[record.emotion]! + 1;
      } else {
        stats[record.emotion] = 1;
      }
    }
    
    return stats;
  }
  
  /// 감정 점수 설정
  Future<bool> setEmotionScore(String emotion, double score) async {
    // 점수 유효성 검사 (0.0 ~ 1.0 사이 값만 허용)
    if (score < 0.0 || score > 1.0) {
      return false;
    }
    
    // 로컬 업데이트
    _customEmotionScores[emotion] = score;
    
    // Firebase에 저장
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        await FirebaseService.setDocument(
          'emotion_scores',
          user.uid,
          {'scores': _customEmotionScores}
        );
        
        notifyListeners();
        return true;
      } catch (e) {
        print('감정 점수 저장 오류: $e');
        return false;
      }
    }
    
    notifyListeners();
    return true;
  }
  
  /// 감정 점수 일괄 설정
  Future<bool> setEmotionScores(Map<String, double> scores) async {
    // 점수 유효성 검사
    for (final score in scores.values) {
      if (score < 0.0 || score > 1.0) {
        return false;
      }
    }
    
    // 로컬 업데이트
    _customEmotionScores = Map.from(scores);
    
    // Firebase에 저장
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        await FirebaseService.setDocument(
          'emotion_scores',
          user.uid,
          {'scores': _customEmotionScores}
        );
        
        notifyListeners();
        return true;
      } catch (e) {
        print('감정 점수 일괄 저장 오류: $e');
        return false;
      }
    }
    
    notifyListeners();
    return true;
  }
  
  /// 기본 감정 점수로 초기화
  Future<bool> resetEmotionScores() async {
    _customEmotionScores = {};
    
    // Firebase에서 삭제
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        await FirebaseService.setDocument(
          'emotion_scores',
          user.uid,
          {'scores': {}}
        );
        
        notifyListeners();
        return true;
      } catch (e) {
        print('감정 점수 초기화 오류: $e');
        return false;
      }
    }
    
    notifyListeners();
    return true;
  }
  
  /// 특정 감정의 점수 조회
  double getEmotionScore(String emotion) {
    // 사용자 정의 점수가 있으면 사용
    if (_customEmotionScores.containsKey(emotion)) {
      return _customEmotionScores[emotion]!;
    }
    
    // 기본 점수가 있으면 사용
    if (_defaultEmotionScores.containsKey(emotion)) {
      return _defaultEmotionScores[emotion]!;
    }
    
    // 없으면 중립 점수 반환
    return 0.5;
  }
} 