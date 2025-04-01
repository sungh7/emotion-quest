import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/quest_service.dart';
import '../models/quest.dart';
import '../services/firebase_service.dart';

class QuestHistoryScreen extends StatefulWidget {
  const QuestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QuestHistoryScreen> createState() => _QuestHistoryScreenState();
}

class _QuestHistoryScreenState extends State<QuestHistoryScreen> {
  List<Map<String, dynamic>> _questHistory = [];
  bool _isLoading = true;
  final Map<int, Quest> _questCache = {};
  
  @override
  void initState() {
    super.initState();
    _loadQuestHistory();
  }
  
  Future<void> _loadQuestHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Firebase에서 퀘스트 히스토리 로드
      final history = await FirebaseService.loadQuestProgress();
      
      if (mounted) {
        setState(() {
          _questHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('퀘스트 히스토리 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퀘스트 히스토리를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 퀘스트 ID로 퀘스트 정보 가져오기
  Quest? _getQuestById(int questId) {
    // 캐시에 있으면 바로 반환
    if (_questCache.containsKey(questId)) {
      return _questCache[questId];
    }
    
    // 캐시에 없으면 QuestService에서 찾기
    final questService = Provider.of<QuestService>(context, listen: false);
    for (final quest in questService.quests) {
      if (quest.id == questId) {
        // 캐시에 저장
        _questCache[questId] = quest;
        return quest;
      }
    }
    return null;
  }
  
  // 퀘스트 난이도에 따른 색상 반환
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '상':
        return Colors.red;
      case '중':
        return Colors.orange;
      case '하':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 히스토리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuestHistory,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '아직 완료한 퀘스트가 없습니다',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '퀘스트를 완료하면 여기에 기록됩니다',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _questHistory.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final questProgress = _questHistory[index];
                    final questId = questProgress['questId'] as int;
                    final quest = _getQuestById(questId);
                    
                    // 시작 시간 형식화
                    final startTime = DateTime.fromMillisecondsSinceEpoch(
                      questProgress['startTime'] as int,
                    );
                    final formattedStartTime = DateFormat('yyyy년 MM월 dd일 HH:mm').format(startTime);
                    
                    // 완료 시간 형식화
                    String? formattedCompletionTime;
                    if (questProgress['completionTime'] != null) {
                      final completionTime = DateTime.fromMillisecondsSinceEpoch(
                        questProgress['completionTime'] as int,
                      );
                      formattedCompletionTime = DateFormat('yyyy년 MM월 dd일 HH:mm').format(completionTime);
                    }
                    
                    // 경과 시간 계산
                    String elapsedTime = '알 수 없음';
                    if (questProgress['completionTime'] != null && questProgress['startTime'] != null) {
                      final start = DateTime.fromMillisecondsSinceEpoch(questProgress['startTime'] as int);
                      final end = DateTime.fromMillisecondsSinceEpoch(questProgress['completionTime'] as int);
                      final duration = end.difference(start);
                      
                      if (duration.inHours > 0) {
                        elapsedTime = '${duration.inHours}시간 ${(duration.inMinutes % 60)}분';
                      } else if (duration.inMinutes > 0) {
                        elapsedTime = '${duration.inMinutes}분 ${(duration.inSeconds % 60)}초';
                      } else {
                        elapsedTime = '${duration.inSeconds}초';
                      }
                    }
                    
                    // 체크포인트 진행 상황
                    final checkPoints = questProgress['checkPoints'] as List<dynamic>? ?? [];
                    final completedCheckpoints = checkPoints.where((cp) => cp.toString().startsWith('✓')).length;
                    final checkpointProgress = checkPoints.isEmpty ? 0.0 : completedCheckpoints / checkPoints.length;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 날짜 및 퀘스트 이름
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 퀘스트 이모지 또는 아이콘
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.fitness_center, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // 퀘스트 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        quest?.title ?? '알 수 없는 퀘스트',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        formattedStartTime,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // 난이도 표시
                                if (quest != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getDifficultyColor(quest.difficulty),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      quest.difficulty,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 진행 상황
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('완료 상태: '),
                                    const SizedBox(width: 8),
                                    if (questProgress['isCompleted'] == true)
                                      const Text(
                                        '완료됨',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    else
                                      const Text(
                                        '진행 중',
                                        style: TextStyle(
                                          color: Colors.orange,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('소요 시간: '),
                                    const SizedBox(width: 8),
                                    Text(elapsedTime),
                                  ],
                                ),
                                if (formattedCompletionTime != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('완료 시간: '),
                                      const SizedBox(width: 8),
                                      Text(formattedCompletionTime),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('체크리스트: '),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: checkpointProgress,
                                        backgroundColor: Colors.grey[300],
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${(checkpointProgress * 100).toInt()}%'),
                                  ],
                                ),
                              ],
                            ),
                            
                            // 보상 표시
                            if (quest != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '보상: ${quest.expReward} EXP',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 