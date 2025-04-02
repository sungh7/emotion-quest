import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emotion_record.dart';
import '../services/firebase_service.dart'; // FirebaseService의 firestore 인스턴스 사용
import 'dart:math';

/// 감정 기록 데이터 저장소
///
/// Firestore와의 직접적인 데이터 통신을 담당합니다.
class EmotionRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'emotion_records';

  // 생성자에서 Firestore 인스턴스 주입 (또는 FirebaseService에서 가져오기)
  EmotionRepository({
    FirebaseFirestore? firestore,
  })
    : _firestore = firestore ?? FirebaseService.firestore;

  /// Firestore에서 감정 기록 목록 가져오기
  ///
  /// [userId] 사용자의 기록만 가져옵니다.
  /// [startDate]와 [endDate]를 사용하여 기간 필터링이 가능합니다.
  Future<List<Map<String, dynamic>>> getEmotionRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 기본 쿼리 구성 - 복합 인덱스를 활용하도록 수정
      Query<Map<String, dynamic>> query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId);

      // 시작 날짜 필터링
      if (startDate != null) {
        // 당일 00:00:00부터 필터링되도록 설정
        final adjustedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(adjustedStartDate));
      }

      // 종료 날짜 필터링 - 두 번째 where 대신 client-side 필터링
      final querySnapshot = await query.orderBy('timestamp', descending: true).get();

      // 결과를 Map 목록으로 변환 (Timestamp -> ISO8601 String 변환 포함)
      List<Map<String, dynamic>> records = querySnapshot.docs.map((doc) {
        final data = doc.data();
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        // ID 필드 추가
        data['id'] = doc.id;
        return data;
      }).toList();

      // 종료 날짜가 있는 경우 클라이언트에서 필터링
      if (endDate != null) {
        final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999).toIso8601String();
        records = records.where((record) => 
          (record['timestamp'] as String).compareTo(adjustedEndDate) <= 0
        ).toList();
      }

      return records;
    } catch (e) {
      print('Error getting emotion records: $e');
      // 예외를 다시 던져서 서비스 레이어에서 처리하도록 할 수 있습니다.
      // throw Exception('감정 기록을 불러오는 데 실패했습니다.');
      return []; // 또는 빈 목록 반환
    }
  }

  /// Firestore에 감정 기록 저장
  /// 
  /// [recordData]는 EmotionRecord.toJson()으로 변환된 Map 형태여야 합니다.
  Future<String?> saveEmotionRecord(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('userId')) {
        print('Error: 감정 기록에 userId가 없습니다.');
        return null;
      }
      
      // 저장 전 데이터 검증 로깅
      print('저장할 감정 기록 데이터: ${data.toString().substring(0, min(100, data.toString().length))}...');
      
      // timestamp를 Firestore Timestamp 객체로 변환
      if (data['timestamp'] is String) {
        try {
          data['timestamp'] = Timestamp.fromDate(DateTime.parse(data['timestamp']));
        } catch (e) {
          print('[EmotionRepository] timestamp 파싱 오류: ${data['timestamp']} - $e');
          // 파싱 오류 시 현재 시간으로 대체 또는 오류 반환
          data['timestamp'] = Timestamp.now(); 
        }
      } else if (data['timestamp'] is DateTime) {
          data['timestamp'] = Timestamp.fromDate(data['timestamp']);
      } else if (data['timestamp'] == null) {
           data['timestamp'] = Timestamp.now();
      }
      // 이미 Timestamp 타입이면 그대로 둠
      
      // 특수 필드 로깅
      print('이미지 URL: ${data['imageUrl']}');
      print('비디오 URL: ${data['videoUrl']}');
      
      // 데이터 저장
      final docRef = await _firestore.collection(_collection).add(data);
      print("[EmotionRepository] 감정 기록 저장 완료: ${docRef.id}");
      return docRef.id; // 저장된 문서 ID 반환
    } catch (e, stackTrace) {
      print('감정 기록 저장 중 심각한 오류: $e');
      print('스택 트레이스: $stackTrace');
      return null; // 저장 실패 시 null 반환
    }
  }
  
  // TODO: 감정 기록 수정 및 삭제 기능 추가 (필요시)
  /*
  Future<void> updateEmotionRecord(String recordId, Map<String, dynamic> updatedData) async { ... }
  Future<void> deleteEmotionRecord(String recordId) async { ... }
  */
} 