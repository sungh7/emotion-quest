import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/emotion_service.dart';

class TagManagementScreen extends StatefulWidget {
  const TagManagementScreen({Key? key}) : super(key: key);

  @override
  State<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends State<TagManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  
  List<String> _allTags = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadTags();
  }
  
  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }
  
  // 모든 태그 로드
  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      final tags = await emotionService.getAllTags();
      
      setState(() {
        _allTags = List<String>.from(tags); // 복사본 생성
        _isLoading = false;
      });
      
      print('태그 관리 화면에 로드된 태그: $_allTags');
    } catch (e) {
      print('태그 로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('태그 로드 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 새 태그 추가
  Future<void> _addTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final newTag = _tagController.text.trim();
    
    if (_allTags.contains(newTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미 존재하는 태그입니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _allTags.add(newTag);
      _tagController.clear();
    });
    
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    final success = await emotionService.saveCustomTags(_allTags);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '새 태그가 추가되었습니다' : '태그 추가 중 오류가 발생했습니다'),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }
  
  // 태그 삭제
  Future<void> _deleteTag(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('정말 "$tag" 태그를 삭제하시겠습니까?'),
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
      _allTags.remove(tag);
    });
    
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    final success = await emotionService.saveCustomTags(_allTags);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '태그가 삭제되었습니다' : '태그 삭제 중 오류가 발생했습니다'),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }
  
  // 빌드 메서드
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true); // 태그 변경 성공 여부 반환
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('태그 관리', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTags,
              child: Column(
                children: [
                  // 태그 추가 폼
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '새 태그 추가',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _tagController,
                                  decoration: const InputDecoration(
                                    labelText: '태그 이름',
                                    hintText: '예: 업무, 가족, 건강, 여행',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '태그 이름을 입력해주세요';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _addTag,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text('추가'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // 태그 목록 타이틀
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text(
                          '내 태그 목록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_allTags.length}개',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 기본 태그와 사용자 정의 태그 표시
                  Expanded(
                    child: _allTags.isEmpty
                      ? const Center(
                          child: Text(
                            '아직 등록된 태그가 없습니다\n태그를 추가해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _allTags.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tag = _allTags[index];
                            final emotionService = Provider.of<EmotionService>(context, listen: false);
                            final isDefaultTag = emotionService.defaultTags.contains(tag);
                            
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.tag,
                                color: isDefaultTag ? theme.colorScheme.primary : null,
                              ),
                              title: Text(
                                tag,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDefaultTag ? theme.colorScheme.primary : null,
                                ),
                              ),
                              trailing: isDefaultTag
                                ? const Chip(
                                    label: Text('기본', style: TextStyle(fontSize: 12)),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteTag(tag),
                                    tooltip: '태그 삭제',
                                    color: Colors.red[400],
                                  ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
} 