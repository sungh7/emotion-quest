import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  // 라이트 테마 정의
  ThemeData get lightTheme => ThemeData.light(
    useMaterial3: true,
  ).copyWith(
    colorScheme: ColorScheme.light(
      primary: Colors.teal[600] ?? Colors.teal,
      secondary: Colors.tealAccent[700] ?? Colors.tealAccent,
    ),
  );
  
  // 다크 테마 정의
  ThemeData get darkTheme => ThemeData.dark(
    useMaterial3: true,
  ).copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.teal[400] ?? Colors.teal,
      secondary: Colors.tealAccent[400] ?? Colors.tealAccent,
    ),
  );
  
  /// 테마 서비스 초기화 및 저장된 테마 모드 로드
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
  }
  
  /// SharedPreferences에서 테마 모드 설정 로드
  void _loadThemeMode() {
    final savedThemeMode = _prefs.getString(_themeKey);
    if (savedThemeMode != null) {
      switch (savedThemeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
          break;
      }
    }
    notifyListeners();
  }
  
  /// 테마 모드 변경 및 저장
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    String themeModeValue;
    switch (mode) {
      case ThemeMode.light:
        themeModeValue = 'light';
        break;
      case ThemeMode.dark:
        themeModeValue = 'dark';
        break;
      case ThemeMode.system:
        themeModeValue = 'system';
        break;
    }
    
    await _prefs.setString(_themeKey, themeModeValue);
    notifyListeners();
  }
  
  /// 라이트 모드로 설정
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }
  
  /// 다크 모드로 설정
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// 시스템 설정 모드로 설정
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// 현재 테마 모드를 반대 모드로 전환 (라이트 <-> 다크)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
} 