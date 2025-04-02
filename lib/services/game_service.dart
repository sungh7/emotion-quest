import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_stats.dart';
import '../models/emotion_record.dart';
import '../models/quest.dart';
import '../repositories/user_repository.dart';
import '../services/firebase_service.dart';

/// 게임 시스템 관련 서비스 (경험치, 레벨, 업적 등)
class GameService extends ChangeNotifier {
  UserStats? _userStats;
  bool _isLoading = false;
  int _points = 0;
  int _level = 1;
  List<String> _achievements = [];
  
  // UserRepository 인스턴스
  final UserRepository _userRepository = UserRepository();
  
  // 게터
  UserStats? get userStats => _userStats;
  bool get isLoading => _isLoading;
  int get points => _points;
  int get level => _level;
  List<String> get achievements => _achievements;
  
  // 포인트 가져오기
  int getPoints() {
    return _points;
  }
  
  // 로컬 저장소 키
  static const String _statsKey = 'user_stats';
  
  // 생성자
  GameService({UserStats? initialStats})  {
    _userStats = initialStats;
    // 초기화 시 기존 데이터 로드
    loadGameData();
    _loadStats();
  }
  
  // 사용자 통계 로드
  Future<void> _loadStats() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Firebase 사용자 확인
      final userId = FirebaseService.currentUser?.uid;
      
      if (userId != null) {
        // Firestore에서 통계 로드 시도
        final firestoreStats = await _userRepository.getUserStats(userId);
        
        if (firestoreStats != null) {
          _userStats = firestoreStats;
          print('Firestore에서 사용자 통계 로드 성공: Level ${_userStats!.level}, Exp ${_userStats!.experience}');
        } else {
          // Firestore에 데이터가 없는 경우, 로컬 스토리지 확인
          final prefs = await SharedPreferences.getInstance();
          final statsJson = prefs.getString(_statsKey);
          
          if (statsJson != null) {
            _userStats = UserStats.fromJson(jsonDecode(statsJson));
            // 로컬에 있던 데이터를 Firestore에 동기화
            await _saveStatsToFirestore(userId, _userStats!);
          } else {
            // 기본 통계 생성
            _userStats = UserStats();
            await _saveStats();
          }
        }
      } else {
        // 로그인되지 않은 경우 로컬 스토리지만 확인
        final prefs = await SharedPreferences.getInstance();
        final statsJson = prefs.getString(_statsKey);
        
        if (statsJson != null) {
          _userStats = UserStats.fromJson(jsonDecode(statsJson));
        } else {
          // 기본 통계 생성
          _userStats = UserStats();
          await _saveStats();
        }
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
      // 로컬 스토리지에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_userStats!.toJson()));
      
      // Firebase 사용자가 있으면 Firestore에도 저장
      final userId = FirebaseService.currentUser?.uid;
      if (userId != null) {
        await _saveStatsToFirestore(userId, _userStats!);
      }
    } catch (e) {
      print('통계 저장 오류: $e');
    }
  }
  
  // Firestore에 통계 저장
  Future<void> _saveStatsToFirestore(String userId, UserStats stats) async {
    try {
      await _userRepository.saveUserStats(userId, stats);
      print('Firestore에 사용자 통계 저장 성공: Level ${stats.level}, Exp ${stats.experience}');
    } catch (e) {
      print('Firestore 통계 저장 오류: $e');
    }
  }
  
  // 통계 업데이트
  Future<void> updateStats(UserStats newStats) async {
    _userStats = newStats;
    await _saveStats();
    notifyListeners();
  }
  
  // 경험치 추가
  Future<bool> addExperience(int exp) async {
    if (_userStats == null) return false;
    
    // 현재 레벨 저장
    final int oldLevel = _userStats!.level;
    
    // 경험치 추가
    _userStats!.experience += exp;
    
    // 레벨업 체크
    _userStats!.checkLevelUp();
    
    // 데이터 저장
    await _saveStats();
    
    // 레벨업 발생 여부 반환
    return _userStats!.level > oldLevel;
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
    
    // 유저 스탯 업데이트
    await updateStats(newStats);
    
    // 게임 포인트도 동일하게 추가 (로컬 스토리지에 저장됨)
    await addPoints(expEarned);
    
    return expEarned;
  }

  // 게임 데이터 로드
  Future<void> loadGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _points = prefs.getInt('game_points') ?? 0;
      _level = prefs.getInt('game_level') ?? 1;
      _achievements = prefs.getStringList('game_achievements') ?? [];
      notifyListeners();
    } catch (e) {
      print('게임 데이터 로드 오류: $e');
    }
  }

  // 게임 데이터 저장
  Future<void> _saveGameData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('game_points', _points);
      await prefs.setInt('game_level', _level);
      await prefs.setStringList('game_achievements', _achievements);
    } catch (e) {
      print('게임 데이터 저장 오류: $e');
    }
  }

  // 포인트 추가
  Future<void> addPoints(int points) async {
    if (_userStats == null) await _loadStats();
    if (_userStats == null) return;
    
    // 포인트 추가
    _userStats!.points += points;
    
    // 게임 데이터 저장 (퀘스트 상태는 변경하지 않음)
    await _saveStats();
    
    // UI 업데이트
    notifyListeners();
  }

  // 포인트 차감
  Future<bool> usePoints(int amount) async {
    if (_points < amount) {
      return false;
    }
    
    _points -= amount;
    await _saveGameData();
    notifyListeners();
    return true;
  }

  // 레벨업 체크
  void _checkLevelUp() {
    // 레벨당 필요 포인트는 (현재 레벨 * 100) 으로 계산
    int pointsForNextLevel = _level * 100;
    
    if (_points >= pointsForNextLevel) {
      _level++;
      // 레벨업 업적 추가
      _addAchievement('레벨 ${_level}에 도달했습니다!');
      notifyListeners();
    }
  }

  // 업적 추가
  Future<void> _addAchievement(String achievement) async {
    if (!_achievements.contains(achievement)) {
      _achievements.add(achievement);
      await _saveGameData();
      notifyListeners();
    }
  }

  // 퀘스트 완료 보상
  Future<void> completeQuest(int rewardPoints) async {
    await addPoints(rewardPoints);
    notifyListeners();
  }

  // 게임 데이터 리셋 (테스트용)
  Future<void> resetGameData() async {
    _points = 0;
    _level = 1;
    _achievements = [];
    await _saveGameData();
    notifyListeners();
  }
  
  // 사용자 상태 초기화 (로그아웃 용)
  Future<void> resetUserStats() async {
    _userStats = null;
    _points = 0;
    _level = 1;
    _achievements = [];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statsKey);
      await prefs.remove('game_points');
      await prefs.remove('game_level');
      await prefs.remove('game_achievements');
    } catch (e) {
      print('상태 초기화 오류: $e');
    }
    
    notifyListeners();
  }
} 