import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'game_service.dart';
import 'dart:typed_data';

/// Firebase 서비스
///
/// Firebase 관련 기능을 중앙에서 관리하는 서비스 클래스입니다.
class FirebaseService {
  // Firestore 인스턴스
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Firebase Auth 인스턴스
  static final FirebaseAuth auth = FirebaseAuth.instance;
  
  // Firebase Storage 인스턴스
  static final FirebaseStorage storage = FirebaseStorage.instance;
  
  // 현재 로그인한 사용자
  static User? get currentUser => auth.currentUser;
  
  /// Firebase 초기화
  static Future<void> initializeFirebase() async {
    // 필요한 경우 추가 초기화 작업 수행
    print('Firebase 서비스 초기화 완료');
  }
  
  /// 이메일/비밀번호로 로그인
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('로그인 오류: $e');
      rethrow;
    }
  }
  
  /// 이메일/비밀번호로 회원가입
  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      final result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }
  
  /// 로그아웃
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      
      // 참고: 이 방법은 직접적인 Provider 호출이 아니라 
      // 필요한 곳에서 GameService 인스턴스를 별도로 가져와야 합니다.
      // 일반적으로는 context를 통해 Provider에 접근하는 것이 좋습니다.
      print('로그아웃 성공: 사용자가 로그아웃되었습니다.');
    } catch (e) {
      print('로그아웃 오류: $e');
      rethrow;
    }
  }
  
  // context를 받아 로그아웃하는 확장 메서드
  static Future<void> signOutAndResetData(BuildContext context) async {
    try {
      // 먼저, GameService에서 상태 리셋
      final gameService = Provider.of<GameService>(context, listen: false);
      await gameService.resetUserStats();
      
      // 그 다음 로그아웃
      await auth.signOut();
      
      print('로그아웃 성공: 사용자 상태가 초기화되었습니다.');
    } catch (e) {
      print('로그아웃 및 상태 초기화 오류: $e');
      rethrow;
    }
  }
  
  /// 비밀번호 재설정 이메일 발송
  static Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }
  
  /// 사용자 프로필 업데이트
  static Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }
  
  /// Firestore에서 문서 가져오기
  static Future<DocumentSnapshot> getDocument(String collection, String documentId) async {
    return await firestore.collection(collection).doc(documentId).get();
  }
  
  /// Firestore 문서 저장
  static Future<void> setDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(documentId).set(data);
  }
  
  /// Firestore 문서 업데이트
  static Future<void> updateDocument(String collection, String documentId, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(documentId).update(data);
  }
  
  /// Firestore 문서 삭제
  static Future<void> deleteDocument(String collection, String documentId) async {
    await firestore.collection(collection).doc(documentId).delete();
  }
  
  /// Firestore 컬렉션 데이터 가져오기 (필터링 가능)
  static Future<List<Map<String, dynamic>>> getCollection(
    String collection, {
    String? queryField,
    dynamic queryValue,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      // 쿼리 빌드
      Query query = firestore.collection(collection);
      
      // 필터 조건 추가
      if (queryField != null && queryValue != null) {
        query = query.where(queryField, isEqualTo: queryValue);
      }
      
      // 정렬 조건 추가
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // 결과 개수 제한
      if (limit != null) {
        query = query.limit(limit);
      }
      
      // 쿼리 실행
      final querySnapshot = await query.get();
      
      // 결과 변환
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList();
    } catch (e) {
      print('Firestore 컬렉션 조회 오류: $e');
      return [];
    }
  }
  
  /// Storage에 파일 업로드
  static Future<String> uploadFile(String path, dynamic file) async {
    final ref = storage.ref().child(path);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
  
  /// Storage에 바이트 배열 업로드 (웹 환경용)
  static Future<String> uploadFileBytes(String path, Uint8List bytes) async {
    try {
      final ref = storage.ref().child(path);
      
      // 메타데이터 설정 (선택사항)
      final metadata = SettableMetadata(
        contentType: 'application/octet-stream', // 또는 적절한 MIME 타입
        customMetadata: {'uploaded-by': 'emotion-control-app'},
      );
      
      // 바이트 배열 업로드
      final uploadTask = await ref.putData(bytes, metadata);
      
      // 다운로드 URL 반환
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('바이트 배열 업로드 성공: $path');
      return downloadUrl;
    } catch (e) {
      print('바이트 배열 업로드 오류: $e');
      throw e; // 오류 전파
    }
  }
  
  /// 퀘스트 진행 상황 저장
  static Future<bool> saveQuestProgress(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      // 경로를 loadQuestProgress와 일치시킴: users/{userId}/quest_progress
      final collectionRef = firestore
          .collection('users')
          .doc(user.uid)
          .collection('quest_progress');
      
      // 문서 ID가 지정되어 있으면 해당 문서 업데이트, 없으면 새 문서 생성
      if (data.containsKey('id') && data['id'] != null) {
        final docId = data['id'];
        await collectionRef.doc(docId).set(data, SetOptions(merge: true));
      } else {
        final docRef = await collectionRef.add(data);
        print('퀘스트 진행 저장 완료: ${docRef.id}');
      }
      
      return true;
    } catch (e) {
      print('퀘스트 진행 상황 저장 오류: $e');
      return false;
    }
  }
  
  /// 퀘스트 진행 상황 불러오기
  static Future<List<Map<String, dynamic>>> loadQuestProgress() async {
    try {
      final user = currentUser;
      if (user == null) return [];
      
      // users/{userId}/quest_progress 컬렉션에서 데이터 가져오기
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('quest_progress')
          .orderBy('startTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Timestamp를 ISO 문자열로 변환
        if (data['startTime'] is Timestamp) {
          data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
        }
        if (data['completionTime'] is Timestamp) {
          data['completionTime'] = (data['completionTime'] as Timestamp).toDate().toIso8601String();
        }
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList();
    } catch (e) {
      print('퀘스트 진행 상황 로드 오류: $e');
      return [];
    }
  }
  
  /// 디지털 웰빙 데이터 저장
  static Future<Map<String, dynamic>> saveDigitalWellbeingData(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) return {'success': false};
      
      final docRef = firestore.collection('wellbeing_data').doc(user.uid);
      await docRef.set(data, SetOptions(merge: true));
      return {'success': true, 'id': user.uid};
    } catch (e) {
      print('디지털 웰빙 데이터 저장 오류: $e');
      return {'success': false};
    }
  }
  
  /// 사용자 필드 업데이트 (필드 값 업데이트 연산 지원)
  Future<void> updateUserField(String userId, String field, dynamic value) async {
    try {
      await firestore.collection('users').doc(userId).update({
        field: value
      });
      print('사용자 필드 업데이트 성공: $field');
    } catch (e) {
      print('사용자 필드 업데이트 오류: $e');
      throw e;
    }
  }
} 