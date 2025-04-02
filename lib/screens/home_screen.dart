import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/emotion_service.dart';
import '../services/quest_service.dart';
import '../services/firebase_service.dart';
import '../services/game_service.dart';
import '../models/emotion_record.dart';
import 'report_screen.dart';
import 'wellbeing_screen.dart';
import 'quest_screen.dart';
import 'profile_screen.dart';
import 'auth_screen.dart';
import 'custom_emotion_screen.dart';
import 'emotion_quest_screen.dart';
import '../services/theme_service.dart';
import '../models/quest.dart' show Quest;
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _authChecked = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkAuthState();
    _loadData();
  }
  
  void _checkAuthState() {
    if (FirebaseService.currentUser == null) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen())
        );
      });
    } else {
      setState(() {
        _authChecked = true;
      });
    }
  }
  
  Future<void> _loadData() async {
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    final questService = Provider.of<QuestService>(context, listen: false);
    final gameService = Provider.of<GameService>(context, listen: false);
    
    // 사용자 인증 상태 확인
    final user = FirebaseService.currentUser;
    if (mounted) {
      setState(() {
        _isLoggedIn = user != null;
        _isLoading = true;
      });
    }
    
    if (user != null) {
      // 커스텀 감정 로드
      await emotionService.loadCustomEmotions();
      
      // 감정 기록 로드
      await emotionService.loadEmotionRecords();
      
      // 퀘스트 로드 (내부에서 loadProgress() 호출)
      await questService.loadQuests();
      
      // 게임 데이터가 로드되었는지 확인
      if (gameService.points == 0) {
        // 게임 데이터 로드 시도
        await gameService.loadGameData();
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      if (index == 0) {
        _loadData();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final emotionService = Provider.of<EmotionService>(context);
    final questService = Provider.of<QuestService>(context);
    final gameService = Provider.of<GameService>(context);
    
    final user = FirebaseService.currentUser;
    
    final emotionCount = emotionService.getTodayEmotionCount();
    
    final gamePoints = gameService.getPoints();
    
    final List<Widget> _pages = [
      _buildHomeContent(
        context, 
        emotionCount: emotionCount,
        gamePoints: gamePoints
      ),
      const ReportScreen(),
      const QuestScreen(),
      const WellbeingScreen(),
      const ProfileScreen(),
    ];
    
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '리포트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: '퀘스트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smartphone),
            label: '웰빙',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
  
  Widget _buildHomeContent(
    BuildContext context, {
    required int emotionCount,
    required int gamePoints,
  }) {
    final emotionService = Provider.of<EmotionService>(context);
    final questService = Provider.of<QuestService>(context);
    
    return Consumer<EmotionService>(
      builder: (context, emotionService, _) {
        return Consumer<QuestService>(
          builder: (context, questService, _) {
            if (!_authChecked) {
              return Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: const Text('감정 퀘스트'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        // 알림 화면으로 이동
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '안녕하세요! 오늘 어떤 감정을 느끼세요?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '오늘의 요약',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        context,
                                        icon: Icons.emoji_emotions,
                                        title: '감정 기록',
                                        value: '$emotionCount회',
                                        color: Colors.blue,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        context,
                                        icon: Icons.star,
                                        title: '게임 포인트',
                                        value: gamePoints.toString(),
                                        color: Colors.yellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        _buildEmotionButtons(context, emotionService),
                        
                        const SizedBox(height: 24),
                        
                        const Text(
                          '감정 추세',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildEmotionStatsSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildSummaryItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmotionButtons(BuildContext context, EmotionService emotionService) {
    final List<Map<String, dynamic>> allEmotions = [
      ...emotionService.baseEmotions,
      ...emotionService.customEmotions,
    ];
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: allEmotions.length + 1,
      itemBuilder: (context, index) {
        if (index == allEmotions.length) {
          return _buildAddEmotionButton(context);
        } else {
          final emotionData = allEmotions[index];
          final isCustom = index >= emotionService.baseEmotions.length;
          
          return _buildEmotionButton(
            context,
            emotion: emotionData['emotion'],
            emoji: emotionData['emoji'],
            color: emotionData['color'] ?? Colors.grey,
            isCustom: isCustom,
            onTap: () {
              _recordEmotion(emotionData);
            },
          );
        }
      },
    );
  }
  
  Widget _buildEmotionButton(
    BuildContext context,
    {
      required String emotion,
      required String emoji,
      required Color color,
      bool isCustom = false,
      required VoidCallback onTap,
    }
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              emotion,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddEmotionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomEmotionScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32),
            SizedBox(height: 8),
            Text(
              '감정 추가',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordEmotion(Map<String, dynamic> emotionData) async {
    final emotion = emotionData['emotion'];
    final emoji = emotionData['emoji'];
    final isCustom = emotionData['isCustom'] ?? false;

    final recordDetails = await _showRecordDetailDialog(
      context,
      emotion: emotion,
      emoji: emoji,
    );

    if (recordDetails != null) {
      final record = EmotionRecord(
        emotion: emotion,
        emoji: emoji,
        timestamp: DateTime.now(),
        details: recordDetails['notes'],
        tags: recordDetails['tags'],
        isCustomEmotion: isCustom,
        imageUrl: recordDetails['imageUrl'],
        videoUrl: recordDetails['videoUrl'],
        audioUrl: recordDetails['audioUrl'],
        diaryContent: recordDetails['diaryContent'],
      );

      try {
        final emotionService = Provider.of<EmotionService>(context, listen: false);
        final recordId = await emotionService.saveEmotionRecord(record);

        if (recordId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$emotion 감정이 기록되었습니다.')),
          );
          
          final gameService = Provider.of<GameService>(context, listen: false);
          await gameService.processRewardForRecord(record.copyWith(id: recordId));

          _showQuestSuggestionDialog(context, emotion);
          
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('감정 기록 저장 실패'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        print('감정 기록 처리 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showRecordDetailDialog(
    BuildContext context, {
    required String emotion,
    required String emoji,
  }) async {
    String notes = '';
    String diaryContent = '';
    List<String> tags = [];
    XFile? imageFile;
    XFile? videoFile;

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final ImagePicker picker = ImagePicker();

    final availableTags = await Provider.of<EmotionService>(context, listen: false).getAllTags();

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$emoji $emotion 감정 기록'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '메모 (선택)',
                          hintText: '상황, 생각 등을 간단히 기록하세요.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          notes = value;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: '감정 일기 (선택)',
                          hintText: '오늘의 감정에 대해 자세히 써보세요.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                        onChanged: (value) {
                          diaryContent = value;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text('태그 (선택)'),
                      Wrap(
                        spacing: 8.0,
                        children: availableTags.map((tag) {
                          final isSelected = tags.contains(tag);
                          return ChoiceChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  tags.add(tag);
                                } else {
                                  tags.remove(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.image),
                                onPressed: () async {
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      imageFile = pickedFile;
                                    });
                                  }
                                },
                              ),
                              const Text('이미지', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.videocam),
                                onPressed: () async {
                                  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setState(() {
                                      videoFile = pickedFile;
                                    });
                                  }
                                },
                              ),
                              const Text('비디오', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: () {
                                  // 음성 녹음 기능 구현
                                },
                              ),
                              const Text('음성 메모', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      if (imageFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: kIsWeb 
                            ? FutureBuilder<Uint8List>(
                                future: imageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                    return Column(
                                      children: [
                                        Image.memory(
                                          snapshot.data!,
                                          height: 100,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('웹 이미지 미리보기 오류: $error');
                                            return Column(
                                              children: [
                                                Icon(Icons.image, size: 40, color: Colors.grey),
                                                Text('이미지 미리보기를 표시할 수 없습니다.'),
                                                Text('선택된 파일: ${imageFile!.name}', style: TextStyle(fontSize: 12))
                                              ],
                                            );
                                          },
                                        ),
                                        Text('선택된 이미지: ${imageFile!.name}', style: TextStyle(fontSize: 12)),
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Column(
                                      children: [
                                        Icon(Icons.image, size: 40, color: Colors.grey),
                                        Text('이미지 로드 오류: ${snapshot.error}'),
                                        Text('선택된 파일: ${imageFile!.name}', style: TextStyle(fontSize: 12))
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text('이미지 로드 중...'),
                                        Text('선택된 파일: ${imageFile!.name}', style: TextStyle(fontSize: 12))
                                      ],
                                    );
                                  }
                                },
                              )
                            : Image.file(
                                File(imageFile!.path), 
                                height: 100, 
                                errorBuilder: (context, error, stackTrace) {
                                  print('이미지 로드 오류: $error');
                                  return Column(
                                    children: [
                                      Icon(Icons.image, size: 40, color: Colors.grey),
                                      Text('이미지 미리보기를 표시할 수 없습니다.'),
                                      Text('선택된 파일: ${imageFile!.name}', style: TextStyle(fontSize: 12))
                                    ],
                                  );
                                },
                              ),
                        ),
                      if (videoFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text('선택된 비디오: ${videoFile!.name}'),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String? imageUrl;
                    String? videoUrl;
                    
                    final userId = FirebaseService.currentUser?.uid;
                    if (userId != null) {
                      if (imageFile != null) {
                        final imagePath = 'emotion_records/$userId/images/${DateTime.now().millisecondsSinceEpoch}_${imageFile!.name}';
                        
                        if (kIsWeb) {
                          // 웹 환경에서는 XFile에서 바이트 데이터를 읽어 업로드
                          final bytes = await imageFile!.readAsBytes();
                          imageUrl = await FirebaseService.uploadFileBytes(imagePath, bytes);
                        } else {
                          // 모바일 환경에서는 기존 방식대로 File 객체 사용
                          imageUrl = await FirebaseService.uploadFile(imagePath, File(imageFile!.path));
                        }
                      }
                      if (videoFile != null) {
                        final videoPath = 'emotion_records/$userId/videos/${DateTime.now().millisecondsSinceEpoch}_${videoFile!.name}';
                        
                        if (kIsWeb) {
                          // 웹 환경에서는 XFile에서 바이트 데이터를 읽어 업로드
                          final bytes = await videoFile!.readAsBytes();
                          videoUrl = await FirebaseService.uploadFileBytes(videoPath, bytes);
                        } else {
                          // 모바일 환경에서는 기존 방식대로 File 객체 사용
                          videoUrl = await FirebaseService.uploadFile(videoPath, File(videoFile!.path));
                        }
                      }
                    }
                    
                    Navigator.pop(context, {
                      'notes': notes,
                      'tags': tags,
                      'diaryContent': diaryContent,
                      'imageUrl': imageUrl,
                      'videoUrl': videoUrl,
                      'audioUrl': null,
                    });
                  },
                  child: const Text('기록하기'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showQuestSuggestionDialog(BuildContext context, String emotion) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$emotion 관련 퀘스트'),
          content: Text('이 감정과 관련된 퀘스트를 수행하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmotionQuestScreen(
                      selectedEmotion: emotion,
                    ),
                  ),
                );
              },
              child: const Text('퀘스트 보기'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildEmotionStatsSection(BuildContext context) {
    final emotionService = Provider.of<EmotionService>(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '감정 추세',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings, size: 20),
                      onPressed: () {
                        _showEmotionScoreSettings(context, emotionService);
                      },
                      tooltip: '감정 점수 설정',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/report');
                      },
                      child: Text(
                        '자세히 보기',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<Map<String, double>>(
              future: _calculateDayScores(emotionService),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      height: 150,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                  );
                }
                
                final dayScores = snapshot.data ?? {
                  '월': 0.5, '화': 0.5, '수': 0.5, '목': 0.5, '금': 0.5, '토': 0.5, '일': 0.5
                };
                
                return _buildSimpleChart(context, dayScores);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSimpleChart(BuildContext context, Map<String, double> dayScores) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    return Column(
      children: [
        const Text('요일별 감정 점수', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDayColumn(context, '월', dayScores['월'] ?? 0.5),
            _buildDayColumn(context, '화', dayScores['화'] ?? 0.5),
            _buildDayColumn(context, '수', dayScores['수'] ?? 0.5),
            _buildDayColumn(context, '목', dayScores['목'] ?? 0.5),
            _buildDayColumn(context, '금', dayScores['금'] ?? 0.5),
            _buildDayColumn(context, '토', dayScores['토'] ?? 0.5),
            _buildDayColumn(context, '일', dayScores['일'] ?? 0.5),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text('부정', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text('중립', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            const Text('긍정', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDayColumn(BuildContext context, String day, double score) {
    Color color;
    if (score > 0.65) {
      color = Colors.green;
    } else if (score > 0.35) {
      color = Colors.amber;
    } else {
      color = Colors.red;
    }
    
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 16,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 16,
                height: 120 * score,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(score * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Future<Map<String, double>> _calculateDayScores(EmotionService emotionService) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final records = await emotionService.getEmotionRecords(
      startDate: thirtyDaysAgo,
      endDate: now,
    );
    
    if (records.isEmpty) {
      return {
        '월': 0.5, '화': 0.5, '수': 0.5, '목': 0.5, '금': 0.5, '토': 0.5, '일': 0.5
      };
    }
    
    final dayGroups = <String, List<EmotionRecord>>{
      '월': [], '화': [], '수': [], '목': [], '금': [], '토': [], '일': []
    };
    
    final days = ['월', '화', '수', '목', '금', '토', '일'];
    for (var record in records) {
      final weekday = record.timestamp.weekday;
      final day = days[weekday - 1];
      dayGroups[day]?.add(record);
    }
    
    final dayScores = <String, double>{};
    dayGroups.forEach((day, dayRecords) {
      if (dayRecords.isEmpty) {
        dayScores[day] = 0.5;
      } else {
        double totalScore = 0;
        for (var record in dayRecords) {
          totalScore += emotionService.getEmotionScore(record.emotion);
        }
        dayScores[day] = totalScore / dayRecords.length;
      }
    });
    
    return dayScores;
  }
  
  void _showEmotionScoreSettings(BuildContext context, EmotionService emotionService) {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, double> tempScores = Map.from(emotionService.emotionScores);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('감정 점수 설정'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      '각 감정이 당신의 기분에 미치는 영향을 설정하세요. 0은 매우 부정적, 1은 매우 긍정적입니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ...emotionService.allEmotions.map((emotion) {
                      final name = emotion['emotion'] as String;
                      final emoji = emotion['emoji'] as String;
                      final color = emotion['color'] as Color;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name),
                                  Slider(
                                    value: tempScores[name] ?? 0.5,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 10,
                                    label: ((tempScores[name] ?? 0.5) * 10).round().toString(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        tempScores[name] = newValue;
                                      });
                                    },
                                    activeColor: color,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('부정', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('중립', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('긍정', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () async {
                    await emotionService.resetEmotionScores();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('감정 점수가 기본값으로 초기화되었습니다.')),
                    );
                  },
                  child: const Text('기본값으로 초기화'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await emotionService.setEmotionScores(tempScores);
                    Navigator.pop(context);
                    if (result) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('감정 점수가 저장되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('감정 점수 저장 중 오류가 발생했습니다.')),
                      );
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 