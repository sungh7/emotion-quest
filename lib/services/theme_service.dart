import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeService extends ChangeNotifier {
  // 테마 모드 (기본값: 시스템 설정)
  ThemeMode _themeMode = ThemeMode.system;
  
  // 현재 테마 모드
  ThemeMode get themeMode => _themeMode;
  
  // 다크 모드 여부 (시스템 설정 고려)
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // 시스템 설정에 따라 판단
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // 라이트 테마
  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.grey[50],
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Colors.black87,
        ),
      ),
      useMaterial3: true,
    );
  }
  
  // 다크 테마
  ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.blue[300],
        unselectedItemColor: Colors.grey[500],
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: Colors.white70,
        ),
      ),
      useMaterial3: true,
    );
  }
  
  // 테마 전환
  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      // 시스템 설정인 경우 현재 시스템 상태의 반대로 설정
      _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
  
  // 테마 설정
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // 시스템 테마로 설정
  void useSystemTheme() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
} 