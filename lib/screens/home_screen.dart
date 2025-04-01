import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';
import '../services/theme_service.dart';
import '../screens/emotion_detail_screen.dart';
import '../screens/custom_emotion_screen.dart';
import '../screens/tag_management_screen.dart';
import '../screens/quest_screen.dart';
import '../services/quest_service.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _detailsController = TextEditingController();
  bool _isSaving = false;
  bool _isFirebaseInitialized = false;
  String _selectedEmotion = '';
  String _selectedEmotionEmoji = '';
  Set<String> _selectedTags = {};
  late TabController _tabController;
  int _currentIndex = 0;
  
  // 정의된 감정 목록
  final List<Map<String, String>> emotions = [
    {'emotion': '행복', 'emoji': '😊'},
    {'emotion': '기쁨', 'emoji': '😄'},
    {'emotion': '사랑', 'emoji': '🥰'},
    {'emotion': '화남', 'emoji': '😡'},
    {'emotion': '슬픔', 'emoji': '😢'},
    {'emotion': '불안', 'emoji': '😰'},
    {'emotion': '무기력', 'emoji': '😴'},
    {'emotion': '지루함', 'emoji': '🙄'},
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _checkFirebaseStatus();
  }
  
  @override
  void dispose() {
    _detailsController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Firebase 상태 확인
  void _checkFirebaseStatus() {
    try {
      // FirebaseService 상태 확인
      final auth = FirebaseService.auth;
      setState(() {
        _isFirebaseInitialized = true;
      });
    } catch (e) {
      print('Firebase 상태 확인 오류: $e');
      setState(() {
        _isFirebaseInitialized = false;
      });
    }
  }

  // 사용자 정의 감정 화면으로 이동
  void _navigateToCustomEmotionScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomEmotionScreen()),
    );
  }
  
  // 태그 관리 화면으로 이동
  void _navigateToTagManagementScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TagManagementScreen()),
    );
  }
  
  // 디지털 웰빙 화면으로 이동
  void _navigateToWellbeingScreen(BuildContext context) {
    Navigator.pushNamed(context, '/wellbeing');
  }

  // 감정 버튼 클릭 시 감정 기록 화면으로 이동
  void _showEmotionDetailDialog(String emotion, String emoji) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmotionDetailScreen(
          emotion: emotion,
          emoji: emoji,
        ),
      ),
    );
  }

  // 감정 선택 시 퀘스트 화면으로 이동
  void _onEmotionQuestSelected(String emotion, String emoji) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestScreen(
          emotion: emotion,
          emoji: emoji,
        ),
      ),
    );
  }

  // 감정 버튼 생성 (감정 기록용)
  Widget _buildEmotionRecordButton(String emotion, String emoji, bool isCustom) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () => _showEmotionDetailDialog(emotion, emoji),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              emotion,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isCustom)
              const Icon(Icons.star, size: 14, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  // 퀘스트 감정 버튼 생성
  Widget _buildQuestEmotionButton(String emotion, String emoji) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () => _onEmotionQuestSelected(emotion, emoji),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              emotion,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const Icon(Icons.fitness_center, size: 14),
          ],
        ),
      ),
    );
  }

  // 감정 그리드 생성 (감정 기록용)
  Widget _buildEmotionRecordGrid() {
    final emotionService = Provider.of<EmotionService>(context);
    final customEmotions = emotionService.customEmotions;
    final allEmotions = [
      ...emotionService.defaultEmotions.map((e) => {'emotion': e['emotion'], 'emoji': e['emoji']}),
      ...customEmotions.map((e) => {'emotion': e['emotion'], 'emoji': e['emoji']}),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
      ),
      itemCount: allEmotions.length,
      itemBuilder: (context, index) {
        final emotion = allEmotions[index];
        final isCustom = index >= emotionService.defaultEmotions.length;
        
        return _buildEmotionRecordButton(
          emotion['emotion']!,
          emotion['emoji']!,
          isCustom,
        );
      },
    );
  }

  // 퀘스트 감정 그리드 생성
  Widget _buildQuestEmotionGrid() {
    final questService = Provider.of<QuestService>(context);
    final emotions = questService.availableEmotions;

    // 감정별 이모지 매핑
    final emojiMap = {
      '감사': '🙏',
      '기쁨': '😊',
      '무기력': '😔',
      '불안': '😰',
      '우울': '😢',
      '집중': '🎯',
      '짜증': '😤',
      '평온': '😌',
    };

    if (questService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (emotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('감정 퀘스트를 불러올 수 없습니다.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await questService.loadQuests();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
      ),
      itemCount: emotions.length,
      itemBuilder: (context, index) {
        final emotion = emotions[index];
        final emoji = emojiMap[emotion] ?? '❓';
        return _buildQuestEmotionButton(emotion, emoji);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final emotionService = Provider.of<EmotionService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isLoggedIn = false;
    
    try {
      // 로그인 상태 검증 강화: 초기화 확인 + 현재 사용자 확인 + 사용자 이메일 확인
      final currentUser = FirebaseService.currentUser;
      isLoggedIn = _isFirebaseInitialized && 
                   currentUser != null && 
                   currentUser.email != null && 
                   currentUser.email!.isNotEmpty;
    } catch (e) {
      print('로그인 상태 확인 오류: $e');
      isLoggedIn = false;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '감정 퀘스트',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // 메뉴 버튼
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'theme') {
                _toggleTheme(context);
              } else if (value == 'logout') {
                _showLogoutConfirmDialog(context);
              } else if (value == 'custom_emotions') {
                _navigateToCustomEmotionScreen(context);
              } else if (value == 'tag_management') {
                _navigateToTagManagementScreen(context);
              } else if (value == 'digital_wellbeing') {
                _navigateToWellbeingScreen(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6),
                    SizedBox(width: 8),
                    Text('테마 변경'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'custom_emotions',
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions),
                    SizedBox(width: 8),
                    Text('감정 관리'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'tag_management',
                child: Row(
                  children: [
                    Icon(Icons.tag),
                    SizedBox(width: 8),
                    Text('태그 관리'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'digital_wellbeing',
                child: Row(
                  children: [
                    Icon(Icons.phone_android),
                    SizedBox(width: 8),
                    Text('디지털 웰빙'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('로그아웃'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.fitness_center),
              text: '감정 퀘스트',
            ),
            Tab(
              icon: Icon(Icons.edit_note),
              text: '감정 기록',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: '프로필',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 감정 퀘스트 탭
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '감정에 맞는 퀘스트를 선택해보세요',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildQuestEmotionGrid(),
              ),
              const SizedBox(height: 16),
            ],
          ),
          
          // 감정 기록 탭
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오늘의 감정을 기록해보세요',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildEmotionRecordGrid(),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomEmotionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('나만의 감정 만들기'),
              ),
              const SizedBox(height: 16),
            ],
          ),

          // 프로필 탭
          const ProfileScreen(),
        ],
      ),
    );
  }

  void _toggleTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    themeService.toggleTheme();
  }

  void _saveEmotionRecord(String emotion, String emoji) async {
    if (emotion.isEmpty) {
      _showMessage('감정을 선택해주세요.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 현재 시간 및 타임스탬프 생성
      final now = DateTime.now();
      
      // 감정 기록 생성
      final record = EmotionRecord(
        emotion: emotion,
        emoji: emoji,
        details: _detailsController.text.trim(), // 비어있어도 저장 허용
        timestamp: now,
        tags: List.from(_selectedTags),
      ).toJson();
      
      // 서비스를 통해 저장
      final result = await FirebaseService.saveEmotionRecord(record);
      
      if (result['success'] == true) {
        // 입력 필드 초기화
        _detailsController.clear();
        setState(() {
          _selectedEmotion = '';
          _selectedEmotionEmoji = '';
          _selectedTags = {};
        });
        
        // 성공 메시지 표시
        _showMessage('감정이 기록되었습니다.');
        
        // EmotionService 새로고침
        Provider.of<EmotionService>(context, listen: false).refreshEmotionRecords();
      } else {
        _showMessage('감정 기록 중 오류가 발생했습니다.', isError: true);
      }
    } catch (e) {
      print('감정 기록 오류: $e');
      _showMessage('감정 기록 중 오류가 발생했습니다: $e', isError: true);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 로그아웃 확인 다이얼로그
  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await FirebaseService.signOut();
                if (mounted) {
                  // 로그인 상태를 강제로 갱신
                  setState(() {
                    // 로그아웃 후 상태 갱신
                  });
                  // 로그인 화면으로 이동
                  Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('로그아웃 오류: $e')),
                );
              }
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

// 메뉴 버튼 위젯
class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 