import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion_record.dart';
import 'firebase_service.dart';
import 'package:intl/intl.dart';

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
  
  // 생성자에서 비동기 초기화 메서드 호출
  EmotionService() {
    _initialize();
  }
  
  // 비동기 초기화 메서드
  Future<void> _initialize() async {
    await _loadCustomEmotions();
    await _loadCustomTags();
    _isInitialized = true;
    print('EmotionService 초기화 완료: 태그 ${_customTags.length}개, 감정 ${_customEmotions.length}개 로드됨');
    notifyListeners();
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
  
  // 감정 기록 목록 가져오기 (기간 지정 가능)
  Future<List<EmotionRecord>> getEmotionRecords({DateTime? startDate, DateTime? endDate}) async {
    try {
      // Firebase에서 기간에 맞는 기록 조회 (백엔드 필터링)
      if (FirebaseService.currentUser != null) {
        final recordList = await FirebaseService.getEmotionRecords(startDate: startDate, endDate: endDate);
        
        // 로컬 캐시 업데이트 (주의: 이 방식은 기간별 조회가 빈번할 경우 비효율적일 수 있음)
        // _allRecords.clear(); 
        
        List<EmotionRecord> processedRecords = [];
        for (var record in recordList) {
          try {
            record = FirebaseService.processEmotionRecord(record);
            final emotionRecord = EmotionRecord.fromJson(record);
            processedRecords.add(emotionRecord);
          } catch (e) {
            print('레코드 처리 중 오류: $e');
            continue;
          }
        }
        // 선택적으로 로컬 캐시 업데이트 로직 추가 가능
        // _updateRecords(processedRecords); 
        return processedRecords;
      } else {
        // 로그인 안 된 경우 로컬 데이터 필터링
        await _getLocalEmotionRecords();
        return _filterLocalRecords(startDate, endDate);
      }
    } catch (e) {
      print('기간별 감정 기록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 로컬 기록 필터링 함수
  List<EmotionRecord> _filterLocalRecords(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) {
      return _allRecords; // 기간 없으면 전체 반환
    }
    return _allRecords.where((record) {
      final recordTime = record.timestamp;
      bool afterStartDate = startDate == null || recordTime.isAfter(startDate.subtract(const Duration(microseconds: 1)));
      bool beforeEndDate = endDate == null || recordTime.isBefore(endDate.add(const Duration(microseconds: 1)));
      return afterStartDate && beforeEndDate;
    }).toList();
  }
  
  // 로컬 저장소에서 감정 기록 조회 (캐시 업데이트 로직 분리)
  Future<void> _getLocalEmotionRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? jsonRecords = prefs.getStringList(_storageKey);
      
      _allRecords.clear();
      if (jsonRecords != null && jsonRecords.isNotEmpty) {
        for (String jsonRecord in jsonRecords) {
          try {
            final Map<String, dynamic> recordData = jsonDecode(jsonRecord);
            final processedRecord = FirebaseService.processEmotionRecord(recordData);
            final emotionRecord = EmotionRecord.fromJson(processedRecord);
            _allRecords.add(emotionRecord);
          } catch(e) {
             print('로컬 레코드 파싱 오류: $e');
             continue;
          }
        }
      }
      _updateRecordsByDate(); // 날짜별 그룹화는 유지
    } catch (e) {
      print('로컬 감정 기록 조회 오류: $e');
      _allRecords.clear(); // 오류 시 캐시 비우기
    }
  }
  
  // 기록을 날짜별로 그룹화
  void _updateRecordsByDate() {
    _recordsByDate.clear();
    _recordsByMonth.clear();
    
    for (final record in _allRecords) {
      // 날짜별 그룹화 (YYYY-MM-DD 형식)
      final dateStr = DateFormat('yyyy-MM-dd').format(record.timestamp);
      
      // 월별 그룹화 (YYYY-MM 형식)
      final monthStr = DateFormat('yyyy-MM').format(record.timestamp);
      
      if (!_recordsByDate.containsKey(dateStr)) {
        _recordsByDate[dateStr] = [];
      }
      
      if (!_recordsByMonth.containsKey(monthStr)) {
        _recordsByMonth[monthStr] = [];
      }
      
      _recordsByDate[dateStr]!.add(record);
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
        final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
        
        return allRecords.where((record) {
          final recordTime = record.timestamp;
          return recordTime.isAfter(dayStart.subtract(const Duration(seconds: 1))) && 
                 recordTime.isBefore(dayEnd.add(const Duration(seconds: 1)));
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
  
  // 모든 태그 가져오기 (로딩 중이면 대기)
  Future<List<String>> getAllTags() async {
    if (!_isInitialized) {
      await _loadCustomTags();
    }
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
      for (var slot in timeSlots.keys) {
        result[slot] = {};
      }
      
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
  
  // 사용자 정의 태그 로드
  Future<void> _loadCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagsList = prefs.getStringList(_customTagsKey);
      
      if (tagsList != null && tagsList.isNotEmpty) {
        _customTags = tagsList;
        print('로드된 사용자 정의 태그: $_customTags');
      } else {
        print('저장된 사용자 정의 태그가 없습니다');
      }
    } catch (e) {
      print('사용자 정의 태그 로드 오류: $e');
    }
  }
  
  // 사용자 정의 태그 저장
  Future<bool> saveCustomTags(List<String> tags) async {
    try {
      // 기본 태그 제외하고 사용자 정의 태그만 저장
      _customTags = tags.where((tag) => !_defaultTags.contains(tag)).toList();
      print('저장할 사용자 정의 태그: $_customTags');
      
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
  
  // 감정 기록 새로고침 (강제 다시 로드 - 전체 데이터 로드 유지)
  Future<void> refreshEmotionRecords() async {
    try {
      if (FirebaseService.currentUser != null) {
        // Firebase에서 전체 기록 조회 (기존 방식 유지)
        final recordList = await FirebaseService.getEmotionRecords();
        
        // 로컬 캐시 업데이트
        _allRecords.clear();
        
        for (var record in recordList) {
          try {
            record = FirebaseService.processEmotionRecord(record);
            final emotionRecord = EmotionRecord.fromJson(record);
            _allRecords.add(emotionRecord);
          } catch (e) {
            print('레코드 처리 중 오류: $e');
            continue;
          }
        }
        _updateRecordsByDate(); // 기존 날짜별 그룹화 유지
      } else {
        await _getLocalEmotionRecords();
      }
      notifyListeners();
    } catch (e) {
      print('감정 기록 새로고침 오류: $e');
    }
  }
  
  /// 익명 상태에서 저장한 기록을 로그인한 계정으로 연결
  Future<bool> linkAnonymousRecordsToUser() async {
    try {
      // 로그인 상태 확인
      if (FirebaseService.currentUser == null) {
        print('로그인되지 않아 기록 연결을 건너뜁니다.');
        return false;
      }
      
      // SharedPreferences 인스턴스 가져오기
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 기록 가져오기
      List<String>? jsonRecords = prefs.getStringList('emotion_records');
      if (jsonRecords == null || jsonRecords.isEmpty) {
        print('연결할 로컬 기록이 없습니다.');
        return false;
      }
      
      // 저장할 레코드 목록
      List<Map<String, dynamic>> recordsToSave = [];
      List<String> remainingRecords = [];
      bool hasAnonymousRecords = false;
      
      // 각 기록을 확인하고 익명 상태로 저장된 기록만 필터링
      for (String jsonRecord in jsonRecords) {
        Map<String, dynamic> record = jsonDecode(jsonRecord);
        
        // 익명 사용자 ID인지 확인
        if (record['userId'] != null && record['userId'].toString().startsWith('anonymous_')) {
          hasAnonymousRecords = true;
          // 현재 사용자 ID로 변경
          record['userId'] = FirebaseService.currentUser!.uid;
          recordsToSave.add(record);
        } else {
          // 익명 기록이 아닌 것은 유지
          remainingRecords.add(jsonRecord);
        }
      }
      
      // 익명 기록이 없으면 종료
      if (!hasAnonymousRecords) {
        print('연결할 익명 기록이 없습니다.');
        return false;
      }
      
      // 각 기록을 Firebase에 저장
      int successCount = 0;
      for (Map<String, dynamic> record in recordsToSave) {
        try {
          await FirebaseService.saveEmotionRecord(record);
          successCount++;
        } catch (e) {
          print('기록 연결 중 오류: $e');
          // 오류 발생 시 원래 기록 유지
          remainingRecords.add(jsonEncode(record));
        }
      }
      
      // 남은 기록 저장 (Firebase 저장에 실패한 것들)
      await prefs.setStringList('emotion_records', remainingRecords);
      
      // 결과 출력
      print('$successCount/${recordsToSave.length}개의 익명 기록이 사용자 계정에 연결되었습니다.');
      
      // 기록 새로고침
      await refreshEmotionRecords();
      return successCount > 0;
    } catch (e) {
      print('익명 기록 연결 오류: $e');
      return false;
    }
  }
  
  // 로컬 저장소에 감정 기록 저장하기
  Future<bool> _saveLocalEmotionRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 객체를 JSON 문자열로 변환
      final jsonRecords = _allRecords.map((record) => jsonEncode(record.toJson())).toList();
      
      // 로컬 저장소에 저장
      await prefs.setStringList(_storageKey, jsonRecords);
      
      // 날짜별 그룹화 저장
      _updateRecordsByDate();
      
      return true;
    } catch (e) {
      print('로컬 감정 기록 저장 오류: $e');
      return false;
    }
  }
} 