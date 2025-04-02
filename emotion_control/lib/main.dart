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
import 'screens/wellbeing_screen.dart';
import './services/wellbeing_service.dart';
import './services/game_service.dart';
import './services/quest_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // QuestService 초기화
  final questService = QuestService();
  
  // Firebase 초기화 전에 assets 로드 시도
  try {
    await questService.loadQuests();
    print('퀘스트 서비스 초기화 완료');
  } catch (e) {
    print('퀘스트 서비스 초기화 오류: $e');
  }

  bool firebaseInitialized = false;
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.initializeFirebase();
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
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => WellbeingService()),
        Provider<bool>.value(value: firebaseInitialized),
        ChangeNotifierProvider(create: (_) => GameService()),
        ChangeNotifierProvider.value(value: questService),
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
          theme: themeService.getLightTheme(),
          darkTheme: themeService.getDarkTheme(),
          themeMode: themeService.themeMode,
          home: _getInitialScreen(firebaseInitialized),
          routes: {
            '/report': (context) => const ReportScreen(),
            '/wellbeing': (context) => const WellbeingScreen(),
            '/auth': (context) => const AuthScreen(),
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
