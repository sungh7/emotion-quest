import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:js' as js;
import 'dart:js_util';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_record.dart';

/// Firebase 인증 및 데이터베이스 서비스
///
/// 웹 환경에서는 JavaScript Firebase SDK를 우선적으로 사용하고,
/// 네이티브 환경에서는 Flutter Firebase SDK를 사용합니다.
class FirebaseService {
  // 싱글톤 인스턴스
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // 내부 인스턴스 저장
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static bool _jsFirebaseInitialized = false;
  static bool _initialized = false;
  
  /// Firebase 초기화 여부 반환
  static bool get isInitialized => _initialized;
  
  /// 웹 환경인지 확인
  static bool get isWeb => kIsWeb;
  
  /// JavaScript Firebase SDK 초기화 여부 확인
  static bool get isJSFirebaseInitialized => _jsFirebaseInitialized;
  
  /// Firebase Auth 인스턴스 가져오기
  static FirebaseAuth get auth {
    // 이미 초기화된 경우 바로 반환
    if (_auth != null) return _auth!;
    
    try {
      _auth = FirebaseAuth.instance;
      return _auth!;
    } catch (e) {
      print("Firebase Auth 인스턴스 가져오기 실패: $e");
      throw "Firebase 인증이 초기화되지 않았습니다.";
    }
  }
  
  /// Firestore 인스턴스 가져오기
  static FirebaseFirestore get firestore {
    // 이미 초기화된 경우 바로 반환
    if (_firestore != null) return _firestore!;
    
    try {
      _firestore = FirebaseFirestore.instance;
      return _firestore!;
    } catch (e) {
      print("Firestore 인스턴스 가져오기 실패: $e");
      throw "Firestore가 초기화되지 않았습니다.";
    }
  }
  
  /// Firebase 초기화
  static Future<void> initializeFirebase() async {
    // 이미 초기화된 경우 바로 반환
    if (_initialized) return;
    
    try {
      if (isWeb) {
        print("웹 환경에서 Firebase 초기화 중...");
        
        // 웹에서 JavaScript SDK 초기화 여부 확인
        if (isJSFirebaseInitialized) {
          print("JavaScript Firebase SDK 감지됨, Flutter SDK 초기화 건너뜀");
          
          // JavaScript SDK가 초기화되어 있더라도 Flutter SDK도 초기화
          // (이미 main.dart에서 시도했기 때문에 여기서는 생략)
          _initialized = true;
          return;
        }
      }
      
      // 네이티브 환경 또는 웹에서 JavaScript SDK가 초기화되지 않은 경우
      try {
        _auth = FirebaseAuth.instance;
        _firestore = FirebaseFirestore.instance;
        _initialized = true;
        print("Firebase 서비스 초기화 완료");
      } catch (e) {
        print("Flutter Firebase 인스턴스 초기화 실패: $e");
        
        // 웹 환경에서 JavaScript SDK가 초기화되어 있다면 계속 진행
        if (isWeb && isJSFirebaseInitialized) {
          _initialized = true;
          print("Flutter SDK 초기화 실패했지만 JavaScript SDK 사용 가능 - 계속 진행");
          return;
        }
        
        throw e;
      }
    } catch (e) {
      print("Firebase 서비스 초기화 오류: $e");
      
      if (isWeb && isJSFirebaseInitialized) {
        print("JavaScript SDK가 초기화되어 있어 계속 진행합니다.");
        _initialized = true;
        return;
      }
      
      throw "Firebase 초기화 실패: $e";
    }
  }
  
  /// JavaScript 함수 결과를 기다리기 위한 헬퍼 함수
  static Future<Map<String, dynamic>> _waitForJSResult(String resultVarName, {int maxAttempts = 30, int delayMs = 200}) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      attempts++;
      
