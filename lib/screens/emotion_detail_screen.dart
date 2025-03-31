import 'dart:io';
import 'package:flutter/foundation.dart';
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
// import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_animate/flutter_animate.dart';
// 웹 지원을 위한 추가 임포트
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:async'; // TimeoutException을 위한 import 추가

// 오디오 녹음을 위한 플랫폼별 조건부 임포트 추가는 웹 빌드에서 실패하므로 제거
// import 'audio_helper.dart' if (dart.library.js) 'audio_helper_web.dart';

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
  
  // 웹을 위한 추가 변수
  Uint8List? _webImageBytes;
  String? _webImageName;
  
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
    // 웹 환경인지 체크
    if (kIsWeb) {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _webImageName = pickedFile.name;
        });
        print('웹 환경에서 이미지 선택: ${pickedFile.name}, 크기: ${bytes.length} bytes');
      }
    } else {
      // 모바일 환경에서의 기존 코드
      final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        print('모바일 환경에서 이미지 선택: ${pickedFile.path}');
      }
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

  // 오디오 녹음 시작
  Future<void> _startRecording() async {
    // 웹 환경에서는 녹음 기능 비활성화
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹 환경에서는 녹음 기능이 지원되지 않습니다. 모바일 앱을 이용해주세요.'))
      );
      return;
    }
    
    // 웹 빌드에서 Record 클래스 사용 오류를 방지하기 위해 현재 기능 비활성화
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('녹음 기능이 현재 비활성화되어 있습니다. 향후 업데이트에서 지원될 예정입니다.'))
    );
    
    // 모바일 환경에서도 현재는 비활성화
    return;
    
    // 아래 코드는 웹 빌드 오류로 주석 처리
    /*
    // 여기서부터는 모바일 환경에서만 실행됨
    try {
      // 다트 분석기가 아래 코드를 웹에서도 실행 가능하다고 판단하지만,
      // if (kIsWeb) 체크로 실제로는 웹에서 실행되지 않음
      if (!kIsWeb) {
        final recorder = Record();
        
        // 권한 체크
        if (await recorder.hasPermission()) {
          // 임시 파일 경로 생성
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          // 녹음 시작
          await recorder.start(
            path: tempPath,
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            samplingRate: 44100,
          );
          
          setState(() {
            _isRecording = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('녹음이 시작되었습니다. 최대 1분간 녹음할 수 있습니다.'))
          );
          
          // 1분 후 자동 중지
          Future.delayed(const Duration(minutes: 1), () {
            if (_isRecording) {
              _stopRecording();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('마이크 권한이 필요합니다.'))
          );
        }
      }
    } catch (e) {
      print('녹음 시작 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('녹음을 시작할 수 없습니다: $e'))
      );
    }
    */
  }

  // 오디오 녹음 중지
  Future<void> _stopRecording() async {
    // 상태 업데이트만 수행
    setState(() {
      _isRecording = false;
    });
    return;
    
    // 아래 코드는 웹 빌드 오류로 주석 처리
    /*
    // 웹 환경이면 그냥 상태만 업데이트
    if (kIsWeb) {
      setState(() {
        _isRecording = false;
      });
      return;
    }

    try {
      // 여기서부터는 모바일 환경에서만 실행됨
      if (!kIsWeb && _isRecording) {
        final recorder = Record();
        // 녹음 중지
        final path = await recorder.stop();
        
        setState(() {
          _isRecording = false;
          
          if (path != null) {
            _audioFile = File(path);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('녹음이 완료되었습니다.'))
            );
          }
        });
      }
    } catch (e) {
      print('녹음 중지 오류: $e');
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('녹음을 중지할 수 없습니다: $e'))
      );
    }
    */
  }

  // 미디어 파일 업로드 메서드 추가
  Future<Map<String, String?>> _uploadMedia() async {
    final String userId = FirebaseService.currentUser?.uid ?? 'anonymous';
    String? imageUrl;
    String? videoUrl;
    String? audioUrl;
    
    try {
      // 웹 환경에서 이미지 업로드
      if (kIsWeb && _webImageBytes != null) {
        final uniqueFileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${_webImageName ?? 'image.jpg'}';
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('emotion_images')
            .child(uniqueFileName);
        
        // 메타데이터 설정
        final metadata = firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        );
        
        // 바이트 데이터 업로드 (타임아웃 추가)
        try {
          // 시간 제한 설정
          final uploadTask = await storageRef.putData(_webImageBytes!, metadata)
              .timeout(const Duration(seconds: 20), onTimeout: () {
            print('이미지 업로드 타임아웃');
            throw TimeoutException('이미지 업로드 시간이 초과되었습니다.');
          });
          
          imageUrl = await storageRef.getDownloadURL();
          print('웹 환경에서 이미지 업로드 완료: $imageUrl');
        } catch (e) {
          print('웹 이미지 업로드 오류: $e');
          // 타임아웃이나 다른 오류가 발생하면 null 반환
          imageUrl = null;
        }
      } 
      // 모바일 환경에서 이미지 업로드
      else if (_imageFile != null) {
        final uniqueFileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('emotion_images')
            .child(uniqueFileName);
        
        // 메타데이터 설정
        final metadata = firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        );
        
        try {
          // 시간 제한 설정
          await storageRef.putFile(_imageFile!, metadata)
              .timeout(const Duration(seconds: 20), onTimeout: () {
            print('이미지 업로드 타임아웃');
            throw TimeoutException('이미지 업로드 시간이 초과되었습니다.');
          });
          
          imageUrl = await storageRef.getDownloadURL();
          print('모바일 환경에서 이미지 업로드 완료: $imageUrl');
        } catch (e) {
          print('모바일 이미지 업로드 오류: $e');
          imageUrl = null;
        }
      }
      
      if (_videoFile != null) {
        final uniqueFileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('emotion_videos')
            .child(uniqueFileName);
        
        try {
          await storageRef.putFile(_videoFile!)
              .timeout(const Duration(seconds: 30), onTimeout: () {
            throw TimeoutException('비디오 업로드 시간이 초과되었습니다.');
          });
          videoUrl = await storageRef.getDownloadURL();
          print('비디오 업로드 완료: $videoUrl');
        } catch (e) {
          print('비디오 업로드 오류: $e');
          videoUrl = null;
        }
      }
      
      if (_audioFile != null) {
        final uniqueFileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('emotion_audios')
            .child(uniqueFileName);
        
        try {
          await storageRef.putFile(_audioFile!)
              .timeout(const Duration(seconds: 20), onTimeout: () {
            throw TimeoutException('오디오 업로드 시간이 초과되었습니다.');
          });
          audioUrl = await storageRef.getDownloadURL();
          print('오디오 업로드 완료: $audioUrl');
        } catch (e) {
          print('오디오 업로드 오류: $e');
          audioUrl = null;
        }
      }
      
      return {
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'audioUrl': audioUrl,
      };
    } catch (e) {
      print('미디어 업로드 일반 오류: $e');
      // 오류 발생해도 계속 진행
      return {
        'imageUrl': null,
        'videoUrl': null,
        'audioUrl': null,
      };
    }
  }

  // 감정 기록 저장 (통합된 메서드)
  Future<void> _saveEmotionRecord() async {
    // 로딩 상태 설정
    setState(() {
      _isLoading = true;
      _isSaving = true;
    });

    try {
      // 미디어 파일 있는 경우 업로드 시작
      Map<String, String?> mediaUrls = {};
      
      if (_imageFile != null || _videoFile != null || _audioFile != null || _webImageBytes != null) {
        // 업로드 진행 중 안내
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('미디어 파일을 업로드하는 중입니다. 잠시만 기다려주세요...'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // 미디어 업로드
        mediaUrls = await _uploadMedia();
      }
      
      // EmotionRecord 생성
      EmotionRecord record = EmotionRecord(
        emotion: widget.emotion,
        emoji: widget.emoji,
        timestamp: DateTime.now(),
        details: _detailsController.text.isEmpty ? null : _detailsController.text.trim(),
        tags: _selectedTags.toList(),
        imageUrl: mediaUrls['imageUrl'],
        videoUrl: mediaUrls['videoUrl'],
        audioUrl: mediaUrls['audioUrl'],
        diaryContent: _diaryController.text.isEmpty ? null : _diaryController.text.trim(),
      );

      // 감정 기록 저장
      await Provider.of<EmotionService>(context, listen: false).saveEmotionRecord(record);

      // 저장 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('감정이 저장되었습니다')),
        );
        
        // 화면 닫기
        Navigator.pop(context, true);
      }
    } catch (e) {
      // 오류 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('감정 기록 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // 로딩 상태 해제
        setState(() {
          _isLoading = false;
          _isSaving = false;
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    _isSaving ? '감정 기록 저장 중...' : '로딩 중...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
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
                                  color: (_imageFile != null || _webImageBytes != null) ? Theme.of(context).primaryColor : Colors.grey,
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
                        if (_imageFile != null || _videoFile != null || _audioFile != null || _webImageBytes != null) ...[
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
                                if (kIsWeb && _webImageBytes != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.memory(
                                            _webImageBytes!,
                                            height: 84,
                                            width: 84,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () => setState(() {
                                              _webImageBytes = null;
                                              _webImageName = null;
                                            }),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!kIsWeb && _imageFile != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.file(_imageFile!, height: 84, width: 84, fit: BoxFit.cover),
                                        ),
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
                        // 저장 버튼 (통합)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveEmotionRecord,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              '감정 저장하기',
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