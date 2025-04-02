import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:async';
import '../models/quest.dart';
import '../models/quest_progress.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/game_service.dart';
import 'dart:math';
import 'package:provider/provider.dart';

class QuestService extends ChangeNotifier {
  List<Quest> _quests = [];
  Map<String, List<Quest>> _questsByEmotion = {};
  bool _isLoading = false;
  Map<String, QuestProgress> _questProgresses = {}; // 퀘스트 ID를 키로, 진행 상황을 값으로 하는 맵
  String? _activeQuestId; // 현재 활성화된 퀘스트 ID
  Timer? _questTimer;
  Set<String> _completedQuestIds = {};

  // 게터
  List<Quest> get quests => _quests;
  Map<String, List<Quest>> get questsByEmotion => _questsByEmotion;
  bool get isLoading => _isLoading;
  List<String> get availableEmotions => _questsByEmotion.keys.toList();
  // 현재 선택된 퀘스트의 진행 상황만 반환
  QuestProgress? get currentProgress => _activeQuestId != null ? _questProgresses[_activeQuestId] : null;
  
  // 특정 퀘스트의 진행 상황 반환
  QuestProgress? getQuestProgress(String questId) {
    return _questProgresses[questId];
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }

  // CSV 파일에서 퀘스트 데이터 로드
  Future<void> loadQuests() async {
    try {
      _isLoading = true;
      notifyListeners();

      // CSV 파일 로드 시도
      final String csvPath = 'assets/edited_quest.csv';
      String csvData;
      
      try {
        csvData = await rootBundle.loadString(csvPath);
        print('CSV 데이터 로드 성공: ${csvData.length} 바이트');
        
        if (csvData.isEmpty) {
          print('CSV 파일이 비어있습니다: $csvPath');
          _setupDefaultQuests();
          return;
        }
      } catch (e) {
        print('CSV 파일 로드 오류: $e');
        print('대체 데이터 사용을 시도합니다.');
        
        // 대체 파일 시도
        try {
          csvData = await rootBundle.loadString('assets/emotional_quest.csv');
          print('대체 CSV 파일 로드: ${csvData.length} 바이트');
        } catch (e2) {
          print('대체 CSV 파일도 로드 실패: $e2');
          _setupDefaultQuests();
          return;
        }
      }
      
      // 명시적으로 구분자 설정 (쉼표로 설정)
      List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvData);
      
      print('CSV 변환 결과: ${csvTable.length} 행');

      if (csvTable.isEmpty) {
        print('CSV 테이블이 비어있습니다. 기본 퀘스트를 사용합니다.');
        _setupDefaultQuests();
        return;
      }

      // 헤더 추출
      final headers = csvTable[0];
      print('CSV 헤더: $headers');
      
      if (headers.isEmpty || csvTable.length <= 1) {
        print('CSV 데이터가 올바르지 않습니다. 헤더 또는 데이터 행이 없습니다.');
        _setupDefaultQuests();
        return;
      }
      
      // 데이터 행 처리
      _quests = [];
      for (var i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];
        if (row.isEmpty) continue;
        
        try {
          // row를 Map으로 변환
          final Map<String, dynamic> rowMap = {};
          for (var j = 0; j < headers.length && j < row.length; j++) {
            String key = headers[j].toString();
            if (key.isEmpty) key = j.toString(); // 빈 헤더는 인덱스로 대체
            rowMap[key] = row[j].toString();
          }
          
          // 필수 필드 확인
          if (rowMap.containsKey('감정') && rowMap.containsKey('퀘스트') && rowMap.containsKey('난이도')) {
            final quest = Quest.fromCsv(rowMap);
            _quests.add(quest);
          } else {
            print('필수 필드가 없는 행 무시: $rowMap');
          }
        } catch (e) {
          print('행 파싱 오류: ${row}, 오류: $e');
        }
      }

      if (_quests.isEmpty) {
        print('CSV에서 유효한 퀘스트를 찾을 수 없습니다. 기본 퀘스트를 사용합니다.');
        _setupDefaultQuests();
        return;
      }

