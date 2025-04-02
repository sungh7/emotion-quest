import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quest_service.dart';
import '../services/game_service.dart';
import '../models/quest.dart';
import 'quest_detail_screen.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({Key? key}) : super(key: key);

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  @override
  Widget build(BuildContext context) {
    final questService = Provider.of<QuestService>(context);
    final gameService = Provider.of<GameService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 퀘스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              questService.refreshDailyQuests();
            },
          ),
        ],
      ),
      body: questService.getAvailableQuests().isEmpty
          ? _buildEmptyState()
          : _buildQuestList(context, questService, gameService),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '현재 사용 가능한 퀘스트가 없습니다.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestList(BuildContext context, QuestService questService, GameService gameService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: questService.getAvailableQuests().length,
      itemBuilder: (context, index) {
        final quest = questService.getAvailableQuests()[index];
        return _buildQuestCard(context, quest, questService, gameService);
      },
    );
  }
  
  Widget _buildQuestCard(BuildContext context, Quest quest, QuestService questService, GameService gameService) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color difficultyColor;
    
    switch (quest.difficulty) {
      case '상':
        difficultyColor = Colors.red[400]!;
        break;
      case '중':
        difficultyColor = Colors.amber[400]!;
        break;
      default:
        difficultyColor = Colors.green[400]!;
    }
    
    // 서비스에서 현재 진행 중인 퀘스트 ID 가져오기
    String? activeQuestId = questService.currentProgress?.questId;
    
    // 현재 퀘스트 진행 상태 확인
    bool isAnotherQuestInProgress = activeQuestId != null && 
                                    activeQuestId != quest.id.toString() &&
                                    !quest.isCompleted;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: isDarkMode 
            ? const Color(0xFF2C2C2C)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 난이도 태그
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: difficultyColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: difficultyColor,
                  width: 1,
                ),
              ),
              child: Text(
                quest.difficulty,
                style: TextStyle(
                  color: difficultyColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 및 상단 부분
                Padding(
                  padding: const EdgeInsets.only(right: 42.0), // 난이도 태그 공간 확보
                  child: Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quest.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${quest.rewardPoints} 경험치',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.amber[400] : Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 하단 버튼 부분 - 완료 체크마크와 시작 버튼을 좌/우 정렬하여 배치
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 왼쪽: 완료 상태 표시
                    quest.isCompleted 
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '완료됨',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                    
                    // 오른쪽: 시작 버튼 또는 비활성화된 버튼
                    isAnotherQuestInProgress 
                      ? TextButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_outline, size: 16),
                          label: const Text(
                            '다른 퀘스트 진행 중',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                        )
                      : activeQuestId == quest.id.toString()
                        ? ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context, 
                                '/quest_detail',
                                arguments: quest,
                              );
                            },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text(
                              '계속하기',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: quest.isCompleted 
                              ? null
                              : () {
                                  questService.startQuest(quest);
                                  Navigator.pushNamed(
                                    context, 
                                    '/quest_detail',
                                    arguments: quest,
                                  );
                                },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text(
                              '시작하기',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: quest.isCompleted 
                                ? Colors.grey 
                                : Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 