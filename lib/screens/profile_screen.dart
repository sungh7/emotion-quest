import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/achievement.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        if (gameService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final stats = gameService.userStats;
        if (stats == null) {
          return const Center(child: Text('통계를 불러올 수 없습니다.'));
        }
        
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('프로필'),
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
                _buildAchievementsTab(context, gameService),
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
                    value: stats.levelProgress,
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
          
          // 포인트 및 기록 통계
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '포인트',
                  '${stats.points} P',
                  Icons.stars,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  '연속 기록',
                  '${stats.recordStreak}일',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '총 기록',
                  '${stats.totalRecords}개',
                  Icons.note_alt,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  '업적',
                  '${stats.achievements.length}개',
                  Icons.emoji_events,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
  
  Widget _buildAchievementsTab(BuildContext context, GameService gameService) {
    final unlockedAchievements = gameService.unlockedAchievements;
    final lockedAchievements = Achievements.all
        .where((a) => !unlockedAchievements.contains(a))
        .where((a) => !a.isSecret)  // 숨겨진 업적은 표시하지 않음
        .toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unlockedAchievements.isNotEmpty) ...[
          const Text(
            '획득한 업적',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...unlockedAchievements.map((achievement) => 
            _buildAchievementCard(context, achievement, true)
          ),
          const SizedBox(height: 24),
        ],
        
        if (lockedAchievements.isNotEmpty) ...[
          const Text(
            '도전 가능한 업적',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...lockedAchievements.map((achievement) =>
            _buildAchievementCard(context, achievement, false)
          ),
        ],
      ],
    );
  }
  
  Widget _buildAchievementCard(BuildContext context, Achievement achievement, bool unlocked) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Text(
          achievement.icon,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            color: unlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: TextStyle(
                color: unlocked ? null : Colors.grey,
              ),
            ),
            if (unlocked)
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('+${achievement.expReward} EXP'),
                    backgroundColor: Colors.green[100],
                    labelStyle: const TextStyle(color: Colors.green),
                  ),
                  Chip(
                    label: Text('+${achievement.pointReward} P'),
                    backgroundColor: Colors.amber[100],
                    labelStyle: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
          ],
        ),
        trailing: unlocked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock_outline, color: Colors.grey),
      ),
    );
  }
} 