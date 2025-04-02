import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_stats.dart';
import '../services/firebase_service.dart'; // Firestore 인스턴스 접근용

/// 사용자 데이터 저장소
///
/// Firestore와 사용자 통계(UserStats) 데이터 통신을 담당합니다.
class UserRepository {
  final FirebaseFirestore _firestore;

  // 생성자에서 Firestore 인스턴스 주입
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  /// Firestore에서 사용자 통계 데이터 로드
  /// 
  /// [userId] 사용자의 통계 데이터를 가져옵니다.
  /// 데이터가 없으면 null을 반환합니다.
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        // Firestore Timestamp를 DateTime으로 변환
        if (data['lastRecordDate'] is Timestamp) {
          data['lastRecordDate'] = (data['lastRecordDate'] as Timestamp).toDate().millisecondsSinceEpoch;
        }
        return UserStats.fromJson(data);
      } else {
        print("[UserRepository] 사용자($userId) 통계 데이터 없음");
        return null; // 데이터가 없으면 null 반환
      }
    } catch (e) {
      print("[UserRepository] 사용자 통계 로드 오류: $e");
      return null; // 오류 발생 시 null 반환
    }
  }

  /// Firestore에 사용자 통계 데이터 저장 또는 업데이트
  /// 
  /// [userId] 사용자의 통계 데이터를 저장합니다.
  /// 기존 데이터가 있으면 덮어씁니다.
  Future<void> saveUserStats(String userId, UserStats stats) async {
    try {
      final docRef = _firestore.collection('users').doc(userId);
      final dataToSave = stats.toJson();
      
      // DateTime을 Firestore Timestamp로 변환
      if (dataToSave['lastRecordDate'] is int) {
         dataToSave['lastRecordDate'] = Timestamp.fromMillisecondsSinceEpoch(dataToSave['lastRecordDate']);
      } else if (dataToSave['lastRecordDate'] == null) {
         // lastRecordDate가 null이면 Firestore에서도 null로 저장되도록 함
         // 또는 기본값 설정: dataToSave['lastRecordDate'] = Timestamp.now();
      }
      
      // 메타데이터 추가 (예: 업데이트 시간)
      dataToSave['updatedAt'] = FieldValue.serverTimestamp();
      
      // 데이터 저장 (set 사용, merge는 필요 없음 - 전체 덮어쓰기)
      await docRef.set(dataToSave);
      print("[UserRepository] 사용자($userId) 통계 저장 완료");
    } catch (e) {
      print("[UserRepository] 사용자 통계 저장 오류: $e");
      // 오류 처리 (예: 예외 다시 던지기)
      // throw Exception('사용자 통계를 저장하는 데 실패했습니다.');
    }
  }
} 