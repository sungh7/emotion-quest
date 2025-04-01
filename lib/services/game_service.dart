import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_stats.dart';
import '../models/emotion_record.dart';

class GameService extends ChangeNotifier {
  UserStats? _userStats;
  static const String _statsKey = 'user_stats';

  // 게터
  UserStats? get userStats => _userStats;

  GameService() {
    _loadUserStats();
  }

  // 유저 스탯 불러오기
  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsData = prefs.getString(_statsKey);
      
      if (statsData != null) {
        final statsMap = jsonDecode(statsData) as Map<String, dynamic>;
        _userStats = UserStats.fromJson(statsMap);
      } else {
        // 초기 스탯 생성
        _userStats = UserStats(
          level: 1,
          experience: 0,
          recordCount: 0,
          lastRecordDate: DateTime.now(),
        );
        await _saveUserStats();
      }
      
      notifyListeners();
    } catch (e) {
      print('유저 스탯 로드 오류: $e');
    }
  }

  // 유저 스탯 저장
  Future<void> _saveUserStats() async {
    try {
      if (_userStats != null) {
        final prefs = await SharedPreferences.getInstance();
        final statsData = jsonEncode(_userStats!.toJson());
        await prefs.setString(_statsKey, statsData);
      }
    } catch (e) {
      print('유저 스탯 저장 오류: $e');
    }
  }

  // 유저 스탯 업데이트
  Future<void> updateStats(UserStats newStats) async {
    _userStats = newStats;
    await _saveUserStats();
    notifyListeners();
  }

  // 감정 기록에 따른 보상 처리
  Future<void> processRecordRewards(EmotionRecord record) async {
    if (_userStats == null) return;
    
    // 기본 경험치 보상
    int expReward = 20;
    
    // 추가 보너스 (태그가 있는 경우, 이미지가 있는 경우 등)
    if (record.tags.isNotEmpty) {
      expReward += record.tags.length * 5;
    }
    
    if (record.imageUrl != null || record.videoUrl != null || record.audioUrl != null) {
      expReward += 15;
    }
    
    if (record.details != null && record.details!.isNotEmpty) {
      expReward += 10;
    }
    
    // 최대 100 경험치 제한
    expReward = expReward.clamp(0, 100);
    
    // 경험치 추가 및 저장
    _userStats = _userStats!.addExperience(expReward);
    _userStats = _userStats!.incrementRecordCount();
    
    await _saveUserStats();
    notifyListeners();
  }
} 