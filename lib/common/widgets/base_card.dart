import 'package:flutter/material.dart';

/// 앱 전체에서 사용될 카드 위젯의 기본 스타일
///
/// 기본적인 패딩, 모양, 그림자 등을 포함합니다.
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;

  const BaseCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.shape,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: elevation ?? 1.0, // 기본 그림자 약간
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0), // 기본 상하 마진
      shape: shape ?? RoundedRectangleBorder( // 기본 둥근 모서리
        borderRadius: BorderRadius.circular(12.0),
      ),
      color: color, // 기본 색상 (테마 의존)
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0), // 기본 내부 패딩
        child: child,
      ),
    );
  }
} 