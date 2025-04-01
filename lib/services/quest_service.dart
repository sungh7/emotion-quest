import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/quest.dart';

class QuestService extends ChangeNotifier {
  List<Quest> _quests = [];
  Map<String, List<Quest>> _questsByEmotion = {};
  bool _isLoading = false;

  // 게터
  List<Quest> get quests => _quests;
  Map<String, List<Quest>> get questsByEmotion => _questsByEmotion;
  bool get isLoading => _isLoading;
  List<String> get availableEmotions => _questsByEmotion.keys.toList();

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
} 