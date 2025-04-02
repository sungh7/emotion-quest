import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  // 테마 모드
  ThemeMode _themeMode = ThemeMode.system;
  
  // 로컬 저장소 키
  static const String _themeModeKey = 'theme_mode';
  
  // 게터
  ThemeMode get themeMode => _themeMode;
  
  // 현재 다크 모드 여부
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
  
  // 생성자
  ThemeService() {
    _loadThemeMode();
  }
  
  // 테마 모드 로드
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeModeKey);
      
      if (themeModeIndex != null) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }
      
      notifyListeners();
    } catch (e) {
      print('테마 모드 로드 오류: $e');
    }
  }
  
  // 테마 모드 저장
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      print('테마 모드 저장 오류: $e');
    }
  }
  
  // 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveThemeMode();
    notifyListeners();
  }
  
  // 테마 모드 토글 (다크 <-> 라이트)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
  
  // 라이트 테마
  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
  
  // 다크 테마
  ThemeData getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
} 