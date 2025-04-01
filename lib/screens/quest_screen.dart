import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/quest.dart';
import '../models/quest_progress.dart';
import '../services/quest_service.dart';
import '../services/game_service.dart';
import 'package:confetti/confetti.dart';

class QuestScreen extends StatefulWidget {
  final String emotion;
  final String emoji;

  const QuestScreen({
    Key? key,
    required this.emotion,
    required this.emoji,
  }) : super(key: key);

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  Quest? _currentQuest;
  bool _isCompleted = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _loadQuest();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // 퀘스트 로드
  void _loadQuest() {
    final questService = Provider.of<QuestService>(context, listen: false);
    final quest = questService.getRandomQuest(widget.emotion);
    setState(() {
      _currentQuest = quest;
      _isCompleted = false;
    });
    
    // 퀘스트 시작
    if (quest != null) {
      questService.startQuest(quest);
    }
  }

  // 퀘스트 완료 처리
  Future<void> _completeQuest() async {
    if (_currentQuest == null || _isCompleted) return;

    final questService = Provider.of<QuestService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);
    
    // 퀘스트 완료 처리
    bool success = await questService.completeQuest();
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('퀘스트 완료 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // 경험치 추가 및 퀘스트 완료 카운트 증가
    if (_currentQuest != null) {
      // 현재 레벨 저장
      final int prevLevel = gameService.userStats?.level ?? 1;
      
      // 경험치 추가
      final expReward = await gameService.processRewardForQuest(_currentQuest!);
      
      // 레벨업 체크 및 효과 표시
      if (gameService.userStats != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 퀘스트 완료! +$expReward EXP 획득'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 레벨업 확인
          if (gameService.userStats!.level > prevLevel) {
            _confettiController.play();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 레벨 ${gameService.userStats!.level}로 레벨업!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    }

    setState(() {
      _isCompleted = true;
    });
  }
  
  // 퀘스트 재설정
  void _resetQuest() {
    final questService = Provider.of<QuestService>(context, listen: false);
    questService.resetQuest();
    _loadQuest();
  }

  @override
  Widget build(BuildContext context) {
    final questService = Provider.of<QuestService>(context);
    final progress = questService.currentProgress;
    
    if (_currentQuest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('퀘스트')),
        body: const Center(child: Text('퀘스트를 불러올 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 퀘스트'),
        actions: [
          // 타이머 표시
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  questService.getElapsedTimeText(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetQuest,
            tooltip: '새로운 퀘스트',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 감정 표시
              Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 72),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.emotion,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 진행 상태 표시
              if (progress != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('진행률: '),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress.progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(progress.progress * 100).toInt()}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // 퀘스트 정보
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 난이도 및 보상 표시
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(_currentQuest!.difficulty),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _currentQuest!.difficulty,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '보상: ${_currentQuest!.expReward} EXP',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 퀘스트 제목
                      Text(
                        _currentQuest!.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 퀘스트 설명
                      Text(
                        _currentQuest!.task,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      
                      // 체크포인트 목록
                      if (progress != null && progress.checkPoints.isNotEmpty) ...[
                        const Text(
                          '체크리스트',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          progress.checkPoints.length,
                          (index) => CheckboxListTile(
                            value: progress.checkPoints[index].startsWith('✓'),
                            onChanged: _isCompleted 
                              ? null
                              : (value) {
                                  if (value == true) {
                                    questService.completeCheckpoint(index);
                                  }
                                },
                            title: Text(
                              progress.checkPoints[index].replaceAll('✓ ', ''),
                              style: TextStyle(
                                decoration: progress.checkPoints[index].startsWith('✓')
                                  ? TextDecoration.lineThrough
                                  : null,
                                color: progress.checkPoints[index].startsWith('✓')
                                  ? Colors.grey
                                  : null,
                              ),
                            ),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 퀘스트 완료 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isCompleted ? null : _completeQuest,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            _isCompleted ? '퀘스트 완료!' : '퀘스트 완료하기',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

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
} 