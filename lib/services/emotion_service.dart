import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_record.dart';
import 'firebase_service.dart';

/// 감정 기록 관리 서비스
class EmotionService extends ChangeNotifier {
  // 로컬 캐시
  final List<EmotionRecord> _allRecords = [];
  final Map<String, List<EmotionRecord>> _recordsByDate = {};
  final Map<String, List<EmotionRecord>> _recordsByMonth = {};
  
  // 마지막으로 조회한 기간
  DateTime? _lastFetchedMonth;
  
  // 초기화 완료 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // 로컬 저장소 키
  static const String _storageKey = 'emotion_records';
  static const String _customEmotionsKey = 'custom_emotions';
  static const String _customTagsKey = 'custom_tags';
  
  // 기본 감정 목록
  final List<Map<String, String>> _defaultEmotions = [
    {'emotion': '행복', 'emoji': '😊'},
    {'emotion': '슬픔', 'emoji': '😢'},
    {'emotion': '분노', 'emoji': '😠'},
    {'emotion': '불안', 'emoji': '😰'},
    {'emotion': '놀람', 'emoji': '😲'},
    {'emotion': '혐오', 'emoji': '🤢'},
    {'emotion': '지루함', 'emoji': '😴'},
  ];
  
  // 사용자 정의 감정 목록
  List<Map<String, String>> _customEmotions = [];
  
  // 기본 태그 목록
  final List<String> _defaultTags = [
    '업무', '가족', '건강', '친구', '취미', '학업', '연애'
  ];
  
  // 사용자 정의 태그 목록
  List<String> _customTags = [];
  
  // 모든 감정 목록 (기본 + 사용자 정의)
  List<Map<String, String>> get allEmotions => [..._defaultEmotions, ..._customEmotions];
  
  // 기본 감정 목록 가져오기
  List<Map<String, String>> get defaultEmotions => _defaultEmotions;
  
  // 사용자 정의 감정 목록 가져오기
  List<Map<String, String>> get customEmotions => _customEmotions;
  
  // 모든 태그 목록 (기본 + 사용자 정의)
  List<String> get allTags => [..._defaultTags, ..._customTags];
  
  // 기본 태그 목록 가져오기
  List<String> get defaultTags => _defaultTags;
  
  // 사용자 정의 태그 목록 가져오기
  List<String> get customTags => _customTags;
  
  // 생성자에서 사용자 정의 감정 및 태그 로드
  EmotionService() {
    _loadCustomEmotions();
    _loadCustomTags();
  }
  
