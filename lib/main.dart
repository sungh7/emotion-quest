import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/emotion_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/report_screen.dart';
import 'screens/wellbeing_screen.dart';
import 'services/wellbeing_service.dart';
import 'services/game_service.dart';
import 'services/quest_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 사용자 로그인 상태 확인
  final user = FirebaseService.currentUser;
  
  // 앱 최초 실행 여부 확인 (로그인 상태인 경우 무시)
  bool firstLaunch = false;
  if (user == null) {
    final prefs = await SharedPreferences.getInstance();
    firstLaunch = !(prefs.getBool('app_launched_before') ?? false);
    
    // 앱 실행 기록 저장 (로그인되지 않은 경우에만)
    if (firstLaunch) {
      await prefs.setBool('app_launched_before', true);
    }
  }
  
  // EmotionService 및 QuestService 인스턴스 생성
  final emotionService = EmotionService();
  final questService = QuestService();
  final gameService = GameService();
  
  // 사용자가 인증된 경우 초기 데이터 로드
  if (user != null) {
    // 비동기로 데이터 로드 시작 (결과는 기다리지 않음)
    emotionService.loadEmotionRecords();
    questService.loadQuests();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<EmotionService>(
          create: (context) => emotionService,
        ),
        ChangeNotifierProvider<QuestService>(
          create: (context) => questService,
        ),
        ChangeNotifierProvider<GameService>(
          create: (context) => gameService,
        ),
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => WellbeingService()),
        Provider<bool>.value(value: true),
        // 앱 최초 실행 여부 공유
        Provider<bool>.value(value: firstLaunch),
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
    // 앱 최초 실행 여부
    final firstLaunch = Provider.of<bool>(context, listen: false);
    
    // 로그인 상태를 체크
    final user = FirebaseService.currentUser;
    print('현재 로그인 상태: ${user != null ? "로그인됨 (${user.email})" : "로그인되지 않음"}');
    
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
          // 앱 최초 실행 시 또는 로그인 안된 상태면 스플래시 화면, 그렇지 않으면 홈 화면으로 이동
          home: _getInitialScreen(firstLaunch),
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

  Widget _getInitialScreen(bool firstLaunch) {
    // 로그인 상태를 먼저 확인
    final user = FirebaseService.currentUser;
    
    // 로그인된 사용자는 항상 홈 화면으로 이동
    if (user != null) {
      return const HomeScreen();
    }
    
    // 스플래시 화면을 표시할지 여부 확인
    bool showSplash = false;
    SharedPreferences.getInstance().then((prefs) {
      bool splashShown = prefs.getBool('splash_shown') ?? false;
      if (!splashShown) {
        prefs.setBool('splash_shown', true);
      }
    });
    
    // 스플래시 화면을 한 번도 보지 않았으면 표시, 그렇지 않으면 로그인 화면으로 이동
    return firstLaunch ? const SplashScreen() : const AuthScreen();
  }
}
