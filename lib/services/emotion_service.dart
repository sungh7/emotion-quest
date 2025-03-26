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
  
  // 월별 감정 맵 가져오기
  Future<Map<DateTime, String?>> getMonthlyEmotionMap(DateTime month) async {
    try {
      // 모든 기록 가져오기
      final allRecords = await getEmotionRecords();
      final result = <DateTime, String?>{};
      
      // 같은 날짜의 기록을 그룹화
      final recordsByDate = <String, List<EmotionRecord>>{};
      
      for (final record in allRecords) {
        final date = DateTime(
          record.timestamp.year,
          record.timestamp.month,
          record.timestamp.day,
        );
        
        // 선택된 월에 속하는 기록만 필터링
        if (date.year == month.year && date.month == month.month) {
          final dateStr = date.toIso8601String().split('T')[0];
          
          if (!recordsByDate.containsKey(dateStr)) {
            recordsByDate[dateStr] = [];
          }
          
          recordsByDate[dateStr]!.add(record);
        }
      }
      
      // 날짜별로 가장 많이 기록된 감정을 대표 감정으로 선택
      recordsByDate.forEach((dateStr, records) {
        // 감정별 빈도수 계산
        final emotionCounts = <String, int>{};
        
        for (final record in records) {
          final emotion = record.emotion;
          emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
        }
        
        // 가장 많이 기록된 감정 찾기
        String? mostCommonEmotion;
        int maxCount = 0;
        
        emotionCounts.forEach((emotion, count) {
          if (count > maxCount) {
            mostCommonEmotion = emotion;
            maxCount = count;
          }
        });
        
        final date = DateTime.parse(dateStr);
        result[date] = mostCommonEmotion;
      });
      
      return result;
    } catch (e) {
      print('월별 감정 맵 가져오기 오류: $e');
      return {};
    }
  }
  
  // 날짜 키 형식 (YYYY-MM-DD)
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 월 키 형식 (YYYY-MM)
  String _formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
} 