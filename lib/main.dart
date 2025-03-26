import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/theme_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/emotion_detail_screen.dart';
import 'services/firebase_service.dart';

Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 전역 에러 핸들러 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter 에러: ${details.exception}');
  };
  
  // 테마 설정 로드
  final themeService = ThemeService();
  await themeService.initialize();
  
  // Firebase 초기화 
  bool firebaseInitialized = false;
  
  try {
    print('Firebase 초기화 시작...');
    
    // 웹 환경에서는 JavaScript가 이미 Firebase를 초기화했는지 확인
    if (kIsWeb) {
      // 먼저 Flutter Firebase Core를 항상 초기화 (JavaScript SDK와 별개로)
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
        print('Flutter Firebase Core 초기화 성공');
      } catch (e) {
        print('Flutter Firebase Core 초기화 실패: $e');
      }
      
      if (js.context.hasProperty('isFirebaseInitialized') && 
          js.context['isFirebaseInitialized'] == true) {
        print('JavaScript Firebase SDK가 이미 초기화되어 있음 - Flutter 초기화 건너뜀');
        firebaseInitialized = true;
      }
      
      // Firebase 서비스 초기화 (JavaScript 또는 Flutter SDK 사용)
      await FirebaseService.initializeFirebase();
      print('Firebase 서비스 초기화 완료!');
      firebaseInitialized = true;
    } else {
      // 네이티브 환경에서는 일반적인 초기화 과정 진행
      await _initializeFlutterFirebase();
      firebaseInitialized = true;
    }
  } catch (e, stackTrace) {
    print('Firebase 초기화 오류: $e');
    print('스택 트레이스: $stackTrace');
    
    // 웹 환경에서 JavaScript SDK가 초기화된 경우 Flutter 초기화 실패해도 서비스는 사용 가능할 수 있음
    if (kIsWeb && js.context.hasProperty('isFirebaseInitialized') && 
        js.context['isFirebaseInitialized'] == true) {
      print('JavaScript Firebase SDK 초기화 감지됨 - 제한된 기능으로 계속 진행');
      firebaseInitialized = true;
    }
  }
  
  // 앱 실행 - Firebase 초기화 실패해도 앱은 실행
  runApp(
    ChangeNotifierProvider(
      create: (context) => themeService,
      child: MyApp(firebaseInitialized: firebaseInitialized),
    ),
  );
}

// Flutter Firebase 초기화를 위한 헬퍼 함수
Future<void> _initializeFlutterFirebase() async {
  try {
    // 네이티브 환경에서는 기본 옵션 사용
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase 코어 초기화 성공!');
    
    // Firebase 서비스 초기화
    await FirebaseService.initializeFirebase();
    print('Firebase 서비스 초기화 완료!');
  } catch (e) {
    print('Flutter Firebase 초기화 실패: $e');
    rethrow; // 오류 전파
  }
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, this.firebaseInitialized = false});

  @override
  Widget build(BuildContext context) {
    // FirebaseService.currentUser가 null이 아니면, 로그인 상태
    final bool isLoggedIn = firebaseInitialized && FirebaseService.currentUser != null;
    
    final themeService = Provider.of<ThemeService>(context);
    
    return MaterialApp(
      title: '감정 퀘스트',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS 블루 색상
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS 라이트 모드 배경색
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF000000),
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          color: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            letterSpacing: -0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            letterSpacing: -0.3,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEFEFF4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF007AFF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: Color(0xFF007AFF),
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        // 페이지 전환 애니메이션 정의 (ThemeData 내부로 이동)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A84FF), // iOS 다크모드 블루 색상
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000), // iOS 다크 모드 배경색
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFFFFFFF),
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          color: const Color(0xFF1C1C1E), // iOS 다크모드 카드 색상
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
          titleMedium: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
          bodyLarge: TextStyle(
            fontSize: 17,
            letterSpacing: -0.5,
            color: Color(0xFFFFFFFF),
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            letterSpacing: -0.3,
            color: Color(0xFFFFFFFF),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A84FF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0A84FF),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: Color(0xFF0A84FF),
        ),
        cupertinoOverrideTheme: const CupertinoThemeData(
          primaryColor: Color(0xFF0A84FF),
          brightness: Brightness.dark,
        ),
        // 다크 테마의 페이지 전환 애니메이션도 동일하게 설정
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: themeService.themeMode,
      initialRoute: isLoggedIn ? '/' : '/auth',
      routes: {
        '/': (context) => const HomeScreen(),
        '/report': (context) => const ReportScreen(),
        '/auth': (context) => const AuthScreen(),
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
    );
  }
}
