import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/game_service.dart';
import '../models/user_stats.dart';
import '../models/achievement.dart';
import '../services/theme_service.dart';
import 'quest_history_screen.dart';
import 'emotion_stats_screen.dart';
import '../common/widgets/base_card.dart';
import '../common/widgets/stat_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Provider.of<ThemeService>(context, listen: false).isDarkMode;
  }
  
  @override
  Widget build(BuildContext context) {
    final gameService = Provider.of<GameService>(context);
    final UserStats? userStats = gameService.userStats;
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 프로필'),
        actions: [
          // 테마 변경 버튼
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: '테마 변경',
            onPressed: () {
              themeService.toggleTheme();
            },
          ),
          // 설정 버튼
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '설정',
            onPressed: () {
              // TODO: 설정 화면으로 이동
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 카드
            _buildProfileCard(context, themeService),
            
            const SizedBox(height: 24),
            
            // 통계 카드
            _buildStatsCard(context, userStats),
            
            const SizedBox(height: 24),
            
            // 바로가기 섹션
            _buildShortcuts(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileCard(BuildContext context, ThemeService themeService) {
    return BaseCard(
      child: Row(
        children: [
          // 프로필 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          
          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FirebaseService.currentUser?.displayName ?? '게스트',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  FirebaseService.currentUser?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                // 로그인/로그아웃 버튼
                FirebaseService.currentUser != null
                    ? OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('로그아웃'),
                        onPressed: () async {
                          await FirebaseService.signOut();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('로그인'),
                        onPressed: () {
                          // TODO: 로그인 화면으로 이동
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard(BuildContext context, UserStats? userStats) {
    final double progress = userStats != null && userStats.experienceForNextLevel > 0
        ? (userStats.experience / userStats.experienceForNextLevel).clamp(0.0, 1.0)
        : 0.0;
        
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // StatItem 사용
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: Icons.bar_chart,
                title: '레벨',
                value: '${userStats?.level ?? 1}',
              ),
              StatItem(
                icon: Icons.stars,
                title: '경험치',
                value: '${userStats?.experience ?? 0}/${userStats?.experienceForNextLevel ?? 100}',
              ),
              StatItem(
                icon: Icons.check_circle,
                title: '완료 퀘스트',
                value: '${userStats?.completedQuests ?? 0}',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 경험치 바
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '다음 레벨까지 ${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildShortcuts(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '바로가기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // 바로가기 항목들
          _buildShortcutItem(
            context,
            icon: Icons.show_chart,
            title: '감정 통계',
            subtitle: '나의 감정 기록 패턴 확인하기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmotionStatsScreen()),
              );
            },
          ),
          const Divider(height: 1), // 항목 구분선
          _buildShortcutItem(
            context,
            icon: Icons.history,
            title: '퀘스트 기록',
            subtitle: '완료한 퀘스트 목록 보기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QuestHistoryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildShortcutItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// 현재 GameService 코드에 없는 속성 추가
extension UserStatsExtension on UserStats {
  // 레벨 진행도
  double get levelProgress => experience / experienceForNextLevel;
  
  // 스트릭 계산 (임시)
  int get recordStreak => 1;
  
  // 포인트 (임시)
  int get points => experience * 2;
  
  // 총 기록 수
  int get totalRecords => recordCount;
} 