import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart'; // Firestore 인스턴스 접근용

/// 퀘스트 데이터 저장소
///
/// Firestore와 퀘스트 진행 데이터 통신을 담당합니다.
class QuestRepository {
  final FirebaseFirestore _firestore;

  // 생성자에서 Firestore 인스턴스 주입
  QuestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  /// Firestore에 퀘스트 진행 상태 저장
  /// 
  /// [userId]는 필수이며, [progressData]는 QuestProgress 모델의 toJson() 결과입니다.
  Future<String?> saveQuestProgress({
    required String userId,
    required Map<String, dynamic> progressData,
  }) async {
    try {
      // questId 필드 확인 (문서 ID 생성에 사용될 수 있음)
      final questId = progressData['questId'];
      if (questId == null || questId.isEmpty) {
        throw ArgumentError('questId가 유효하지 않습니다.');
      }

      // 컬렉션 참조
      final questsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('quest_progress');

      // 문서 ID 생성 (예: questId + timestamp)
      final docId = '${questId}_${DateTime.now().millisecondsSinceEpoch}';

      // Firestore Timestamp로 변환
      if (progressData['startTime'] is String) {
        progressData['startTime'] = Timestamp.fromDate(DateTime.parse(progressData['startTime']));
      } else if (progressData['startTime'] is DateTime) {
         progressData['startTime'] = Timestamp.fromDate(progressData['startTime']);
      }
      
      if (progressData['completionTime'] is String) {
        progressData['completionTime'] = Timestamp.fromDate(DateTime.parse(progressData['completionTime']));
      } else if (progressData['completionTime'] is DateTime) {
         progressData['completionTime'] = Timestamp.fromDate(progressData['completionTime']);
      }

      // 추가 메타데이터
      progressData['savedAt'] = FieldValue.serverTimestamp();
      progressData['userId'] = userId; // 중복 저장될 수 있으나 명시적 확인용

      // 데이터 저장
      await questsRef.doc(docId).set(progressData);
      print("[QuestRepository] 퀘스트 진행 상태 저장 완료: $docId");
      return docId;
    } catch (e) {
      print("[QuestRepository] 퀘스트 진행 상태 저장 오류: $e");
      return null;
    }
  }

  /// Firestore에서 사용자의 퀘스트 진행 기록 로드
  /// 
  /// [userId] 사용자의 기록을 최신순으로 [limit] 개수만큼 가져옵니다.
  Future<List<Map<String, dynamic>>> loadQuestProgress({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final questsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('quest_progress');

      // 최신 기록부터 로드
      final snapshot = await questsRef
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      // 결과 변환 (Timestamp -> ISO8601 String)
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        
        if (data['startTime'] is Timestamp) {
           data['startTime'] = (data['startTime'] as Timestamp).toDate().toIso8601String();
        }
        if (data['completionTime'] is Timestamp) {
           data['completionTime'] = (data['completionTime'] as Timestamp).toDate().toIso8601String();
        }
        if (data['savedAt'] is Timestamp) {
           data['savedAt'] = (data['savedAt'] as Timestamp).toDate().toIso8601String();
        }
        
        return data;
      }).toList();
    } catch (e) {
      print("[QuestRepository] 퀘스트 진행 기록 로드 오류: $e");
      return [];
    }
  }
} 