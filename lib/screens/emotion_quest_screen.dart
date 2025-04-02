import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quest_service.dart';
import '../services/game_service.dart';
import '../services/firebase_service.dart';
import '../models/quest.dart';
import '../models/quest_progress.dart';

// Checkpoint 클래스 추가
class Checkpoint {
  final String title;
  bool isCompleted;
  
  Checkpoint({required this.title, this.isCompleted = false});
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
  };
}

class EmotionQuestScreen extends StatefulWidget {
  final String selectedEmotion;
  final Quest? quest;
  
  const EmotionQuestScreen({
    Key? key,
    required this.selectedEmotion,
    this.quest,
  }) : super(key: key);

  @override
  State<EmotionQuestScreen> createState() => _EmotionQuestScreenState();
}

class _EmotionQuestScreenState extends State<EmotionQuestScreen> {
  bool _isLoading = true;
  List<Quest> _quests = [];
  Quest? _selectedQuest;
  bool _isCompleting = false;
  QuestProgress? _currentProgress;
  DateTime _startTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    if (widget.quest != null) {
      setState(() {
        _selectedQuest = widget.quest;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeQuest();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAndSelectRandomQuest();
      });
    }
  }
  
  void _initializeQuest() {
    if (_selectedQuest != null && mounted) {
      try {
        final questService = Provider.of<QuestService>(context, listen: false);
        
        // 현재 이미 진행중인 퀘스트인지 확인
        final existingProgress = questService.getQuestProgress(_selectedQuest!.id.toString());
        
        if (existingProgress != null && existingProgress.isCompleted) {
          // 이미 완료된 퀘스트인 경우
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미 완료한 퀘스트입니다.'))
            );
          }
        } else {
          // 퀘스트 시작 또는 계속 진행
          questService.startQuest(_selectedQuest!);
        }
      } catch (e) {
        print('퀘스트 초기화 오류: $e');
      }
    }
  }
  
  // 퀘스트를 로드하고 랜덤으로 선택
  Future<void> _loadAndSelectRandomQuest() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 선택된 감정에 맞는 퀘스트 로드
      final questService = Provider.of<QuestService>(context, listen: false);
      
      // 디버그 정보 출력
      print('감정 카테고리: ${widget.selectedEmotion}');
      print('사용 가능한 감정 목록: ${questService.availableEmotions.join(', ')}');
      
      // 정확한 감정 일치 확인
      List<Quest> targetQuests = questService.getQuestsByEmotion(widget.selectedEmotion);
      
      // 퀘스트가 없을 경우 비슷한 감정이나 다른 소스에서 퀘스트 찾기
      if (targetQuests.isEmpty) {
        print('선택된 감정(${widget.selectedEmotion})의 퀘스트를 찾을 수 없습니다. 대체 퀘스트를 찾습니다.');
        
        // 1. 먼저 모든 퀘스트에서 비슷한 카테고리 검색
        for (var quest in questService.getAvailableQuests()) {
          if (quest.category.toLowerCase().contains(widget.selectedEmotion.toLowerCase()) ||
              widget.selectedEmotion.toLowerCase().contains(quest.category.toLowerCase())) {
            targetQuests.add(quest);
          }
        }
        
        // 2. 여전히 없으면 전체 퀘스트에서 검색
        if (targetQuests.isEmpty) {
          for (var emotion in questService.availableEmotions) {
            List<Quest> emotionQuests = questService.getQuestsByEmotion(emotion);
            if (emotionQuests.isNotEmpty) {
              targetQuests.addAll(emotionQuests);
              break;
            }
          }
        }
        
        // 3. 여전히 없으면 그냥 전체 퀘스트 추가
        if (targetQuests.isEmpty) {
          targetQuests = List<Quest>.from(questService.getAvailableQuests());
        }
      }
      
      print('찾은 퀘스트 수: ${targetQuests.length}개');
      
      if (targetQuests.isEmpty) {
        print('퀘스트를 찾을 수 없습니다.');
        if (mounted) {
          setState(() {
            _quests = [];
            _selectedQuest = null;
            _isLoading = false;
          });
        }
        return;
      }
      
      // 미완료 퀘스트 먼저 필터링
      List<Quest> incompleteQuests = targetQuests.where((quest) {
        return !questService.isQuestCompleted(quest.id.toString());
      }).toList();
      
      print('미완료 퀘스트 수: ${incompleteQuests.length}개');
      
      // 미완료 퀘스트가 있으면 해당 퀘스트 중에서 선택, 없으면 모든 퀘스트 중에서 선택
      List<Quest> availableQuests = incompleteQuests.isNotEmpty ? incompleteQuests : targetQuests;
      
      if (availableQuests.isEmpty) {
        print('사용 가능한 퀘스트가 없습니다.');
        if (mounted) {
          setState(() {
            _quests = [];
            _selectedQuest = null;
            _isLoading = false;
          });
        }
        return;
      }
      
      // 랜덤으로 퀘스트 선택
      availableQuests.shuffle();
      final selectedQuest = availableQuests.first;
      
      print('선택된 퀘스트: ID=${selectedQuest.id}, 제목=${selectedQuest.title}');
      
      if (mounted) {
        setState(() {
          _quests = availableQuests;
          _selectedQuest = selectedQuest;
          _isLoading = false;
        });
        
        // 퀘스트 시작
        _initializeQuest();
      }
    } catch (e) {
      print('퀘스트 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedQuest = null;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final questService = Provider.of<QuestService>(context);
    final gameService = Provider.of<GameService>(context);
    
    // 현재 선택된 퀘스트의 진행 상황 확인
    QuestProgress? currentProgress;
    if (_selectedQuest != null) {
      currentProgress = questService.getQuestProgress(_selectedQuest!.id.toString());
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedEmotion} 퀘스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAndSelectRandomQuest,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _selectedQuest == null
            ? _buildEmptyQuestScreen()
            : _buildQuestDetailScreen(questService, gameService, currentProgress),
    );
  }
  
  Widget _buildEmptyQuestScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '현재 이 감정에 맞는 퀘스트가 없습니다.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestDetailScreen(QuestService questService, GameService gameService, QuestProgress? currentProgress) {
    // 선택된 퀘스트 가져오기
    final Quest quest = _selectedQuest!;
    final String questId = quest.id.toString();
    
    // 이 퀘스트가 퀘스트 목록에 있는지 확인
    final int questIndex = questService.getAvailableQuests()
        .indexWhere((q) => q.id.toString() == questId);
    final bool isInQuestList = questIndex != -1;
    final bool isCompletedInQuestList = isInQuestList && 
        questService.getAvailableQuests()[questIndex].isCompleted;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 퀘스트 정보 카드
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quest.category,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+${quest.rewardPoints} 포인트',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    quest.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quest.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  if (isInQuestList) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.today,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '오늘의 퀘스트',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCompletedInQuestList) ...[
                          const Spacer(),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '완료됨',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // 타이머 및 진행 상황 카드
          if (currentProgress != null && !isCompletedInQuestList) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '진행 시간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        questService.getElapsedTimeText(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 진행률 표시
                    LinearProgressIndicator(
                      value: currentProgress.progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '진행률: ${(currentProgress.progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 체크포인트 목록
                    const Text(
                      '체크포인트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                      currentProgress.checkPoints.length,
                      (index) => _buildCheckpointItem(
                        context,
                        currentProgress.checkPoints[index],
                        index,
                        questService,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // 완료 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: currentProgress.progress == 1.0 && !_isCompleting
                    ? () => _completeQuest()
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isCompleting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '퀘스트 완료',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
          
          // 이미 완료된 일일 퀘스트인 경우 메시지 표시
          if (isCompletedInQuestList)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    '이미 완료한 퀘스트입니다',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '이 퀘스트는 오늘의 퀘스트로 이미 완료되었습니다.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _loadAndSelectRandomQuest,
                    child: const Text('다른 퀘스트 찾기'),
                  ),
                ],
              ),
            ),
          
          // 퀘스트 시작하기 버튼
          if (currentProgress == null && !isCompletedInQuestList)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _initializeQuest();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '퀘스트 시작하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 체크포인트 아이템 위젯
  Widget _buildCheckpointItem(
    BuildContext context,
    String checkpoint,
    int index,
    QuestService questService,
  ) {
    final isCompleted = checkpoint.startsWith('✓');
    final checkpointText = isCompleted ? checkpoint.substring(2) : checkpoint;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (isCompleted)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            Icon(Icons.radio_button_unchecked, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              checkpointText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () {
                questService.completeCheckpoint(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('완료'),
            ),
        ],
      ),
    );
  }
  
  // 퀘스트 완료 로직
  Future<void> _completeQuest() async {
    // 퀘스트 ID 확인
    final Quest questToComplete = _selectedQuest ?? widget.quest!;
    if (questToComplete == null) {
      print('완료할 퀘스트가 없습니다.');
      return;
    }
    
    setState(() {
      _isCompleting = true;
    });
    
    final String questId = questToComplete.id.toString();
    print('퀘스트 완료 시도: ID=$questId, 제목=${questToComplete.title}');
    
    try {
      final QuestService questService = Provider.of<QuestService>(context, listen: false);
      final isSuccess = await questService.completeQuest(questId);
      
      if (isSuccess && mounted) {
        print('퀘스트 완료 성공: $questId');
        
        // 성공 메시지 및 보상 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${questToComplete.title} 퀘스트를 완료했습니다! +${questToComplete.rewardPoints} 포인트'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 완료 다이얼로그 표시
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false, // 뒤로 가기 버튼 비활성화
            child: AlertDialog(
              title: const Text('퀘스트 완료!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text('축하합니다! 퀘스트를 성공적으로 완료했습니다.'),
                  const SizedBox(height: 8),
                  Text('보상: +${questToComplete.rewardPoints} 포인트'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.of(context).pop(); // EmotionQuestScreen 닫고 이전 화면으로 돌아가기
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        );
      } else if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퀘스트 완료 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('퀘스트 완료 처리 중 오류: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('퀘스트 완료 처리 중 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 