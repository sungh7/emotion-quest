import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class UserService {
  // 싱글톤 패턴 적용
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 현재 로그인한 사용자 정보 가져오기
  Future<User?> getCurrentUser() async {
    try {
      final auth = FirebaseService.currentUser;
      if (auth == null) return null;
      
      final doc = await _firestore.collection('users').doc(auth.uid).get();
      if (!doc.exists) return null;
      
      return User.fromJson({
        'id': auth.uid,
        ...doc.data() as Map<String, dynamic>
      });
    } catch (e) {
      print('사용자 정보 가져오기 실패: $e');
      return null;
    }
  }
  
  // 사용자 정보 업데이트
  Future<bool> updateUserInfo({
    required String userId,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (displayName != null) data['displayName'] = displayName;
      if (photoURL != null) data['photoURL'] = photoURL;
      if (preferences != null) data['preferences'] = preferences;
      
      if (data.isEmpty) return true; // 변경사항이 없으면 성공으로 간주
      
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('사용자 정보 업데이트 실패: $e');
      return false;
    }
  }
  
  // 경험치와 레벨 업데이트 (트랜잭션 사용)
  Future<bool> updateExperience(String userId, int expPoints) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _firestore.collection('users').doc(userId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('사용자 문서가 존재하지 않습니다.');
        }
        
        final currentExp = snapshot.data()?['experience'] as int? ?? 0;
        final currentLevel = snapshot.data()?['level'] as int? ?? 1;
        
        int newExp = currentExp + expPoints;
        int newLevel = currentLevel;
        
        // 레벨업 로직 (간단한 예: 100점마다 레벨업)
        while (newExp >= 100) {
          newExp -= 100;
          newLevel++;
        }
        
        transaction.update(docRef, {
          'experience': newExp,
          'level': newLevel,
        });
      });
      
      return true;
    } catch (e) {
      print('경험치/레벨 업데이트 실패: $e');
      return false;
    }
  }
  
  // 완료한 퀘스트 추가
  Future<bool> addCompletedQuest(String userId, String questId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'completedQuests': FieldValue.arrayUnion([questId]),
      });
      return true;
    } catch (e) {
      print('완료한 퀘스트 추가 실패: $e');
      return false;
    }
  }
  
  // 새 사용자 프로필 생성 (회원가입 시)
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? photoURL,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'displayName': displayName,
        'photoURL': photoURL,
        'level': 1,
        'experience': 0,
        'completedQuests': [],
        'preferences': {},
        'metadata': {},
        'createdAt': now,
        'lastLogin': now,
      });
      
      return true;
    } catch (e) {
      print('사용자 프로필 생성 실패: $e');
      return false;
    }
  }
  
  // 마지막 로그인 시간 업데이트
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('마지막 로그인 시간 업데이트 실패: $e');
    }
  }
} 