  // 사용자 정의 감정 로드
  Future<void> _loadCustomEmotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_customEmotionsKey);
      
      if (jsonList != null && jsonList.isNotEmpty) {
        _customEmotions = jsonList
            .map((json) => Map<String, String>.from(jsonDecode(json)))
            .toList();
      }
    } catch (e) {
      print('사용자 정의 감정 로드 오류: $e');
    }
  }
  
  // 사용자 정의 감정 저장
  Future<void> _saveCustomEmotions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _customEmotions
          .map((emotion) => jsonEncode(emotion))
          .toList();
      
      await prefs.setStringList(_customEmotionsKey, jsonList);
    } catch (e) {
      print('사용자 정의 감정 저장 오류: $e');
    }
  }
  
  // 사용자 정의 감정 추가
  Future<bool> addCustomEmotion(String emotion, String emoji) async {
    try {
      // 이미 존재하는 감정인지 확인
      final exists = [..._defaultEmotions, ..._customEmotions]
          .any((item) => item['emotion'] == emotion || item['emoji'] == emoji);
      
      if (exists) {
        return false;
      }
      
      // 새 감정 추가
      _customEmotions.add({'emotion': emotion, 'emoji': emoji});
      
      // 저장하고 알림
      await _saveCustomEmotions();
      notifyListeners();
      return true;
    } catch (e) {
      print('사용자 정의 감정 추가 오류: $e');
      return false;
    }
  }
  
  // 사용자 정의 감정 삭제
  Future<bool> removeCustomEmotion(String emotion) async {
    try {
      final initialLength = _customEmotions.length;
      _customEmotions.removeWhere((item) => item['emotion'] == emotion);
      
      if (_customEmotions.length < initialLength) {
        await _saveCustomEmotions();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('사용자 정의 감정 삭제 오류: $e');
      return false;
    }
  }
  
  // 사용자 정의 감정 수정
  Future<bool> updateCustomEmotion(String oldEmotion, String newEmotion, String newEmoji) async {
    try {
      // 원래 감정 찾기
      final index = _customEmotions.indexWhere((item) => item['emotion'] == oldEmotion);
      
      if (index == -1) {
        return false;
      }
      
      // 다른 감정과 중복되는지 확인
      final exists = [..._defaultEmotions, ..._customEmotions]
          .where((item) => item['emotion'] != oldEmotion) // 자기 자신 제외
          .any((item) => item['emotion'] == newEmotion || item['emoji'] == newEmoji);
      
      if (exists) {
        return false;
      }
      
      // 감정 수정
      _customEmotions[index] = {'emotion': newEmotion, 'emoji': newEmoji};
      
      // 저장하고 알림
      await _saveCustomEmotions();
      notifyListeners();
      return true;
    } catch (e) {
      print('사용자 정의 감정 수정 오류: $e');
      return false;
    }
  }
  
  // 감정 기록 저장
  Future<bool> saveEmotionRecord(EmotionRecord record) async {
    try {
      // Firebase에 저장
      final result = await FirebaseService.saveEmotionRecord(record.toJson());
      return result['success'] == true;
    } catch (e) {
      print('감정 기록 저장 오류: $e');
      return false;
    }
  }
  
  // 감정 기록 가져오기
  Future<List<EmotionRecord>> getEmotionRecords() async {
    try {
      if (FirebaseService.currentUser != null) {
        // Firebase에서 가져오기
        final results = await FirebaseService.getEmotionRecords();
        return results.map((record) => EmotionRecord.fromJson(record)).toList();
      } else {
        // 로컬에서 가져오기
        final prefs = await SharedPreferences.getInstance();
        
        // 저장된 기록 가져오기
        List<String>? jsonRecords = prefs.getStringList(_storageKey);
        
        if (jsonRecords == null || jsonRecords.isEmpty) {
          return [];
        }
        
        // JSON에서 객체로 변환
        return jsonRecords.map((jsonRecord) => 
          EmotionRecord.fromJson(jsonDecode(jsonRecord))).toList();
      }
    } catch (e) {
      print('감정 기록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 날짜별 맵 업데이트
  void _updateRecordMaps() {
    _recordsByDate.clear();
    _recordsByMonth.clear();
    
    for (final record in _allRecords) {
      // 날짜별 그룹화
      final dateStr = _formatDateKey(record.timestamp);
      if (!_recordsByDate.containsKey(dateStr)) {
        _recordsByDate[dateStr] = [];
      }
      _recordsByDate[dateStr]!.add(record);
      
      // 월별 그룹화
      final monthStr = _formatMonthKey(record.timestamp);
      if (!_recordsByMonth.containsKey(monthStr)) {
        _recordsByMonth[monthStr] = [];
      }
      _recordsByMonth[monthStr]!.add(record);
    }
  }
  
  // 날짜별 감정 기록 가져오기
  Future<List<EmotionRecord>> getEmotionRecordsByDate(DateTime date) async {
    try {
      if (FirebaseService.currentUser != null) {
        // 모든 기록 가져오기
        final allRecords = await getEmotionRecords();
        
        // 날짜 필터링
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(Duration(days: 1)).subtract(Duration(microseconds: 1));
        
        return allRecords.where((record) {
          final recordTime = record.timestamp;
          return recordTime.isAfter(dayStart.subtract(Duration(seconds: 1))) && 
                 recordTime.isBefore(dayEnd.add(Duration(seconds: 1)));
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('날짜별 감정 기록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 특정 태그별 감정 기록 가져오기
  Future<List<EmotionRecord>> getEmotionRecordsByTag(String tag) async {
    try {
      // 모든 기록 가져오기
      final allRecords = await getEmotionRecords();
      
      // 선택된 태그의 기록만 필터링
      return allRecords.where((record) => record.tags.contains(tag)).toList();
    } catch (e) {
      print('태그별 감정 기록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 모든 사용된 태그 목록 가져오기
  Future<List<String>> getAllTags() async {
    await _loadCustomTags(); // 최신 태그 목록 로드
    return allTags;
  }
  
  // 월별 감정 기록 가져오기
  Future<List<EmotionRecord>> getEmotionRecordsByMonth(DateTime month) async {
    try {
      // 모든 기록 가져오기
      final allRecords = await getEmotionRecords();
      
      // 선택된 월의 기록만 필터링
      return allRecords.where((record) {
        return record.timestamp.year == month.year && 
              record.timestamp.month == month.month;
      }).toList();
    } catch (e) {
      print('월별 감정 기록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 감정별 통계 가져오기
  Future<Map<String, int>> getEmotionCounts() async {
    try {
      // 모든 기록 가져오기
      final records = await getEmotionRecords();
      final counts = <String, int>{};
      
      // 감정별 빈도수 계산
      for (final record in records) {
        final emotion = record.emotion;
        counts[emotion] = (counts[emotion] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      print('감정 통계 가져오기 오류: $e');
      return {};
    }
  }
  
  // 태그별 통계 가져오기
  Future<Map<String, int>> getTagCounts() async {
    try {
      // 모든 기록 가져오기
      final records = await getEmotionRecords();
      final counts = <String, int>{};
      
      // 태그별 빈도수 계산
      for (final record in records) {
        for (final tag in record.tags) {
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
      }
      
      return counts;
    } catch (e) {
      print('태그 통계 가져오기 오류: $e');
      return {};
    }
  }
  
  // 시간대별 감정 통계 가져오기
  Future<Map<String, Map<String, int>>> getEmotionStatsByTimeOfDay() async {
    try {
      // 모든 기록 가져오기
      final records = await getEmotionRecords();
      
      // 시간대 정의
      final timeSlots = {
        '아침 (06:00-12:00)': (hour) => hour >= 6 && hour < 12,
        '오후 (12:00-18:00)': (hour) => hour >= 12 && hour < 18,
        '저녁 (18:00-00:00)': (hour) => hour >= 18 && hour < 24,
        '새벽 (00:00-06:00)': (hour) => hour >= 0 && hour < 6,
      };
      
      // 시간대별 감정 맵 초기화
      final result = <String, Map<String, int>>{};
      timeSlots.keys.forEach((slot) {
        result[slot] = {};
      });
      
      // 감정 기록을 시간대별로 분류
      for (final record in records) {
        final hour = record.timestamp.hour;
        
        // 어느 시간대에 속하는지 확인
        timeSlots.forEach((slotName, condition) {
          if (condition(hour)) {
            final emotion = record.emotion;
            result[slotName]![emotion] = (result[slotName]![emotion] ?? 0) + 1;
          }
        });
      }
      
      return result;
    } catch (e) {
      print('시간대별 감정 통계 가져오기 오류: $e');
      return {};
    }
  }
  
  // 날짜 키 포맷
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 월 키 포맷
  String _formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
  
  // 사용자 정의 태그 로드
  Future<void> _loadCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagsList = prefs.getStringList(_customTagsKey);
      
      if (tagsList != null && tagsList.isNotEmpty) {
        _customTags = tagsList;
      }
      
      notifyListeners();
    } catch (e) {
      print('사용자 정의 태그 로드 오류: $e');
    }
  }
  
  // 사용자 정의 태그 저장
  Future<bool> saveCustomTags(List<String> tags) async {
    try {
      // 기본 태그 제외하고 사용자 정의 태그만 저장
      _customTags = tags.where((tag) => !_defaultTags.contains(tag)).toList();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customTagsKey, _customTags);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('사용자 정의 태그 저장 오류: $e');
      return false;
    }
  }
  
  // 사용자 정의 태그 추가
  Future<bool> addCustomTag(String tag) async {
    try {
      // 이미 존재하는 태그인지 확인
      if (_defaultTags.contains(tag) || _customTags.contains(tag)) {
        return false;
      }
      
      _customTags.add(tag);
      
      // 저장하고 알림
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customTagsKey, _customTags);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('사용자 정의 태그 추가 오류: $e');
      return false;
    }
  }
  
  // 사용자 정의 태그 삭제
  Future<bool> removeCustomTag(String tag) async {
    try {
      // 기본 태그는 삭제 불가
      if (_defaultTags.contains(tag)) {
        return false;
      }
      
      final success = _customTags.remove(tag);
      
      if (success) {
        // 저장하고 알림
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_customTagsKey, _customTags);
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('사용자 정의 태그 삭제 오류: $e');
      return false;
    }
  }
} 