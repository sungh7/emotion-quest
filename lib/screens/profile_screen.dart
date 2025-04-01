import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../services/game_service.dart';
import '../models/user_stats.dart';
import '../models/achievement.dart';
import '../services/theme_service.dart';
import 'quest_history_screen.dart';
import 'emotion_stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }
  
  @override
  Widget build(BuildContext context) {
    final gameService = Provider.of<GameService>(context);
    final UserStats? userStats = gameService.userStats;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 프로필'),
        actions: [
          // 테마 변경 버튼
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: '테마 변경',
            onPressed: () {
              final themeService = Provider.of<ThemeService>(context, listen: false);
              themeService.toggleTheme();
              
              setState(() {
                _isDarkMode = themeService.isDarkMode;
              });
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
            _buildProfileCard(context),
            
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
  
  Widget _buildProfileCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          icon: const Icon(Icons.logout),
                          label: const Text('로그아웃'),
                          onPressed: () async {
                            await FirebaseService.signOut();
                            if (mounted) setState(() {});
                          },
                        )
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('로그인'),
                          onPressed: () {
                            // TODO: 로그인 화면으로 이동
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(BuildContext context, UserStats? userStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            
            Row(
              children: [
                _buildStatItem(
                  context,
                  '레벨',
                  '${userStats?.level ?? 1}',
                  Icons.bar_chart,
                ),
                _buildStatItem(
                  context,
                  '경험치',
                  '${userStats?.experience ?? 0}/${userStats?.experienceForNextLevel ?? 100}',
                  Icons.stars,
                ),
                _buildStatItem(
                  context,
                  '완료한 퀘스트',
                  '${userStats?.completedQuests ?? 0}',
                  Icons.check_circle,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 경험치 바
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('다음 레벨까지'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: userStats != null
                      ? userStats.experience / userStats.experienceForNextLevel
                      : 0.0,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                if (userStats != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${userStats.experience} EXP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${userStats.experienceForNextLevel} EXP',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShortcuts(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            
            // 바로가기 메뉴
            _buildShortcutItem(
              context,
              '감정 통계',
              '내 감정 기록에 대한 통계를 확인합니다',
              Icons.insert_chart,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmotionStatsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildShortcutItem(
              context,
              '퀘스트 히스토리',
              '완료한 퀘스트 목록을 확인합니다',
              Icons.history,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuestHistoryScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildShortcutItem(
              context,
              '업적',
              '달성한 업적을 확인합니다',
              Icons.emoji_events,
              () {
                // TODO: 업적 화면으로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildShortcutItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
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