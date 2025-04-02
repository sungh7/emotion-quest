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
  final _tagFocusNode = FocusNode();
  
  List<String> _allTags = [];
  bool _isLoading = true;
  final TextEditingController _newTagController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadTags();
  }
  
  @override
  void dispose() {
    _tagController.dispose();
    _tagFocusNode.dispose();
    _newTagController.dispose();
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
      
      // 성공적으로 추가되었다면 TextField에 다시 포커스
      if (success) {
        FocusScope.of(context).requestFocus(FocusNode());
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_tagController.text.isEmpty && mounted) {
            FocusScope.of(context).requestFocus(_tagFocusNode);
          }
        });
      }
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
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
        // 키보드 포커스 해제
        FocusScope.of(context).unfocus();
        Navigator.pop(context, true); // 태그 변경 성공 여부 반환
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('태그 관리', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 키보드 포커스 해제
              FocusScope.of(context).unfocus();
              Navigator.pop(context, true);
            },
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newTagController,
                            decoration: InputDecoration(
                              labelText: '새 태그',
                              hintText: '추가할 태그를 입력하세요',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _addTag,
                          child: Text('추가'),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allTags.length,
                      itemBuilder: (context, index) {
                        final tag = _allTags[index];
                        return ListTile(
                          title: Text(tag),
                          leading: Icon(Icons.tag),
                          trailing: _defaultTags.contains(tag)
                              ? Chip(label: Text('기본'))
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<String> _defaultTags = ['가족', '친구', '직장', '건강', '취미', '학업'];

  void _filterTags(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<String> _getFilteredDefaultTags() {
    // TODO: EmotionService에 defaultTags 게터 추가 필요
    // final defaultTags = Provider.of<EmotionService>(context, listen: false).defaultTags;
    final defaultTags = ['업무', '가족', '친구', '건강', '취미']; // 임시 데이터
    if (_searchQuery.isEmpty) {
      return defaultTags;
    }
    return defaultTags.where((tag) => 
      tag.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<String> _getFilteredCustomTags() {
    if (_searchQuery.isEmpty) {
      return _allTags;
    }
    return _allTags.where((tag) => 
      tag.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _addNewTag() async {
    final newTag = _newTagController.text.trim();
    if (newTag.isEmpty) return;

    // 이미 존재하는 태그인지 확인
    if (_allTags.contains(newTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 존재하는 태그입니다: $newTag')),
      );
      return;
    }

    setState(() {
      _allTags.add(newTag);
      _newTagController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('새 태그가 추가되었습니다: $newTag')),
    );
  }

  void _deleteTag(String tag) {
    setState(() {
      _allTags.remove(tag);
    });
  }

  /*
  // TODO: EmotionService에 태그 저장 로직 구현 후 주석 해제
  Future<void> _saveTags() async {
    final emotionService = Provider.of<EmotionService>(context, listen: false);
    try {
      // final success = await emotionService.saveCustomTags(_allTags);
      // if (!success && mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('태그 저장 중 오류 발생'), backgroundColor: Colors.red),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('태그 저장 오류: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  */
} 