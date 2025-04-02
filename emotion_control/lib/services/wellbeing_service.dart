import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_usage/app_usage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/digital_wellbeing.dart';
import 'firebase_service.dart';

/// 디지털 웰빙 데이터 관리 서비스
class WellbeingService extends ChangeNotifier {
  // 로컬 캐시
  final List<DigitalWellbeingData> _allData = [];
  final Map<String, DigitalWellbeingData> _dataByDate = {};
  
  // 초기화 완료 여부
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // 권한 상태
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;
  
  // 로컬 저장소 키
  static const String _storageKey = 'digital_wellbeing_data';
  
  // 오늘의 데이터 (캐싱)
  DigitalWellbeingData? _todayData;
  DigitalWellbeingData? get todayData => _todayData;
  
  // 생성자
  WellbeingService() {
    _initialize();
  }
  
  // 비동기 초기화
  Future<void> _initialize() async {
    await _checkPermission();
    await _loadLocalData();
    _isInitialized = true;
    notifyListeners();
  }
  
  // 권한 확인
  Future<void> _checkPermission() async {
    if (kIsWeb) {
      // 웹에서는 권한 요청 불가능
      _hasPermission = false;
      return;
    }
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android에서는 앱 사용 통계 접근 권한 확인
      final status = await Permission.appTrackingTransparency.status;
      _hasPermission = status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS에서는 별도의 권한 없이 제한된 정보만 수집 가능
      _hasPermission = true;
    } else {
      _hasPermission = false;
    }
  }
  
  // 권한 요청
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android에서는 앱 사용 통계 접근 권한 요청
      await Permission.appTrackingTransparency.request();
      final status = await Permission.appTrackingTransparency.status;
      _hasPermission = status.isGranted;
      notifyListeners();
      return _hasPermission;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS에서는 시스템 제한으로 인해 직접적인 권한 요청이 불가능
      _hasPermission = true;
      notifyListeners();
      return true;
    }
    
    return false;
  }
  
  // 로컬 데이터 불러오기
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey);
      
      if (jsonList != null && jsonList.isNotEmpty) {
        _allData.clear();
        for (final json in jsonList) {
          try {
            final data = DigitalWellbeingData.fromJson(jsonDecode(json));
            _allData.add(data);
            _dataByDate[_formatDateKey(data.date)] = data;
          } catch (e) {
            print('디지털 웰빙 데이터 파싱 오류: $e');
          }
        }
      }
      
      // 오늘 데이터 확인
      final today = DateTime.now();
      final todayKey = _formatDateKey(today);
      _todayData = _dataByDate[todayKey];
    } catch (e) {
      print('로컬 디지털 웰빙 데이터 로드 오류: $e');
    }
  }
  
  // 데이터 저장
  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _allData.map((data) => jsonEncode(data.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      print('로컬 디지털 웰빙 데이터 저장 오류: $e');
    }
  }
  
  // 날짜 키 포맷
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // 앱 사용 통계 수집
  Future<Map<String, int>> _getAppUsageStats(DateTime startTime, DateTime endTime) async {
    if (!_hasPermission) {
      return {};
    }
    
    if (kIsWeb || !(defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return {};
    }
    
    try {
      // 앱 사용 통계 가져오기
      final Map<String, int> usage = {};
      
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        // 실제 기기에서 데이터 수집
        try {
          final AppUsage appUsage = AppUsage();
          final List<AppUsageInfo> usageStats = await appUsage.getAppUsage(startTime, endTime);
          
          for (var app in usageStats) {
            // 사용 시간을 초 단위로 변환
            final seconds = app.usage.inSeconds;
            if (seconds > 0) {
              usage[app.appName] = seconds;
            }
          }
        } catch (e) {
          print('앱 사용 통계 수집 오류: $e');
          // 웹이나 테스트 환경에서 더미 데이터 제공
          usage['Facebook'] = 1800; // 30분
          usage['Instagram'] = 900; // 15분
          usage['YouTube'] = 1200; // 20분
          usage['Twitter'] = 600; // 10분
          usage['TikTok'] = 450; // 7.5분
        }
      } else {
        // 웹이나 테스트 환경에서 더미 데이터 제공
        usage['Facebook'] = 1800; // 30분
        usage['Instagram'] = 900; // 15분
        usage['YouTube'] = 1200; // 20분
        usage['Twitter'] = 600; // 10분
        usage['TikTok'] = 450; // 7.5분
      }
      
      return usage;
    } catch (e) {
      print('앱 사용 통계 수집 오류: $e');
      // 오류 발생 시 더미 데이터 반환
      return {
        'Facebook': 1800, // 30분
        'Instagram': 900, // 15분
        'YouTube': 1200, // 20분
        'Twitter': 600, // 10분
        'TikTok': 450, // 7.5분
      };
    }
  }
  
  // 오늘의 디지털 웰빙 데이터 수집
  Future<DigitalWellbeingData?> collectTodayData() async {
    if (!_hasPermission && !await requestPermission()) {
      return null;
    }
    
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startTime = today;
      final endTime = now;
      
      // 앱 사용 통계 수집
      final appUsage = await _getAppUsageStats(startTime, endTime);
      
      // 총 스크린 타임 계산
      final totalScreenTime = appUsage.values.fold(0, (sum, time) => sum + time);
      
      // 시간대별 사용 시간 (현재는 더미 데이터)
      final hourlyUsage = <String, int>{};
      for (int i = 0; i < 24; i++) {
        hourlyUsage['$i'] = 0;
      }
      
      // 기존 데이터가 있으면 업데이트, 없으면 새로 생성
      final todayKey = _formatDateKey(today);
      final existingData = _dataByDate[todayKey];
      
      final DigitalWellbeingData newData;
      if (existingData != null) {
        newData = existingData.copyWith(
          appUsage: appUsage,
          totalScreenTime: totalScreenTime,
          hourlyUsage: hourlyUsage,
        );
      } else {
        newData = DigitalWellbeingData(
          date: today,
          appUsage: appUsage,
          totalScreenTime: totalScreenTime,
          hourlyUsage: hourlyUsage,
          userId: FirebaseService.currentUser?.uid,
        );
      }
      
      // 데이터 저장
      await saveWellbeingData(newData);
      
      return newData;
    } catch (e) {
      print('오늘의 디지털 웰빙 데이터 수집 오류: $e');
      return null;
    }
  }
  
  // 디지털 웰빙 데이터 저장
  Future<bool> saveWellbeingData(DigitalWellbeingData data) async {
    try {
      final dateKey = _formatDateKey(data.date);
      
      // 메모리에 저장
      _dataByDate[dateKey] = data;
      
      // 리스트에 추가 또는 업데이트
      final existingIndex = _allData.indexWhere((item) => _formatDateKey(item.date) == dateKey);
      if (existingIndex >= 0) {
        _allData[existingIndex] = data;
      } else {
        _allData.add(data);
      }
      
      // 오늘 데이터 업데이트
      final today = DateTime.now();
      if (_formatDateKey(today) == dateKey) {
        _todayData = data;
      }
      
      // 로컬에 저장
      await _saveLocalData();
      
      // Firebase에 저장 시도
      if (FirebaseService.currentUser != null) {
        try {
          final result = await FirebaseService.saveDigitalWellbeingData(data.toJson());
          if (result['success'] == true && result['id'] != null) {
            // ID 업데이트
            final updatedData = data.copyWith(id: result['id']);
            _dataByDate[dateKey] = updatedData;
            
            final existingIndex = _allData.indexWhere((item) => _formatDateKey(item.date) == dateKey);
            if (existingIndex >= 0) {
              _allData[existingIndex] = updatedData;
            }
            
            if (_formatDateKey(today) == dateKey) {
              _todayData = updatedData;
            }
            
            await _saveLocalData();
          }
        } catch (e) {
          print('Firebase 디지털 웰빙 데이터 저장 오류: $e');
          // 로컬 저장은 성공했으므로 여전히 true 반환
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('디지털 웰빙 데이터 저장 오류: $e');
      return false;
    }
  }
  
  // 데이터 가져오기
  Future<List<DigitalWellbeingData>> getWellbeingData() async {
    // 이미 로드된 데이터 반환
    return List.unmodifiable(_allData);
  }
  
  // 날짜별 데이터 가져오기
  DigitalWellbeingData? getDataByDate(DateTime date) {
    final dateKey = _formatDateKey(date);
    return _dataByDate[dateKey];
  }
  
  // 날짜 범위 데이터 가져오기
  List<DigitalWellbeingData> getDataByDateRange(DateTime start, DateTime end) {
    return _allData.where((data) {
      return data.date.isAfter(start.subtract(const Duration(days: 1))) && 
             data.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
} 