      try {
        final result = js.context[resultVarName];
        
        if (result != null) {
          // JSON 객체로 직접 변환, JSON.stringify()로 감싸진 문자열이 아니라면 직접 사용
          try {
            if (result is String) {
              return json.decode(result);
            } else {
              // JS 객체를 Dart Map으로 변환
              final jsObject = result as js.JsObject;
              // Dart Map으로 변환
              Map<String, dynamic> dartMap = {};
              
              if (jsObject['success'] != null) {
                dartMap['success'] = jsObject['success'] as bool;
              }
              
              if (jsObject['error'] != null) {
                dartMap['error'] = jsObject['error'].toString();
              }
              
              if (jsObject['records'] != null) {
                try {
                  final jsRecords = jsObject['records'] as js.JsArray;
                  final List<dynamic> records = List.from(jsRecords);
                  dartMap['records'] = records;
                } catch (e) {
                  print('레코드 변환 오류: $e');
                  dartMap['records'] = [];
                }
              }
              
              if (jsObject['user'] != null) {
                try {
                  final jsUser = jsObject['user'];
                  dartMap['user'] = {
                    'uid': jsUser['uid'],
                    'email': jsUser['email'],
                    'displayName': jsUser['displayName'],
                  };
                } catch (e) {
                  print('사용자 정보 변환 오류: $e');
                }
              }
              
              // 기타 속성들 복사
              if (jsObject['id'] != null) dartMap['id'] = jsObject['id'].toString();
              if (jsObject['code'] != null) dartMap['code'] = jsObject['code'].toString();
              if (jsObject['isLocal'] != null) dartMap['isLocal'] = jsObject['isLocal'] as bool;
              
              return dartMap;
            }
          } catch (e) {
            print('${resultVarName} 결과 파싱 오류: $e');
            // 오류가 발생해도 js.context[resultVarName]을 null로 설정하지 않음
            throw FormatException('$e');
          }
        }
        
        print('${resultVarName} 대기 중... (시도: $attempts/$maxAttempts)');
        await Future.delayed(Duration(milliseconds: delayMs));
      } catch (e) {
        print('${resultVarName} 처리 오류: $e');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
    
    throw TimeoutException('JavaScript 결과를 기다리는 시간이 초과되었습니다: $resultVarName');
  }
  
  /// 웹 환경에서 JavaScript 함수 호출 및 결과 처리
  static Future<Map<String, dynamic>> _callJSFunction(String functionName, List<dynamic> args, String resultVariableName) async {
    try {
      // JavaScript 함수 호출
      js.context.callMethod(functionName, args);
      
      // 결과 대기
      final jsResult = await _waitForJSResult(resultVariableName);
      
      // 결과 반환
      return jsResult;
    } catch (e) {
      print('JS 함수 호출 오류: $e');
      throw Exception('JavaScript 함수 호출 중 오류 발생: $e');
    }
  }
  
