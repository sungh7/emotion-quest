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
import 'services/emotion_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('Firebase 초기화 완료');
  } catch (e) {
    print('Firebase 초기화 오류: $e');
    firebaseInitialized = false;
  }
  
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({Key? key, required this.firebaseInitialized}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => EmotionService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: '감정 퀘스트',
            debugShowCheckedModeBanner: false,
            theme: themeService.isDarkMode
                ? ThemeData.dark(
                    useMaterial3: true,
                  ).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: Colors.teal[400] ?? Colors.teal,
                      secondary: Colors.tealAccent[400] ?? Colors.tealAccent,
                    ),
                  )
                : ThemeData.light(
                    useMaterial3: true,
                  ).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.teal[600] ?? Colors.teal,
                      secondary: Colors.tealAccent[700] ?? Colors.tealAccent,
                    ),
                  ),
            themeMode: themeService.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/auth': (context) => const AuthScreen(),
              '/report': (context) => const ReportScreen(),
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
        },
      ),
    );
  }
}
