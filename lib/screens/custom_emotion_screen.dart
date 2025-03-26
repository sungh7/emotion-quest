import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emotion_service.dart';

class CustomEmotionScreen extends StatefulWidget {
  const CustomEmotionScreen({Key? key}) : super(key: key);

  @override
  State<CustomEmotionScreen> createState() => _CustomEmotionScreenState();
}

class _CustomEmotionScreenState extends State<CustomEmotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emotionController = TextEditingController();
  final _emojiController = TextEditingController();
  
  // 편집 모드인지 여부
  bool _isEditMode = false;
  String? _editingEmotion;
  
  @override
  void dispose() {
    _emotionController.dispose();
    _emojiController.dispose();
    super.dispose();
  }
  
  // 폼 초기화
  void _resetForm() {
    _emotionController.clear();
    _emojiController.clear();
    _isEditMode = false;
    _editingEmotion = null;
  }
  
  // 감정 추가
  Future<void> _addEmotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    final emotion = _emotionController.text.trim();
    final emoji = _emojiController.text.trim();
    
    // 편집 모드인 경우
    if (_isEditMode && _editingEmotion != null) {
      final success = await emotionService.updateCustomEmotion(
        _editingEmotion!,
        emotion,
        emoji,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('감정이 수정되었습니다')),
          );
        }
        _resetForm();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('감정 수정에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } 
    // 추가 모드인 경우
    else {
      final success = await emotionService.addCustomEmotion(emotion, emoji);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 감정이 추가되었습니다')),
          );
        }
        _resetForm();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 사용 중인 감정 또는 이모지입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // 감정 삭제 확인 다이얼로그
  void _showDeleteConfirmation(String emotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 삭제'),
        content: Text('감정 "$emotion"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEmotion(emotion);
            },
            child: const Text('삭제'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  
  // 감정 삭제
  Future<void> _deleteEmotion(String emotion) async {
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    final success = await emotionService.removeCustomEmotion(emotion);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감정이 삭제되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('감정 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 감정 편집 모드 설정
  void _editEmotion(Map<String, String> emotion) {
    setState(() {
      _isEditMode = true;
      _editingEmotion = emotion['emotion'];
      _emotionController.text = emotion['emotion'] ?? '';
      _emojiController.text = emotion['emoji'] ?? '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 정의 감정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 감정 추가/편집 폼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditMode ? '감정 수정' : '새 감정 추가',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 감정 이름 입력
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _emotionController,
                          decoration: const InputDecoration(
                            labelText: '감정 이름',
                            hintText: '예: 설렘, 호기심, 만족감',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '감정 이름을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 이모지 입력
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _emojiController,
                          decoration: const InputDecoration(
                            labelText: '이모지',
                            hintText: '😊',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이모지를 입력해주세요';
                            }
                            return null;
                          },
                          maxLength: 2,
                          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addEmotion,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            _isEditMode ? '수정하기' : '추가하기',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (_isEditMode) ...[
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // 감정 목록 타이틀
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  '내가 추가한 감정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<EmotionService>(
                  builder: (context, emotionService, child) {
                    final count = emotionService.customEmotions.length;
                    return Text(
                      '$count개',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // 감정 목록
          Expanded(
            child: Consumer<EmotionService>(
              builder: (context, emotionService, child) {
                final customEmotions = emotionService.customEmotions;
                
                if (customEmotions.isEmpty) {
                  return const Center(
                    child: Text(
                      '추가한 감정이 없습니다\n새로운 감정을 추가해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: customEmotions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final emotion = customEmotions[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        emotion['emoji'] ?? '',
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        emotion['emotion'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 편집 버튼
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editEmotion(emotion),
                            tooltip: '감정 편집',
                          ),
                          // 삭제 버튼
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showDeleteConfirmation(emotion['emotion'] ?? ''),
                            tooltip: '감정 삭제',
                            color: Colors.red[400],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 