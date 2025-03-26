import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class EmotionButton extends StatefulWidget {
  final String emotion;
  final String emoji;
  final VoidCallback onPressed;

  const EmotionButton({
    Key? key,
    required this.emotion,
    required this.emoji,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<EmotionButton> createState() => _EmotionButtonState();
}

class _EmotionButtonState extends State<EmotionButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 버튼 색상 설정
  Color _getButtonColor(bool isDarkMode) {
    final Map<String, List<Color>> emotionColors = {
      '행복': isDarkMode ? [Color(0xFF388E3C), Color(0xFF2E7D32)] : [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      '기쁨': isDarkMode ? [Color(0xFF7CB342), Color(0xFF689F38)] : [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      '사랑': isDarkMode ? [Color(0xFFC2185B), Color(0xFFAD1457)] : [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      '화남': isDarkMode ? [Color(0xFFD32F2F), Color(0xFFC62828)] : [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
      '슬픔': isDarkMode ? [Color(0xFF1976D2), Color(0xFF1565C0)] : [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      '불안': isDarkMode ? [Color(0xFFFFA000), Color(0xFFFF8F00)] : [Color(0xFFFFF8E1), Color(0xFFFFE082)],
      '무기력': isDarkMode ? [Color(0xFF757575), Color(0xFF616161)] : [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
      '지루함': isDarkMode ? [Color(0xFF78909C), Color(0xFF607D8B)] : [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
    };
    
    // 해당 감정의 색상이 없으면 기본 색상 반환
    return emotionColors[widget.emotion]?.first ?? (isDarkMode ? Colors.grey[800]! : Colors.grey[200]!);
  }
  
  Color _getButtonGradientColor(bool isDarkMode) {
    final Map<String, List<Color>> emotionColors = {
      '행복': isDarkMode ? [Color(0xFF388E3C), Color(0xFF2E7D32)] : [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      '기쁨': isDarkMode ? [Color(0xFF7CB342), Color(0xFF689F38)] : [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      '사랑': isDarkMode ? [Color(0xFFC2185B), Color(0xFFAD1457)] : [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      '화남': isDarkMode ? [Color(0xFFD32F2F), Color(0xFFC62828)] : [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
      '슬픔': isDarkMode ? [Color(0xFF1976D2), Color(0xFF1565C0)] : [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      '불안': isDarkMode ? [Color(0xFFFFA000), Color(0xFFFF8F00)] : [Color(0xFFFFF8E1), Color(0xFFFFE082)],
      '무기력': isDarkMode ? [Color(0xFF757575), Color(0xFF616161)] : [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
      '지루함': isDarkMode ? [Color(0xFF78909C), Color(0xFF607D8B)] : [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
    };
    
    return emotionColors[widget.emotion]?.last ?? (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
              HapticFeedback.mediumImpact(); // iOS 스타일 햅틱 피드백
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _animationController.reverse();
              widget.onPressed();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _animationController.reverse();
            },
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getButtonColor(isDarkMode),
                    _getButtonGradientColor(isDarkMode),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isPressed 
                  ? [] 
                  : [
                      BoxShadow(
                        color: isDarkMode 
                          ? Colors.black.withOpacity(0.3) 
                          : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.emoji,
                        style: const TextStyle(
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.emotion,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 