      // 감정별로 퀘스트 분류
      _questsByEmotion = {};
      for (var quest in _quests) {
        if (!_questsByEmotion.containsKey(quest.emotion)) {
          _questsByEmotion[quest.emotion] = [];
        }
        _questsByEmotion[quest.emotion]!.add(quest);
      }

      print('퀘스트 로드 완료: ${_quests.length}개');
      print('감정 종류: ${_questsByEmotion.keys.join(", ")}');
      
      // 퀘스트 ID 중복 확인 및 고유화 처리
      _ensureUniqueIds();
      
      // 일일 퀘스트 선택
      _setupDailyQuests();
      
      // 저장된 퀘스트 진행 상황 불러오기
      await loadProgress();

    } catch (e) {
      print('퀘스트 로드 오류: $e');
      _quests = [];
      _questsByEmotion = {};
      _setupDefaultQuests();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 특정 감정의 퀘스트 목록 반환
  List<Quest> getQuestsByEmotion(String emotion) {
    return _questsByEmotion[emotion] ?? [];
  }

  // 랜덤 퀘스트 반환
  Quest? getRandomQuest(String emotion) {
    final questList = _questsByEmotion[emotion];
    if (questList == null || questList.isEmpty) return null;
    questList.shuffle();
    return questList.first;
  }
  
  // 퀘스트 시작
  void startQuest(Quest quest) {
    final String questId = quest.id.toString();
    
    // 이미 진행 중인 퀘스트인 경우
    if (_questProgresses.containsKey(questId)) {
      // 이미 완료된 퀘스트는 다시 시작하지 않음
      if (_questProgresses[questId]!.isCompleted) {
        print('이미 완료된 퀘스트입니다: $questId');
        return;
      }
      
      // 진행 중이던 퀘스트를 활성화
      _activeQuestId = questId;
      print('기존 진행 중이던 퀘스트 활성화: $questId');
    } else {
      // 새로운 퀘스트 시작
      _questProgresses[questId] = QuestProgress(
        questId: questId,
        startTime: DateTime.now(),
        checkPoints: _generateCheckpoints(quest),
      );
      _activeQuestId = questId;
      print('새 퀘스트 시작: $questId');
    }
    
    // 타이머 시작
    _startQuestTimer();
    notifyListeners();
  }
  
  // 난이도별 체크포인트 생성
  List<String> _generateCheckpoints(Quest quest) {
    final checkpoints = <String>[];
    
    // 퀘스트 난이도에 따라 체크포인트 생성
    switch (quest.difficulty) {
      case '상':
        checkpoints.addAll([
          '준비하기',
          '시작하기',
          '중간점검',
          '마무리하기'
        ]);
        break;
      case '중':
        checkpoints.addAll([
          '준비하기',
          '수행하기',
          '마무리하기'
        ]);
        break;
      case '하':
        checkpoints.addAll([
          '시작하기',
          '완료하기'
        ]);
        break;
      default:
        checkpoints.addAll([
          '시작하기',
          '완료하기'
        ]);
    }
    
    return checkpoints;
  }
  
  // 타이머 시작
  void _startQuestTimer() {
    _questTimer?.cancel();
    _questTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners();  // UI 업데이트를 위해
    });
  }
  
  // 체크포인트 완료
  void completeCheckpoint(int index) {
    if (_activeQuestId == null || !_questProgresses.containsKey(_activeQuestId)) return;
    
    _questProgresses[_activeQuestId]!.completeCheckpoint(index);
    notifyListeners();
  }
  
  // 퀘스트 완료
  Future<bool> completeQuest(String questId) async {
    print('퀘스트 완료 요청: ID=$questId');
    
    // ID 정규화
    final String normalizedQuestId = questId.toString().trim();
    
    try {
      // 완료된 퀘스트 목록에 추가
      _completedQuestIds.add(normalizedQuestId);
      
      // 퀘스트 완료 처리
      toggleQuestCompletion(normalizedQuestId);
      
      // 현재 사용자에 대한 퀘스트 완료 기록 업데이트
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final FirebaseService _firebaseService = FirebaseService();
          await _firebaseService.updateUserField(
            user.uid, 
            'completedQuests', 
            FieldValue.arrayUnion([normalizedQuestId])
          );
          print('Firebase에 퀘스트 완료 기록 업데이트 성공: ID=$normalizedQuestId');
          
          // 퀘스트 목록에서 해당 퀘스트 찾기
          final Quest? targetQuest = _findQuestById(normalizedQuestId);
          if (targetQuest != null) {
            // GameService를 통해 보상 처리
            final GameService gameService = GameService();
            await gameService.processRewardForQuest(targetQuest);
            print('퀘스트 보상 처리: ${targetQuest.rewardPoints} 포인트/경험치를 GameService로 적용');
          }
        } catch (e) {
          print('Firebase에 퀘스트 완료 기록 업데이트 실패: $e');
        }
      }
      
      // 활성 퀘스트 ID가 완료된 퀘스트와 동일하면 초기화
      if (_activeQuestId == normalizedQuestId) {
        _activeQuestId = null; // 활성 퀘스트 초기화
        _questTimer?.cancel(); // 타이머 정지
        print('활성 퀘스트 초기화: 완료된 퀘스트 ID=$normalizedQuestId');
      }
      
      // 퀘스트 완료 처리 성공
      saveProgress();
      return true;
    } catch (e) {
      print('퀘스트 완료 처리 중 오류 발생: $e');
      return false;
    }
  }
  
  // 경과 시간 텍스트 반환
  String getElapsedTimeText() {
    if (_activeQuestId == null || !_questProgresses.containsKey(_activeQuestId)) return '00:00';
    
    final duration = _questProgresses[_activeQuestId]!.elapsedTime;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    return '$minutes:$seconds';
  }
  
  // 퀘스트 초기화
  void resetQuest() {
    if (_activeQuestId != null) {
      _questProgresses.remove(_activeQuestId);
      _activeQuestId = null;
    }
    _questTimer?.cancel();
    notifyListeners();
  }

  // 모든 퀘스트 진행 상황 초기화
  void resetAllQuestProgresses() {
    _questProgresses.clear();
    _activeQuestId = null;
    _questTimer?.cancel();
    notifyListeners();
  }

  void _setupDefaultQuests() {
    _quests = [
      Quest(
        id: 'default_1_${DateTime.now().millisecondsSinceEpoch}',
        title: '감정 일기 작성하기', 
        description: '오늘 하루 동안 느낀 감정을 기록해보세요.',
        category: '일상',
        rewardPoints: 10,
        isCompleted: false,
      ),
      Quest(
        id: 'default_2_${DateTime.now().millisecondsSinceEpoch + 1}',
        title: '긍정적인 감정 찾기', 
        description: '오늘 경험한 긍정적인 감정을 3가지 이상 찾아보세요.',
        category: '긍정',
        rewardPoints: 15,
        isCompleted: false,
      ),
      Quest(
        id: 'default_3_${DateTime.now().millisecondsSinceEpoch + 2}',
        title: '명상하기', 
        description: '5분 동안 명상을 하며 마음을 안정시켜보세요.',
        category: '마음챙김',
        rewardPoints: 20,
        isCompleted: false,
      ),
    ];
    
    notifyListeners();
  }
  
  void _setupDailyQuests() {
    // 기존 이름을 유지하되 일일 퀘스트 개념은 제거
    
    // 기존 완료된 퀘스트 상태 저장
    final Set<String> completedQuestIds = _quests
        .where((Quest q) => q.isCompleted)
        .map((Quest q) => q.id.toString())
        .toSet();
    
    // 카테고리별로 퀘스트를 그룹화
    Map<String, List<Quest>> questsByCategory = {};
    
    for (Quest quest in _quests) {
      if (!questsByCategory.containsKey(quest.category)) {
        questsByCategory[quest.category] = [];
      }
      questsByCategory[quest.category]!.add(quest);
    }
    
    List<Quest> randomQuests = [];
    
    // 최대 5개까지 퀘스트 제공 (각 카테고리당 최대 1개씩)
    final List<String> categories = questsByCategory.keys.toList();
    categories.shuffle(); // 카테고리 순서 섞기
    
    // 먼저 필요한 카테고리에서 하나씩 추가
    final int categoryCount = categories.length > 5 ? 5 : categories.length;
    for (int i = 0; i < categoryCount; i++) {
      final String category = categories[i];
      final List<Quest> categoryQuests = questsByCategory[category]!;
      categoryQuests.shuffle();
      
      if (categoryQuests.isNotEmpty) {
        randomQuests.add(categoryQuests.first);
      }
    }
    
    // 이전에 완료된 퀘스트 상태 복원 및 타입 명시
    randomQuests = randomQuests.map<Quest>((Quest quest) {
      // 완료된 퀘스트 ID가 있으면 완료 상태로 복원, 아니면 미완료 상태로 유지
      if (completedQuestIds.contains(quest.id)) {
        return quest.copyWith(isCompleted: true);
      }
      return quest.copyWith(isCompleted: false); // 명시적으로 false 설정
    }).toList();
    
    // 랜덤 퀘스트로 기존 퀘스트 목록 업데이트
    // 여기서는 모든 퀘스트를 교체하지 않고, 추가할 수도 있음
    _quests = randomQuests;
    
    print('퀘스트 설정 완료: ${_quests.length}개, 감정 종류: ${categories.length}개');
  }
  
  // 퀘스트 완료 상태 토글
  void toggleQuestCompletion(String questId) {
    print('퀘스트 완료 토글 요청: ID=$questId');
    
    // ID 정규화: 항상 문자열로
    final String normalizedQuestId = questId.toString().trim();
    
    // 1. 먼저 진행 상태에 영향을 주는 코드: 퀘스트의 진행 상황을 완료로 설정 (이미 완료 상태인 경우 무시)
    final currentProgress = _questProgresses[normalizedQuestId];
    if (currentProgress != null && !currentProgress.isCompleted) {
      currentProgress.complete();
      print('퀘스트 진행 상황 완료로 설정: ${normalizedQuestId}');
      
      // 진행 중인 퀘스트가 완료되면 활성 퀘스트 초기화
      if (_activeQuestId == normalizedQuestId) {
        _activeQuestId = null;
        _questTimer?.cancel();
        print('활성 퀘스트 초기화: ${normalizedQuestId}');
      }
    }
    
    // 2. 일일 퀘스트 목록에서 일치하는 퀘스트 찾기 (ID 형식 표준화)
    print('일일 퀘스트 수: ${_quests.length}');
    print('찾는 ID: $normalizedQuestId');
    
    _quests.forEach((quest) {
      print('퀘스트 ID 비교: ${quest.id.toString()} vs $normalizedQuestId');
    });
    
    final int questIndex = _quests.indexWhere((Quest q) {
      return q.id.toString() == normalizedQuestId;
    });
    
    if (questIndex != -1) {
      final Quest questToToggle = _quests[questIndex];
      print('퀘스트 찾음: ID=${questToToggle.id}, 제목=${questToToggle.title}, 현재상태=${questToToggle.isCompleted}');
      
      // 상태를 true로만 변경 (완료 상태로만 변경하고, 완료 취소는 하지 않음)
      if (!questToToggle.isCompleted) {
        _quests[questIndex] = questToToggle.copyWith(isCompleted: true);
        print('퀘스트 상태 변경: ${questToToggle.isCompleted} -> true');
      } else {
        print('퀘스트가 이미 완료 상태입니다. 상태 유지: true');
      }
      
      // 상태 변경 후 저장
      saveProgress();
      notifyListeners();
    } else {
      print('경고: ID=$normalizedQuestId에 해당하는 일일 퀘스트를 찾을 수 없습니다');
    }
  }
  
  // 새로운 퀘스트 세트 생성 (기존 완료 상태 보존하지 않음)
  void refreshDailyQuests() {
    // 새 퀘스트 세트 생성 (완료 상태 초기화)
    _setupDailyQuests();
    
    // 완료된 퀘스트 진행 상황은 그대로 유지 (_questProgresses는 유지)
    // 하지만 일일 퀘스트의 완료 상태는 초기화됨
    
    print('퀘스트 새로고침 완료: ${_quests.length}개 새로운 퀘스트');
    
    // 상태 변경 후 저장
    saveProgress();
    notifyListeners();
  }
  
  // 퀘스트 진행 상황 저장 (확장)
  Future<void> saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 퀘스트 진행 상황을 Map<String, dynamic>으로 변환
      final Map<String, dynamic> progressesJson = Map.fromEntries(
        _questProgresses.entries.map((entry) => 
          MapEntry(entry.key, entry.value.toJson())
        )
      );
      
      // 진행 중인 퀘스트 정보 저장
      await prefs.setString('quest_progresses', jsonEncode(progressesJson));
      if (_activeQuestId != null) {
        await prefs.setString('active_quest_id', _activeQuestId!);
      } else {
        await prefs.remove('active_quest_id');
      }
      
      // 완료된 퀘스트 ID 저장
      await prefs.setStringList('all_completed_quest_ids', _completedQuestIds.toList());
      
      // 기존 일일 퀘스트 관련 정보를 모든 퀘스트 정보로 변경
      final List<String> completedQuestIds = _quests
          .where((Quest q) => q.isCompleted)
          .map((Quest q) => q.id.toString())
          .toList();
          
      await prefs.setStringList('completed_quest_ids', completedQuestIds);
      
      final List<Map<String, dynamic>> questsJson = _quests.map((quest) => quest.toJson()).toList();
      await prefs.setString('quests', jsonEncode(questsJson));
      
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';
      await prefs.setString('last_quest_update', dateStr);
      
      print('퀘스트 진행 상황 저장 완료: 진행 중 ${_questProgresses.length}개, 완료 ${completedQuestIds.length}개, 총 완료 ${_completedQuestIds.length}개');
    } catch (e) {
      print('퀘스트 진행 상황 저장 오류: $e');
    }
  }
  
  // 퀘스트 진행 상황 불러오기 (확장)
  Future<void> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 오늘 날짜와 마지막 업데이트 날짜 비교
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final lastUpdateStr = prefs.getString('last_quest_update') ?? '';
      
      // 완료된 퀘스트 ID 목록 로드 (날짜와 상관없이 항상 로드)
      final allCompletedIds = prefs.getStringList('all_completed_quest_ids') ?? [];
      _completedQuestIds = Set<String>.from(allCompletedIds);
      print('모든 완료된 퀘스트: ${_completedQuestIds.length}개 로드됨');
      
      // 같은 날짜인 경우에만 이전 상태 복원
      if (todayStr == lastUpdateStr) {
        // 1. 진행 중인 퀘스트 정보 불러오기
        final progressesJson = prefs.getString('quest_progresses');
        final activeQuestId = prefs.getString('active_quest_id');
        
        if (progressesJson != null) {
          try {
            final Map<String, dynamic> decodedData = jsonDecode(progressesJson);
            _questProgresses = Map.fromEntries(
              decodedData.entries.map((entry) => 
                MapEntry(entry.key, QuestProgress.fromJson(entry.value))
              )
            );
            _activeQuestId = activeQuestId;
            
            print('퀘스트 진행 상황 불러오기 완료: ${_questProgresses.length}개');
            
            // 타이머 복원
            if (_activeQuestId != null) {
              _startQuestTimer();
            }
          } catch (e) {
            print('퀘스트 진행 상황 데이터 파싱 오류: $e');
            _questProgresses = {};
            _activeQuestId = null;
          }
        }
        
        // 2. 저장된 퀘스트 및 완료 상태 불러오기
        final completedQuestIds = prefs.getStringList('completed_quest_ids') ?? [];
        final questsJson = prefs.getString('quests');
        
        if (questsJson != null) {
          try {
            final List<dynamic> decodedQuestsData = jsonDecode(questsJson);
            final List<Quest> loadedQuests = decodedQuestsData
                .map((data) => Quest.fromJson(data))
                .toList();
                
            if (loadedQuests.isNotEmpty) {
              _quests = loadedQuests;
              print('저장된 퀘스트 ${loadedQuests.length}개 로드 완료');
              
              // 완료 상태 설정
              for (int i = 0; i < _quests.length; i++) {
                final quest = _quests[i];
                if (completedQuestIds.contains(quest.id.toString())) {
                  _quests[i] = quest.copyWith(isCompleted: true);
                }
              }
              
              if (completedQuestIds.isNotEmpty) {
                print('완료된 퀘스트 ${completedQuestIds.length}개 상태 복원');
              }
            }
          } catch (e) {
            print('저장된 퀘스트 데이터 파싱 오류: $e');
          }
        }
      } else {
        print('새로운 날짜로 퀘스트 초기화 또는 저장된 데이터 없음');
        _questProgresses = {};
        _activeQuestId = null;
        
        // 새로운 날짜인 경우 퀘스트 새로 설정
        if (todayStr != lastUpdateStr) {
          _setupDailyQuests(); // 메서드 이름은 유지하되 기능은 변경
          saveProgress();
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('퀘스트 진행 상황 불러오기 오류: $e');
    }
  }
  
  // 일일 퀘스트 관련 이름을 가진 메서드들 이름 변경
  List<Quest> getAvailableQuests() {
    return _quests;
  }
  
  // 완료된 퀘스트 개수 (모든 완료된 퀘스트 포함)
  int getCompletedQuestsCount() {
    // 현재 표시된 퀘스트 중 완료된 퀘스트 수
    int displayedCompleted = _quests.where((Quest q) => q.isCompleted).length;
    
    // 완료된 퀘스트 ID 목록에서 현재 표시된 퀘스트가 아닌 것들의 수
    int otherCompleted = _completedQuestIds.where((id) => 
      !_quests.any((q) => q.id.toString() == id)
    ).length;
    
    print('완료된 현재 퀘스트: $displayedCompleted, 기타 완료된 퀘스트: $otherCompleted');
    
    // 완료된 모든 퀘스트의 수
    return displayedCompleted + otherCompleted;
  }
  
  // 경험치를 받을 수 있는 완료된 퀘스트 개수 (최대 3개까지만 계산)
  int getExperienceEligibleQuestsCount() {
    int completedCount = getCompletedQuestsCount();
    return completedCount > 3 ? 3 : completedCount;
  }

  Quest? _findQuestById(String questId) {
    try {
      return _quests.firstWhere((quest) => quest.id.toString() == questId);
    } catch (e) {
      print('퀘스트를 찾지 못했습니다: ID=$questId, 오류=$e');
      return null;
    }
  }

  // 퀘스트가 완료되었는지 확인
  bool isQuestCompleted(String questId) {
    // ID 정규화
    final String normalizedQuestId = questId.toString().trim();
    
    // 1. 진행 상황에서 확인
    final progress = _questProgresses[normalizedQuestId];
    if (progress != null && progress.isCompleted) {
      return true;
    }
    
    // 2. 일일 퀘스트에서 확인
    final int questIndex = _quests.indexWhere((q) => q.id.toString() == normalizedQuestId);
    if (questIndex != -1 && _quests[questIndex].isCompleted) {
      return true;
    }
    
    // 3. 완료된 퀘스트 ID 목록에서 확인
    if (_completedQuestIds.contains(normalizedQuestId)) {
      return true;
    }
    
    return false;
  }

  // 퀘스트 로드 시 ID 중복 확인 및 고유화 처리 메서드 추가
  void _ensureUniqueIds() {
    final Set<String> usedIds = {};
    final List<Quest> updatedQuests = [];
    
    for (var quest in _quests) {
      String questId = quest.id.toString();
      
      // ID가 이미 사용된 경우 새 ID 생성
      if (usedIds.contains(questId)) {
        final String newId = '${questId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        print('ID 중복 감지: $questId -> $newId로 대체');
        questId = newId;
        
        // 새 Quest 인스턴스 생성 (ID 변경)
        quest = Quest(
          id: newId,
          title: quest.title,
          description: quest.description,
          category: quest.category,
          rewardPoints: quest.rewardPoints,
          isCompleted: quest.isCompleted,
        );
      }
      
      usedIds.add(questId);
      updatedQuests.add(quest);
    }
    
    // 업데이트된 퀘스트 목록으로 대체
    _quests = updatedQuests;
  }
} 