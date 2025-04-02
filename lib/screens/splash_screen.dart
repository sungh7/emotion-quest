import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/auth_screen.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _navigateToNextScreen() async {
    // 앱 시작 완료 상태 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_launched_before', true);
    
    if (!mounted) return;
    
    // 로그인 상태에 따라 다음 화면 결정
    final nextScreen = FirebaseService.currentUser != null
        ? const HomeScreen()
        : const AuthScreen();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 상태 표시줄 투명하게 설정
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    return Scaffold(
      body: Container(
        // color와 decoration을 동시에 사용할 수 없으므로 BoxDecoration으로 통합
        decoration: BoxDecoration(
          // 배경 색상 변경 (파란색에서 흰색으로)
          color: Colors.white,
          image: DecorationImage(
            image: const AssetImage('assets/images/night_sky.png'),
            fit: BoxFit.cover,
            // 이미지 로드 실패 시 에러 무시하고 배경색 표시
            onError: (exception, stackTrace) {
              print('배경 이미지 로드 실패: $exception');
            },
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 앱 로고와 제목
                  const Spacer(flex: 2),
                  const Text(
                    'LEVEL ZERO',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B4162), // 어두운 네이비 색상
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(flex: 1),
                  
                  // 캐릭터 이미지
                  Image.asset(
                    'assets/images/character.png',
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      print('캐릭터 이미지 로드 실패: $error');
                      // 이미지 로드 실패 시 아이콘으로 대체
                      return const Icon(
                        Icons.person,
                        size: 100,
                        color: Color(0xFF2B4162),
                      );
                    },
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // 시작 버튼
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact(); // 햅틱 피드백
                      _navigateToNextScreen();
                    },
                    child: Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B4162), // 진한 남색 유지
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'START',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 