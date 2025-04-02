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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
          // 프로필 아이콘 대신 캐릭터 이미지 사용
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/rock_character.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('이미지 로드 오류: $error');
                  return Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  );
                },
              ),
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
                          await FirebaseService.signOutAndResetData(context);
                          if (mounted) {
                            Navigator.of(context).pushReplacementNamed('/auth');
                          }
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
                          Navigator.of(context).pushReplacementNamed('/auth');
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
          const Divider(height: 1), // 항목 구분선
          _buildShortcutItem(
            context,
            icon: Icons.settings,
            title: '설정',
            subtitle: '앱 설정 및 개인정보 관리',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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

// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emotionRemindersEnabled = true;
  String _selectedLanguage = '한국어';
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 앱 설정 섹션
          _buildSectionHeader(context, '앱 설정'),
          
          // 알림 설정
          SwitchListTile(
            title: const Text('알림'),
            subtitle: const Text('앱 알림 활성화'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          
          // 감정 기록 리마인더
          SwitchListTile(
            title: const Text('감정 기록 리마인더'),
            subtitle: const Text('하루에 한 번 감정 기록 알림'),
            value: _emotionRemindersEnabled,
            onChanged: _notificationsEnabled 
                ? (value) {
                    setState(() {
                      _emotionRemindersEnabled = value;
                    });
                  }
                : null,
            secondary: const Icon(Icons.alarm),
          ),
          
          const Divider(),
          
          // 테마 설정
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('테마 설정'),
            subtitle: Text(themeService.isDarkMode ? '다크 모드' : '라이트 모드'),
            trailing: Switch(
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
              },
            ),
          ),
          
          // 언어 설정
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('언어 설정'),
            subtitle: Text(_selectedLanguage),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          
          const Divider(),
          
          // 계정 섹션
          _buildSectionHeader(context, '계정'),
          
          // 프로필 정보 수정
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('프로필 정보 수정'),
            subtitle: const Text('이름, 이메일, 비밀번호 변경'),
            onTap: () {
              // 프로필 정보 수정 화면으로 이동
            },
          ),
          
          // 개인정보 설정
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('개인정보 설정'),
            subtitle: const Text('데이터 공유 설정 및 보안'),
            onTap: () {
              // 개인정보 설정 화면으로 이동
            },
          ),
          
          // 데이터 관리
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('데이터 관리'),
            subtitle: const Text('감정 기록 데이터 내보내기 및 삭제'),
            onTap: () {
              // 데이터 관리 화면으로 이동
            },
          ),
          
          const Divider(),
          
          // 앱 정보 섹션
          _buildSectionHeader(context, '앱 정보'),
          
          // 앱 버전
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 버전'),
            subtitle: const Text('1.0.0'),
          ),
          
          // 이용 약관
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('이용 약관'),
            onTap: () {
              // 이용 약관 화면으로 이동
            },
          ),
          
          // 개인정보 처리방침
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보 처리방침'),
            onTap: () {
              // 개인정보 처리방침 화면으로 이동
            },
          ),
          
          // 오픈소스 라이선스
          ListTile(
            leading: const Icon(Icons.source),
            title: const Text('오픈소스 라이선스'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: '감정 퀘스트',
                applicationVersion: '1.0.0',
              );
            },
          ),
          
          const Divider(),
          
          // 로그아웃
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await FirebaseService.signOutAndResetData(context);
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                }
              }
            },
          ),
          
          // 계정 삭제
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
            onTap: () {
              // 계정 삭제 확인 다이얼로그 표시
              _showDeleteAccountDialog(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
  
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('언어 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(context, '한국어'),
              _buildLanguageOption(context, 'English'),
              _buildLanguageOption(context, '日本語'),
              _buildLanguageOption(context, '中文'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildLanguageOption(BuildContext context, String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language 
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }
  
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text(
            '계정을 삭제하면 모든 감정 기록과 퀘스트 정보가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // TODO: 계정 삭제 로직 구현
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('계정 삭제'),
            ),
          ],
        );
      },
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