  /// 이메일로 회원가입
  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    if (isWeb && isJSFirebaseInitialized) {
      try {
        final result = await _callJSFunction(
          'signUpWithEmailJS', 
          [email, password], 
          'signupResult'
        );
        
        if (result['success'] == true) {
          return _createWebUserCredential(result['user']);
        } else {
          final errorMsg = result['error'] ?? '회원가입 실패';
          print("회원가입 실패 메시지: $errorMsg");
          
          // 에러 유형에 따른 메시지 반환
          if (errorMsg.contains('email-already-in-use')) {
            throw '이미 사용 중인 이메일입니다.';
          } else if (errorMsg.contains('weak-password')) {
            throw '비밀번호가 너무 약합니다.';
          } else if (errorMsg.contains('invalid-email')) {
            throw '유효하지 않은 이메일 형식입니다.';
          }
          
          throw errorMsg;
        }
      } catch (e) {
        if (e is String) throw e;
        throw '회원가입 중 오류가 발생했습니다: $e';
      }
    } else {
      try {
        return await auth.createUserWithEmailAndPassword(
          email: email,
          password: password
        );
      } catch (e) {
        print("회원가입 오류: $e");
        if (e is FirebaseAuthException) {
          if (e.code == 'email-already-in-use') {
            throw '이미 사용 중인 이메일입니다.';
          } else if (e.code == 'weak-password') {
            throw '비밀번호가 너무 약합니다.';
          } else if (e.code == 'invalid-email') {
            throw '유효하지 않은 이메일 형식입니다.';
          }
        }
        throw '회원가입 중 오류가 발생했습니다: $e';
      }
    }
  }
  
  /// 이메일로 로그인
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      if (kIsWeb && isJSFirebaseInitialized) {
        // JavaScript로 로그인
        js.context.callMethod('signInWithEmailJS', [email, password]);
        
        final result = await _waitForJSResult('loginResult');
        
        if (result['success'] == true) {
          // Flutter Auth 상태 업데이트를 위해 대기
          await Future.delayed(Duration(seconds: 1));
          return auth.currentUser;
        } else {
          final errorCode = result['code'] ?? 'unknown';
          final errorMsg = result['error'] ?? '로그인 실패';
          
          print('로그인 실패 - 코드: $errorCode, 메시지: $errorMsg');
          
          throw FirebaseAuthException(
            code: errorCode,
            message: errorMsg,
          );
        }
      } else {
        // Flutter SDK로 로그인
        try {
          final userCredential = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          return userCredential.user;
        } on FirebaseAuthException catch (e) {
          // 오류 코드별 맞춤 메시지
          String errorMessage;
          if (e.code == 'invalid-credential' || e.code == 'invalid-email') {
            errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다';
          } else if (e.code == 'user-disabled') {
            errorMessage = '계정이 비활성화되었습니다';
          } else if (e.code == 'user-not-found') {
            errorMessage = '해당 이메일로 등록된 계정이 없습니다';
          } else if (e.code == 'wrong-password') {
            errorMessage = '비밀번호가 올바르지 않습니다';
          } else if (e.code == 'too-many-requests') {
            errorMessage = '너무 많은 로그인 시도가 있었습니다. 잠시 후 다시 시도해주세요';
          } else {
            errorMessage = e.message ?? '로그인 실패';
          }
          
          throw FirebaseAuthException(
            code: e.code,
            message: errorMessage,
          );
        }
      }
    } catch (e) {
      print('로그인 오류: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      } else {
        throw '로그인 중 오류가 발생했습니다: $e';
      }
    }
  }
  
  /// 로그아웃
  static Future<void> signOut() async {
    if (isWeb && isJSFirebaseInitialized) {
      try {
        await _callJSFunction('signOutJS', [], 'signoutResult');
      } catch (e) {
        print("로그아웃 오류 (JavaScript): $e");
        throw '로그아웃 중 오류가 발생했습니다: $e';
      }
    } else {
      try {
        await auth.signOut();
      } catch (e) {
        print("로그아웃 오류: $e");
        throw '로그아웃 중 오류가 발생했습니다: $e';
      }
    }
  }
  
  /// 비밀번호 재설정
  static Future<void> resetPassword(String email) async {
    try {
      if (kIsWeb && isJSFirebaseInitialized) {
        // JavaScript로 비밀번호 재설정
        js.context.callMethod('resetPasswordJS', [email]);
        
        final result = await _waitForJSResult('resetPasswordResult');
        
        if (result['success'] != true) {
          throw FirebaseAuthException(
            code: result['code'] ?? 'unknown',
            message: result['error'] ?? '비밀번호 재설정 실패',
          );
        }
      } else {
        // Flutter SDK로 비밀번호 재설정
        await auth.sendPasswordResetEmail(email: email);
      }
    } catch (e) {
      print('비밀번호 재설정 오류: $e');
      rethrow;
    }
  }
  
  /// 감정 기록 저장
  static Future<Map<String, dynamic>> saveEmotionRecord(Map<String, dynamic> record) async {
    if (currentUser == null) {
      throw '로그인이 필요합니다.';
    }
    
    if (isWeb && isJSFirebaseInitialized) {
      try {
        final recordStr = jsonEncode(record);
        
        final result = await _callJSFunction(
          'saveEmotionRecordJS',
          [currentUser!.uid, recordStr],
          'saveEmotionResult'
        );
        
        if (result['success'] == true) {
          return {'success': true, 'id': result['id']};
        } else {
          print("감정 기록 저장 오류 (JavaScript): ${result['error']}");
          
          // AdBlock 관련 오류일 가능성이 있는 경우 로컬에 저장
          if (result['error'] != null && 
             (result['error'].toString().contains('ERR_BLOCKED_BY_CLIENT') ||
              result['error'].toString().contains('network error') ||
              result['error'].toString().contains('failed to fetch'))) {
            return await _saveEmotionRecordLocally(record);
          }
          
          throw result['error'] ?? '감정 기록 저장 실패';
        }
      } catch (e) {
        print("감정 기록 저장 오류: $e");
        
        // AdBlock 관련 오류이거나 통신 오류인 경우 로컬에 저장
        if (e.toString().contains('timeout') || 
            e.toString().contains('ERR_BLOCKED_BY_CLIENT') ||
            e.toString().contains('network error') ||
            e.toString().contains('failed to fetch')) {
          return await _saveEmotionRecordLocally(record);
        }
        
        rethrow;
      }
    } else {
      try {
        DocumentReference docRef = await firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('emotions')
            .add(record);
            
        return {'success': true, 'id': docRef.id};
      } catch (e) {
        print("감정 기록 저장 오류 (Firestore): $e");
        
        // 네트워크 오류인 경우 로컬에 저장
        if (e.toString().contains('network') || 
            e.toString().contains('timeout') ||
            e.toString().contains('unavailable')) {
          return await _saveEmotionRecordLocally(record);
        }
        
        throw '감정 기록 저장 중 오류가 발생했습니다: $e';
      }
    }
  }
  
  /// AdBlock이나 네트워크 오류로 인해 Firestore 저장이 실패했을 때 로컬에 저장
  static Future<Map<String, dynamic>> _saveEmotionRecordLocally(Map<String, dynamic> record) async {
    try {
      print("Firebase 저장 실패로 인해 로컬에 감정 기록 저장 시도");
      
      // SharedPreferences 인스턴스 가져오기
      final prefs = await SharedPreferences.getInstance();
      
      // 기존 감정 기록 불러오기
      List<String> jsonRecords = prefs.getStringList('emotion_records') ?? [];
      
      // 레코드에 임의 ID 추가
      String recordId = 'local_${DateTime.now().millisecondsSinceEpoch}_${jsonRecords.length}';
      record['id'] = recordId;
      
      // 새 기록 추가
      jsonRecords.add(jsonEncode(record));
      
      // 저장
      await prefs.setStringList('emotion_records', jsonRecords);
      
      print("감정 기록이 로컬에 성공적으로 저장됨 (ID: $recordId)");
      
      return {'success': true, 'id': recordId, 'local': true};
    } catch (e) {
      print("로컬 저장 오류: $e");
      throw '감정 기록을 로컬에 저장하는 중 오류가 발생했습니다: $e';
    }
  }
  
  /// 모든 감정 기록 가져오기
  static Future<List<Map<String, dynamic>>> getEmotionRecords() async {
    if (currentUser == null) {
      return [];
    }
    
    if (isWeb && isJSFirebaseInitialized) {
      try {
        final result = await _callJSFunction(
          'getEmotionRecordsJS',
          [currentUser!.uid],
          'getEmotionRecordsResult'
        );
        
        if (result['success'] == true) {
          final List<dynamic> records = result['records'] ?? [];
          return records.map((record) => Map<String, dynamic>.from(record)).toList();
        } else {
          print("감정 기록 가져오기 오류: ${result['error']}");
          return [];
        }
      } catch (e) {
        print("감정 기록 가져오기 오류: $e");
        return [];
      }
    } else {
      try {
        final snapshot = await firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('emotions')
            .orderBy('timestamp', descending: true)
            .get();
        
        return snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      } catch (e) {
        print("감정 기록 가져오기 오류: $e");
        return [];
      }
    }
  }
  
  /// 특정 기간 동안의 감정 기록 가져오기
  static Future<List<Map<String, dynamic>>> getEmotionRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    if (currentUser == null) return [];
    
    if (isWeb && isJSFirebaseInitialized) {
      try {
        final startStr = start.toIso8601String();
        final endStr = end.toIso8601String();
        
        final result = await _callJSFunction(
          'getEmotionRecordsByDateRangeJS',
          [currentUser!.uid, startStr, endStr],
          'getEmotionRecordsByDateResult'
        );
        
        if (result['success'] == true) {
          final List<dynamic> records = result['records'] ?? [];
          return records.map((record) => Map<String, dynamic>.from(record)).toList();
        } else {
          print("날짜별 감정 기록 가져오기 오류: ${result['error']}");
          return [];
        }
      } catch (e) {
        print("날짜별 감정 기록 가져오기 오류: $e");
        return [];
      }
    } else {
      try {
        final snapshot = await firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('emotions')
            .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
            .where('timestamp', isLessThanOrEqualTo: end.toIso8601String())
            .orderBy('timestamp', descending: true)
            .get();
        
        return snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      } catch (e) {
        print("날짜별 감정 기록 가져오기 오류: $e");
        return [];
      }
    }
  }
  
  /// 현재 로그인한 사용자 정보 가져오기
  static User? get currentUser {
    if (isWeb && isJSFirebaseInitialized) {
      try {
        final userJson = js.context.callMethod('getCurrentUserJS');
        if (userJson == null) return null;
        
        // JavaScript에서 반환된 JSON을 파싱하여 사용
        final userData = jsonDecode(userJson);
        return _createUserFromJson(userData);
      } catch (e) {
        print("웹 사용자 정보 변환 오류: $e");
        return null;
      }
    } else {
      try {
        return _auth?.currentUser;
      } catch (e) {
        print("현재 사용자 정보 가져오기 오류: $e");
        return null;
      }
    }
  }
  
  /// JavaScript에서 반환된 사용자 데이터로 User 객체 생성
  static User _createUserFromJson(Map<String, dynamic> userData) {
    return _WebUser(
      uid: userData['uid'] ?? '',
      email: userData['email'] ?? '',
      displayName: userData['displayName'],
    );
  }
  
  /// 웹에서 UserCredential 생성
  static UserCredential _createWebUserCredential(Map<String, dynamic> userData) {
    return _WebUserCredential(
      user: _createUserFromJson(userData),
    );
  }

  // 이전 함수 결과 검색
  static Future<Map<String, dynamic>?> _getJSResult(String varName) async {
    try {
      final result = await _waitForJSResult(varName);
      return result;
    } catch (e) {
      print('JS 결과 조회 오류 ($varName): $e');
      return null;
    }
  }
}

/// 웹 환경을 위한 User 구현
class _WebUser implements User {
  @override
  final String uid;
  
  @override
  final String? email;
  
  @override
  final String? displayName;
  
  _WebUser({
    required this.uid,
    this.email,
    this.displayName,
  });
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('지원하지 않는 User 메소드: ${invocation.memberName}');
    return null;
  }
}

/// 웹 환경을 위한 UserCredential 구현
class _WebUserCredential implements UserCredential {
  @override
  final User user;
  
  _WebUserCredential({
    required this.user,
  });
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    print('지원하지 않는 UserCredential 메소드: ${invocation.memberName}');
    return null;
  }
} 