import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_stats.dart';
import '../models/emotion_record.dart';
import '../models/quest.dart';

/// 게임 시스템 관련 서비스 (경험치, 레벨, 업적 등)
class GameService extends ChangeNotifier {
  UserStats? _userStats;
  bool _isLoading = false;
  
  // 게터
  UserStats? get userStats => _userStats;
  bool get isLoading => _isLoading;
  
  // 로컬 저장소 키
  static const String _statsKey = 'user_stats';
  
  // 생성자
  GameService() {
    _loadStats();
  }
  
  // 사용자 통계 로드
  Future<void> _loadStats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);
      
      if (statsJson != null) {
        _userStats = UserStats.fromJson(jsonDecode(statsJson));
      } else {
        // 기본 통계 생성
        _userStats = UserStats();
        await _saveStats();
      }
    } catch (e) {
      print('통계 로드 오류: $e');
      _userStats = UserStats();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 사용자 통계 저장
  Future<void> _saveStats() async {
    if (_userStats == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_userStats!.toJson()));
    } catch (e) {
      print('통계 저장 오류: $e');
    }
  }
  
  // 통계 업데이트
  Future<void> updateStats(UserStats newStats) async {
    _userStats = newStats;
    await _saveStats();
    notifyListeners();
  }
  
  // 경험치 추가
  Future<void> addExperience(int exp) async {
    if (_userStats == null) return;
    
    final newStats = _userStats!.addExperience(exp);
    await updateStats(newStats);
  }
  
  // 감정 기록에 따른 보상 처리
  Future<int> processRewardForRecord(EmotionRecord record) async {
    if (_userStats == null) await _loadStats();
    if (_userStats == null) return 0;
    
    int expEarned = 0;
    
    // 기본 경험치 (기록당)
    expEarned += 20;
    
    // 이미지/비디오 첨부 보너스
    if (record.imageUrl != null) expEarned += 15;
    if (record.videoUrl != null) expEarned += 15;
    
    // 태그 보너스 (태그당)
    expEarned += record.tags.length * 5;
    
    // 상세 내용 보너스
    if (record.details != null && record.details!.isNotEmpty) expEarned += 10;
    
    // 음성 메모 보너스
    if (record.audioUrl != null) expEarned += 15;
    
    // 일기 작성 보너스
    if (record.diaryContent != null && record.diaryContent!.isNotEmpty) expEarned += 20;
    
    // 경험치 추가 및 기록 카운트 증가
    final newStats = _userStats!
        .addExperience(expEarned)
        .incrementRecordCount();
    
    await updateStats(newStats);
    return expEarned;
  }
  
  // 퀘스트 완료에 따른 보상 처리
  Future<int> processRewardForQuest(Quest quest) async {
    if (_userStats == null) await _loadStats();
    if (_userStats == null) return 0;
    
    // 퀘스트에서 정의된 경험치 보상
    final expEarned = quest.expReward;
    
    // 경험치 추가 및 퀘스트 완료 카운트 증가
    final newStats = _userStats!
        .addExperience(expEarned)
        .incrementQuestCount();
    
    await updateStats(newStats);
    return expEarned;
  }
} 