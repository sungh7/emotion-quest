import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// 각 지원 플랫폼별 기본 옵션 설정
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          '현재 플랫폼 ${defaultTargetPlatform.name}에 대한 Firebase 설정이 없습니다',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyA4Tp1QAkYoSnDpzpFZlaqQ7W2MMVXz_EM",
    authDomain: "emotionalquest.firebaseapp.com",
    projectId: "emotionalquest",
    storageBucket: "emotionalquest.appspot.com",
    messagingSenderId: "184524308627",
    appId: "1:184524308627:web:dadb3a6bbeac4c5bffaf0c"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyA4Tp1QAkYoSnDpzpFZlaqQ7W2MMVXz_EM",
    appId: "1:184524308627:android:dadb3a6bbeac4c5bffaf0c",
    messagingSenderId: "184524308627",
    projectId: "emotionalquest",
    storageBucket: "emotionalquest.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyA4Tp1QAkYoSnDpzpFZlaqQ7W2MMVXz_EM",
    appId: "1:184524308627:ios:dadb3a6bbeac4c5bffaf0c",
    messagingSenderId: "184524308627",
    projectId: "emotionalquest",
    storageBucket: "emotionalquest.appspot.com",
    iosBundleId: "com.example.emotionControl",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyA4Tp1QAkYoSnDpzpFZlaqQ7W2MMVXz_EM",
    appId: "1:184524308627:macos:dadb3a6bbeac4c5bffaf0c",
    messagingSenderId: "184524308627",
    projectId: "emotionalquest",
    storageBucket: "emotionalquest.appspot.com",
    iosBundleId: "com.example.emotionControl.RunnerTests",
  );
} 