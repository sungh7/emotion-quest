import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/emotion_button.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';
import '../screens/emotion_detail_screen.dart';
import '../screens/custom_emotion_screen.dart';
import '../screens/tag_management_screen.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _detailsController = TextEditingController();
  bool _isSaving = false;
  bool _isFirebaseInitialized = false;
  
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
    _checkFirebaseStatus();
  }
  
  @override
  void dispose() {
    _detailsController.dispose();
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
  void _navigateToCustomEmotionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CustomEmotionScreen()),
    );
  }
  
  // 태그 관리 화면으로 이동
  void _navigateToTagManagementScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TagManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final emotionService = Provider.of<EmotionService>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isLoggedIn = false;
    
    try {
      isLoggedIn = _isFirebaseInitialized && FirebaseService.currentUser != null;
    } catch (e) {
      print('로그인 상태 확인 오류: $e');
      isLoggedIn = false;
    }
    
    // 모든 감정 목록 (기본 + 사용자 정의)
    final allEmotions = emotionService.allEmotions;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 퀘스트'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.toggleTheme(),
            tooltip: isDarkMode ? '라이트 모드로 전환' : '다크 모드로 전환',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/report');
            },
          ),
          if (FirebaseService.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: '로그아웃',
              onPressed: () => _showLogoutDialog(context),
            ),
        ],
      ),
      body: _isFirebaseInitialized 
        ? _isSaving 
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '지금 당신의 감정은 어떤가요?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isLoggedIn)
                          Chip(
                            avatar: const Icon(Icons.person, size: 18),
                            label: Text(
                              FirebaseService.currentUser!.email!.split('@')[0],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    if (!_isFirebaseInitialized)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          color: Colors.yellow[100],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.warning, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Firebase 초기화 오류: 로그인하여 데이터를 저장할 수 없습니다. 계정 없이도 앱을 사용할 수 있지만 데이터는 로컬에만 저장됩니다.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/auth');
                                  },
                                  child: const Text('로그인'),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.add_reaction_outlined,
                              label: '감정 추가',
                              onPressed: _navigateToCustomEmotionScreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.tag,
                              label: '태그 관리',
                              onPressed: _navigateToTagManagementScreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MenuButton(
                              icon: Icons.bar_chart,
                              label: '통계',
                              onPressed: () => Navigator.pushNamed(context, '/report'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '감정 선택',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (allEmotions.length > emotionService.defaultEmotions.length)
                            Text(
                              '총 ${allEmotions.length}개의 감정',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: allEmotions.length,
                        itemBuilder: (context, index) {
                          final emotion = allEmotions[index];
                          final isCustom = index >= emotionService.defaultEmotions.length;
                          
                          return EmotionButton(
                            emotion: emotion['emotion']!,
                            emoji: emotion['emoji']!,
                            isCustom: isCustom,
                            onPressed: () => _showEmotionDetailDialog(
                              emotion['emotion']!,
                              emotion['emoji']!,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
        : const Center(child: CircularProgressIndicator()),
    );
  }

  void _showEmotionDetailDialog(String emotion, String emoji) {
    // 다이얼로그 대신 EmotionDetailScreen으로 이동
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
  
  Future<void> _recordEmotion(String emotion, String emoji) async {
    try {
      setState(() {
        _isSaving = true;
      });
      
      if (FirebaseService.currentUser == null) {
        // 로그인 화면으로 이동
        await Navigator.pushNamed(context, '/auth');
        
        // 여전히 로그인되지 않았으면 중단
        if (FirebaseService.currentUser == null) {
          _showMessage('로그인 후 감정을 기록할 수 있습니다.', isError: true);
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }
      
      // 다이얼로그 닫기
      Navigator.of(context).pop();
      
      // 현재 시간으로 감정 기록 생성
      final record = EmotionRecord(
        emotion: emotion,
        emoji: emoji,
        timestamp: DateTime.now(),
        details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      );
      
      // 감정 기록 저장
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final success = await emotionService.saveEmotionRecord(record);
      
      if (success) {
        _showMessage('감정이 성공적으로 기록되었습니다.');
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
  void _showLogoutDialog(BuildContext context) {
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
                  Navigator.of(context).pushReplacementNamed('/auth');
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