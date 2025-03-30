import 'package:emotion_control/services/emotion_service.dart';
import 'package:emotion_control/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/report_screen.dart';
import 'screens/emotion_detail_screen.dart';
import 'screens/wellbeing_screen.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './services/wellbeing_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ThemeService 초기화
  final themeService = ThemeService();
  await themeService.initialize();
  
  bool firebaseInitialized = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => EmotionService()),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider(create: (context) => WellbeingService()),
        Provider<bool>.value(value: firebaseInitialized),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseInitialized = Provider.of<bool>(context);
    
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDarkMode = themeService.isDarkMode;
        print('현재 테마 모드: ${isDarkMode ? 'Dark' : 'Light'}');
        
        return MaterialApp(
          title: '감정 퀘스트',
          debugShowCheckedModeBanner: false,
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.themeMode,
          home: _getInitialScreen(firebaseInitialized),
          routes: {
            '/report': (context) => const ReportScreen(),
            '/wellbeing': (context) => const WellbeingScreen(),
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
        );
      },
    );
  }

  Widget _getInitialScreen(bool firebaseInitialized) {
    // Implement the logic to determine the initial screen based on the firebaseInitialized state
    return const HomeScreen();
  }
}
