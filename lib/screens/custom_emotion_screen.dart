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
  
  // 포커스 노드 추가
  final _emotionFocusNode = FocusNode();
  final _emojiFocusNode = FocusNode();
  
  List<Map<String, String>> _customEmotions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _loadCustomEmotions();
    
    // 첫 필드에 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emotionFocusNode);
    });
  }
  
  @override
  void dispose() {
    _emotionController.dispose();
    _emojiController.dispose();
    _emotionFocusNode.dispose();
    _emojiFocusNode.dispose();
    super.dispose();
  }
  
  // 사용자 정의 감정 로드
  Future<void> _loadCustomEmotions() async {
    setState(() {
      _isLoading = true;
    });
    
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    
    setState(() {
      _customEmotions = emotionService.customEmotions;
      _isLoading = false;
    });
  }
  
  // 새 감정 추가
  Future<void> _addEmotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final emotionName = _emotionController.text.trim();
    final emoji = _emojiController.text.trim();
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final success = await emotionService.addCustomEmotion(emotionName, emoji);
      
      if (success) {
        _emotionController.clear();
        _emojiController.clear();
        
        setState(() {
          _customEmotions = emotionService.customEmotions;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 감정이 추가되었습니다')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 존재하는 감정이거나 이모지입니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감정 추가 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  // 감정 삭제
  Future<void> _deleteEmotion(String emotion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('감정 삭제'),
        content: Text('정말 "$emotion" 감정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final success = await emotionService.removeCustomEmotion(emotion);
      
      setState(() {
        _customEmotions = emotionService.customEmotions;
        _isLoading = false;
      });
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감정이 삭제되었습니다')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감정 삭제 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 감정 추가 폼
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '새 감정 추가',
                        style: TextStyle(
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
                              focusNode: _emotionFocusNode,
                              decoration: const InputDecoration(
                                labelText: '감정 이름',
                                hintText: '예: 설렘, 뿌듯함, 허탈함',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '감정 이름을 입력해주세요';
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                // 이모지 필드로 포커스 이동
                                FocusScope.of(context).requestFocus(_emojiFocusNode);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // 이모지 입력
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _emojiController,
                              focusNode: _emojiFocusNode,
                              decoration: const InputDecoration(
                                labelText: '이모지',
                                hintText: '😍',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '이모지를 입력해주세요';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _addEmotion(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _addEmotion,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('감정 추가'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Divider(),
              
              // 사용자 정의 감정 목록 타이틀
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      '내 감정 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_customEmotions.length}개',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 사용자 정의 감정 목록
              Expanded(
                child: _customEmotions.isEmpty
                  ? const Center(
                      child: Text(
                        '아직 등록된 사용자 정의 감정이 없습니다\n새 감정을 추가해보세요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _customEmotions.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final emotion = _customEmotions[index];
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteEmotion(emotion['emotion'] ?? ''),
                            tooltip: '감정 삭제',
                            color: Colors.red[400],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
} 