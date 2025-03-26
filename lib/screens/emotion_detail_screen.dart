import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';

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

class _EmotionDetailScreenState extends State<EmotionDetailScreen> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _diaryController = TextEditingController();
  final EmotionService _emotionService = EmotionService();
  final ImagePicker _picker = ImagePicker();
  final Record _audioRecorder = Record();
  
  bool _isLoading = false;
  bool _isRecording = false;
  String? _recordingPath;
  
  // 태그 관련 상태
  final List<String> _availableTags = ['업무', '가족', '건강', '친구', '학업', '취미', '기타'];
  final Set<String> _selectedTags = {};
  
  // 미디어 파일 상태
  File? _imageFile;
  File? _videoFile;
  File? _audioFile;

  @override
  void dispose() {
    _detailsController.dispose();
    _diaryController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 비디오 선택
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  // 오디오 녹음 시작
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        _recordingPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          path: _recordingPath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
        
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print('녹음 시작 오류: $e');
    }
  }

  // 오디오 녹음 중지
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _audioFile = File(path);
        }
      });
    } catch (e) {
      print('녹음 중지 오류: $e');
    }
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

      await _emotionService.saveEmotionRecord(record);

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
    if (_detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정에 대한 설명을 입력해주세요')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 미디어 파일 업로드
      String? imageUrl;
      String? videoUrl;
      String? audioUrl;
      
      // Firebase Storage에 파일 업로드
      if (_imageFile != null) {
        imageUrl = await _emotionService.uploadImage(_imageFile!);
        if (imageUrl == null) {
          throw Exception('이미지 업로드에 실패했습니다.');
        }
      }
      
      if (_videoFile != null) {
        videoUrl = await _emotionService.uploadVideo(_videoFile!);
        if (videoUrl == null) {
          throw Exception('비디오 업로드에 실패했습니다.');
        }
      }
      
      if (_audioFile != null) {
        audioUrl = await _emotionService.uploadAudio(_audioFile!);
        if (audioUrl == null) {
          throw Exception('오디오 업로드에 실패했습니다.');
        }
      }

      EmotionRecord record = EmotionRecord(
        emotion: widget.emotion,
        emoji: widget.emoji,
        timestamp: DateTime.now(),
        details: _detailsController.text.trim(),
        tags: _selectedTags.toList(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        diaryContent: _diaryController.text.isNotEmpty ? _diaryController.text.trim() : null,
      );

      await _emotionService.saveEmotionRecord(record);

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

  // 태그 토글 처리
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        
                        // 태그 선택 영역
                        const Text('태그 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _availableTags.map((tag) => FilterChip(
                            label: Text(tag),
                            selected: _selectedTags.contains(tag),
                            onSelected: (_) => _toggleTag(tag),
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
                          )).toList(),
                        ),
                        const SizedBox(height: 16),
                        
                        // 감정 설명 입력
                        const Text('감정 설명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _detailsController,
                          decoration: const InputDecoration(
                            hintText: '지금 느끼는 감정에 대해 자세히 설명해보세요.',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
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
                          decoration: const InputDecoration(
                            hintText: '오늘 있었던 일과 감정에 대한 일기를 작성해보세요.',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
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