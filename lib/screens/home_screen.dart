import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/emotion_button.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';
import '../screens/emotion_detail_screen.dart';
import '../screens/custom_emotion_screen.dart';
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
                    
                    // 사용자 정의 감정 관리 버튼
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
                          TextButton.icon(
                            onPressed: _navigateToCustomEmotionScreen,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('내 감정 추가'),
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
    _detailsController.clear();
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          title: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(emotion),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이 감정을 더 자세히 기록하시겠어요?'),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: '감정에 대한 설명 (선택)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToEmotionDetailScreen(emotion, emoji);
              },
              child: const Text('자세히 기록하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveEmotion(emotion, emoji);
              },
              child: const Text('저장', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEmotionDetailScreen(String emotion, String emoji) {
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

  Future<void> _saveEmotion(String emotion, String emoji) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final record = EmotionRecord(
        emotion: emotion,
        emoji: emoji,
        timestamp: DateTime.now(),
        details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      );

      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final success = await emotionService.saveEmotionRecord(record);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감정이 기록되었습니다')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('감정 기록에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              FirebaseService.signOut();
              Navigator.pop(context);
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
} 