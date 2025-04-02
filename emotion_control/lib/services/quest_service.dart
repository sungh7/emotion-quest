import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:async';
import '../models/quest.dart';
import '../models/quest_progress.dart';
import '../services/firebase_service.dart';

class QuestService extends ChangeNotifier {
  List<Quest> _quests = [];
  Map<String, List<Quest>> _questsByEmotion = {};
  bool _isLoading = false;
  QuestProgress? _currentProgress;
  Timer? _questTimer;

  // 게터
  List<Quest> get quests => _quests;
  Map<String, List<Quest>> get questsByEmotion => _questsByEmotion;
  bool get isLoading => _isLoading;
  List<String> get availableEmotions => _questsByEmotion.keys.toList();
  QuestProgress? get currentProgress => _currentProgress;

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

      // CSV 파일 읽기
      final String csvData = await rootBundle.loadString('assets/emotional_quest.csv');
      print('CSV 데이터 로드: ${csvData.length} 바이트');
      
      // 명시적으로 구분자 설정 (쉼표로 설정)
      List<List<dynamic>> csvTable = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(csvData);
      
      print('CSV 변환 결과: ${csvTable.length} 행');

      if (csvTable.isEmpty) {
        print('CSV 테이블이 비어있습니다.');
        return;
      }

      // 헤더 추출
      final headers = csvTable[0];
      print('CSV 헤더: $headers');
      
      if (headers.isEmpty || csvTable.length <= 1) {
        print('CSV 데이터가 올바르지 않습니다. 헤더 또는 데이터 행이 없습니다.');
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

    } catch (e) {
      print('퀘스트 로드 오류: $e');
      _quests = [];
      _questsByEmotion = {};
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
    _currentProgress = QuestProgress(
      questId: quest.id,
      startTime: DateTime.now(),
      checkPoints: _generateCheckpoints(quest),
    );
    
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
    if (_currentProgress == null) return;
    _currentProgress!.completeCheckpoint(index);
    notifyListeners();
  }
  
  // 퀘스트 완료
  Future<bool> completeQuest() async {
    if (_currentProgress == null) return false;
    
    _currentProgress!.complete();
    _questTimer?.cancel();
    
    // Firebase에 저장
    try {
      await FirebaseService.saveQuestProgress(_currentProgress!.toJson());
      notifyListeners();
      return true;
    } catch (e) {
      print('퀘스트 진행 상태 저장 실패: $e');
      return false;
    }
  }
  
  // 경과 시간 텍스트 반환
  String getElapsedTimeText() {
    if (_currentProgress == null) return '00:00';
    
    final duration = _currentProgress!.elapsedTime;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    
    return '$minutes:$seconds';
  }
  
  // 퀘스트 초기화
  void resetQuest() {
    _currentProgress = null;
    _questTimer?.cancel();
    notifyListeners();
  }
} 