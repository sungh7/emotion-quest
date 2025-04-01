import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/user_stats.dart'; 
import '../models/achievement.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        final stats = gameService.userStats;
        if (stats == null) {
          return const Center(child: Text('통계를 불러올 수 없습니다.'));
        }
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('프로필'),
              automaticallyImplyLeading: false,
              bottom: const TabBar(
                tabs: [
                  Tab(text: '통계'),
                  Tab(text: '업적'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildStatsTab(context, stats),
                _buildAchievementsTab(context),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatsTab(BuildContext context, UserStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레벨 및 경험치 표시
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lv. ${stats.level}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stats.experience / stats.nextLevelExp,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.experience} / ${stats.nextLevelExp} EXP',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 기록 통계
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '총 기록',
                  '${stats.recordCount}개',
                  Icons.note_alt,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  '최근 기록',
                  _formatDate(stats.lastRecordDate),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 경험치 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '경험치 획득 방법',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('감정 기록하기'),
                    subtitle: Text('20 EXP'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.photo),
                    title: Text('사진/비디오 첨부하기'),
                    subtitle: Text('15 EXP'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.tag),
                    title: Text('태그 추가하기'),
                    subtitle: Text('5 EXP (태그당)'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.text_fields),
                    title: Text('상세 내용 작성하기'),
                    subtitle: Text('10 EXP'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }
  
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementsTab(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              '업적 기능은 준비 중입니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '계속해서 감정을 기록하며 경험치를 쌓아보세요!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 현재 GameService 코드에 없는 속성 추가
extension UserStatsExtension on UserStats {
  // 레벨 진행도
  double get levelProgress => experience / nextLevelExp;
  
  // 스트릭 계산 (임시)
  int get recordStreak => 1;
  
  // 포인트 (임시)
  int get points => experience * 2;
  
  // 총 기록 수
  int get totalRecords => recordCount;
} 