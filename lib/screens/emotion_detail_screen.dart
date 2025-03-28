import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';
import '../screens/tag_management_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmotionDetailScreen extends StatefulWidget {
  final String emotion;
  final String emoji;

  const EmotionDetailScreen({
    Key? key,
    required this.emotion,
    required this.emoji,
  }) : super(key: key);

  @override
  State<EmotionDetailScreen> createState() => _EmotionDetailScreenState();
}

class _EmotionDetailScreenState extends State<EmotionDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  
  final FocusNode _detailsFocusNode = FocusNode();
  final FocusNode _diaryFocusNode = FocusNode();
  
  File? _imageFile;
  File? _videoFile;
  File? _audioFile;
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isRecording = false;
  List<Map<String, dynamic>> _availableTags = [];
  List<String> _selectedTags = [];
  
  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
  }
  
  @override
  void dispose() {
    _detailsController.dispose();
    _diaryController.dispose();
    _detailsFocusNode.dispose();
    _diaryFocusNode.dispose();
    super.dispose();
  }
  
  // 사용 가능한 태그 로드
  Future<void> _loadAvailableTags() async {
    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final tags = await emotionService.getAllTags();
      
      if (mounted) {
        setState(() {
          _availableTags = tags.map((tag) => {'name': tag}).toList();
        });
        print('감정 세부 화면에 로드된 태그: $_availableTags');
      }
    } catch (e) {
      print('태그 로드 오류: $e');
      
      // 에러 발생 시 빈 리스트라도 표시
      if (mounted) {
        setState(() {
          _availableTags = [];
        });
      }
    }
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 비디오 선택
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  // 오디오 녹음 시작 (현재 미구현)
  Future<void> _startRecording() async {
    // 녹음 기능 임시 비활성화
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('녹음 기능이 현재 비활성화되어 있습니다.'))
    );
  }

  // 오디오 녹음 중지 (현재 미구현)
  Future<void> _stopRecording() async {
    // 녹음 기능 임시 비활성화
    setState(() {
      _isRecording = false;
    });
  }

  // 상세 정보 없이 감정 저장
  Future<void> _saveWithoutDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      EmotionRecord record = EmotionRecord(
        emotion: widget.emotion,
        emoji: widget.emoji,
        timestamp: DateTime.now(),
        tags: _selectedTags.toList(),
      );

      await Provider.of<EmotionService>(context, listen: false).saveEmotionRecord(record);

      if (mounted) {
        Navigator.pop(context, true); // 저장 성공 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감정 기록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 상세 정보와 함께 감정 저장
  Future<void> _saveWithDetails() async {
    // 더 이상 감정 설명이 필수가 아님
    // 감정 일기 또는 태그가 있는 경우에도 저장 가능
    // 모든 필드가 비어있는 경우에만 경고 메시지 표시
    if (_detailsController.text.isEmpty && 
        _diaryController.text.isEmpty && 
        _selectedTags.isEmpty && 
        _imageFile == null && 
        _videoFile == null && 
        _audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정 설명, 일기, 태그 중 하나 이상 입력해주세요')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 미디어 파일 업로드 (구현 필요)
      String? imageUrl;
      String? videoUrl;
      String? audioUrl;

      EmotionRecord record = EmotionRecord(
        emotion: widget.emotion,
        emoji: widget.emoji,
        timestamp: DateTime.now(),
        details: _detailsController.text.isEmpty ? null : _detailsController.text.trim(),
        tags: _selectedTags.toList(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        diaryContent: _diaryController.text.isEmpty ? null : _diaryController.text.trim(),
      );

      await Provider.of<EmotionService>(context, listen: false).saveEmotionRecord(record);

      if (mounted) {
        Navigator.pop(context, true); // 저장 성공 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감정 기록 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 태그 관리 화면으로 이동
  Future<void> _navigateToTagManagement() async {
    print('태그 관리 화면으로 이동');
    // 키보드 포커스 해제
    FocusScope.of(context).unfocus();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TagManagementScreen()),
    );
    
    if (result == true) {
      print('태그 관리 화면에서 돌아옴, 태그 다시 로드');
      // 태그 관리 화면에서 돌아왔을 때 태그 목록 다시 로드
      _loadAvailableTags();
    }
  }

  // 태그 선택 UI 위젯
  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              const Text(
                '태그',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _navigateToTagManagement,
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('태그 관리'),
              ),
            ],
          ),
        ),
        _availableTags.isEmpty
          ? Center(
              child: Column(
                children: [
                  Text(
                    '사용 가능한 태그가 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _navigateToTagManagement,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('태그 추가하기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            )
          : Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag['name']);
                return FilterChip(
                  selected: isSelected,
                  label: Text(tag['name']),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag['name']);
                      } else {
                        _selectedTags.remove(tag['name']);
                      }
                    });
                    print('선택된 태그: $_selectedTags');
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('감정 확인', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 감정 이미지 표시 영역
                  Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 100),
                      )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true), 
                      )
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '감정 기록: ${widget.emotion}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 태그 선택 UI 추가
                        _buildTagSelector(),
                        
                        // 감정 설명 입력
                        const SizedBox(height: 16),
                        const Text('감정 설명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          focusNode: _detailsFocusNode,
                          decoration: const InputDecoration(
                            hintText: '지금 느끼는 감정에 대해 자세히 설명해보세요.',
                            border: OutlineInputBorder(),
                            helperText: 'Enter: 다음 필드로 이동, Shift+Enter: 줄바꿈',
                          ),
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            // 수정키(Shift 등)가 눌려있지 않은 경우에만 다음 필드로 이동
                            FocusScope.of(context).requestFocus(_diaryFocusNode);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // 미디어 첨부 옵션
                        const Text('미디어 첨부', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 이미지 선택 버튼
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.photo),
                                  onPressed: _pickImage,
                                  color: _imageFile != null ? Theme.of(context).primaryColor : Colors.grey,
                                  iconSize: 32,
                                ),
                                const Text('사진'),
                              ],
                            ),
                            
                            // 비디오 선택 버튼
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.videocam),
                                  onPressed: _pickVideo,
                                  color: _videoFile != null ? Theme.of(context).primaryColor : Colors.grey,
                                  iconSize: 32,
                                ),
                                const Text('동영상'),
                              ],
                            ),
                            
                            // 오디오 녹음 버튼
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                                  onPressed: _isRecording ? _stopRecording : _startRecording,
                                  color: _isRecording || _audioFile != null ? Colors.red : Colors.grey,
                                  iconSize: 32,
                                ),
                                const Text('음성'),
                              ],
                            ),
                          ],
                        ),
                        
                        // 선택된 미디어 미리보기
                        if (_imageFile != null || _videoFile != null || _audioFile != null) ...[
                          const SizedBox(height: 16),
                          const Text('첨부된 미디어', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            height: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                if (_imageFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Image.file(_imageFile!, height: 84, width: 84, fit: BoxFit.cover),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() => _imageFile = null),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_videoFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 84,
                                          width: 84,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.videocam, size: 40),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() => _videoFile = null),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_audioFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 84,
                                          width: 84,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.mic, size: 40),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() => _audioFile = null),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        
                        // 감정 일기 작성
                        const SizedBox(height: 16),
                        const Text('감정 일기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _diaryController,
                          focusNode: _diaryFocusNode,
                          decoration: const InputDecoration(
                            hintText: '오늘 있었던 일과 감정에 대한 일기를 작성해보세요.',
                            border: OutlineInputBorder(),
                            // helperText: 'Shift+Enter: 줄바꿈, Ctrl+S: 저장',
                          ),
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        ),
                        
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveWithDetails,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              '감정 기록 저장',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _saveWithoutDetails,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '간단히 저장',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 