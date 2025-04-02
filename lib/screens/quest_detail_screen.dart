import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quest_service.dart';
import '../services/game_service.dart';
import '../models/quest.dart';
import '../models/quest_progress.dart';

class QuestDetailScreen extends StatefulWidget {
  final Quest quest;
  
  const QuestDetailScreen({Key? key, required this.quest}) : super(key: key);

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  bool _isCompleting = false;

  @override
  Widget build(BuildContext context) {
    final questService = Provider.of<QuestService>(context);
    final gameService = Provider.of<GameService>(context);
    final currentProgress = questService.currentProgress;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트 진행'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // 퀘스트 초기화 확인 다이얼로그
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('퀘스트 취소'),
                  content: const Text('진행 중인 퀘스트를 취소하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('아니요'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 다이얼로그 닫기
                        questService.resetQuest();
                        Navigator.pop(context); // 화면 닫기
                      },
                      child: const Text('예'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 퀘스트 정보
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
                            widget.quest.category,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '+${widget.quest.rewardPoints} 포인트',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.quest.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.quest.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 타이머 및 진행 상황
            if (currentProgress != null) ...[
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
                      ? () async {
                          setState(() => _isCompleting = true);
                          
                          // 퀘스트 완료 처리
                          final success = await questService.completeQuest(widget.quest.id);
                          
                          if (success && mounted) {
                            // 경험치와 포인트 추가 (위 toggleQuestCompletion이 단순히 완료 상태만 변경함)
                            await gameService.processRewardForQuest(widget.quest);
                            
                            // 완료 메시지 및 화면 닫기
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.quest.title} 퀘스트를 완료했습니다! +${widget.quest.rewardPoints} 포인트/경험치'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            Navigator.pop(context);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('퀘스트 완료 처리 중 오류가 발생했습니다.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => _isCompleting = false);
                          }
                        }
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
            
            // 퀘스트 아직 시작 안 된 경우 시작 버튼 표시
            if (currentProgress == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    questService.startQuest(widget.quest);
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
      ),
    );
  }
  
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
} 