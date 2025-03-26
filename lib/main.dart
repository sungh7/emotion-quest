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
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

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

  runApp(MyApp(
    firebaseInitialized: firebaseInitialized,
    themeService: themeService,
  ));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  final ThemeService themeService;
  
  const MyApp({
    Key? key, 
    required this.firebaseInitialized,
    required this.themeService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => themeService),
        Provider<bool>.value(value: firebaseInitialized),
        ChangeNotifierProvider(create: (_) => EmotionService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          final isDarkMode = themeService.isDarkMode;
          print('현재 테마 모드: ${isDarkMode ? 'Dark' : 'Light'}');
          
          return MaterialApp(
            title: '감정 퀘스트',
            debugShowCheckedModeBanner: false,
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: _getInitialScreen(),
            routes: {
              '/report': (context) => const ReportScreen(),
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
      ),
    );
  }

  Widget _getInitialScreen() {
    // Implement the logic to determine the initial screen based on the firebaseInitialized state
    return const HomeScreen();
  }
}
