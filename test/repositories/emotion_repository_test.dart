import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emotion_control/models/emotion_record.dart';
import 'package:emotion_control/repositories/emotion_repository.dart';
import 'emotion_repository_test.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<FirebaseFirestore>(),
  MockSpec<CollectionReference<Map<String, dynamic>>>(
    as: #MockCollectionReference,
  ),
  MockSpec<DocumentReference<Map<String, dynamic>>>(
    as: #MockDocumentReference,
  ),
  MockSpec<DocumentSnapshot<Map<String, dynamic>>>(
    as: #MockDocumentSnapshot,
  ),
  MockSpec<Query<Map<String, dynamic>>>(
    as: #MockQuery,
  ),
  MockSpec<QuerySnapshot<Map<String, dynamic>>>(
    as: #MockQuerySnapshot,
  ),
  MockSpec<QueryDocumentSnapshot<Map<String, dynamic>>>(
    as: #MockQueryDocumentSnapshot,
  ),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockQuery mockQuery;
  late MockQuerySnapshot mockQuerySnapshot;
  late EmotionRepository emotionRepository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockQuery = MockQuery();
    mockQuerySnapshot = MockQuerySnapshot();
    emotionRepository = EmotionRepository(firestore: mockFirestore);
  });

  group('EmotionRepository Tests', () {
    const testUserId = 'testUserId';
    final testTimestamp = DateTime.now();
    final testEmotionRecord = EmotionRecord(
      emotion: '기쁨',
      emoji: '😊',
      timestamp: testTimestamp,
      details: '테스트 감정 기록',
      userId: testUserId,
      tags: ['업무', '성취'],
      isCustomEmotion: false,
    );

    test('getEmotionRecords - 기본 조회 테스트', () async {
      // Arrange
      final mockDoc = MockQueryDocumentSnapshot();
      final testData = testEmotionRecord.toJson();
      testData['timestamp'] = Timestamp.fromDate(testTimestamp);

      when(mockFirestore.collection('emotion_records')).thenReturn(mockCollection);
      when(mockCollection.where('userId', isEqualTo: testUserId))
          .thenReturn(mockQuery);
      when(mockQuery.orderBy('timestamp', descending: true))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
      when(mockDoc.data()).thenReturn(testData);
      when(mockDoc.id).thenReturn('testDocId');

      // Act
      final result = await emotionRepository.getEmotionRecords(userId: testUserId);

      // Assert
      expect(result.length, 1);
      expect(result[0]['emotion'], '기쁨');
      expect(result[0]['emoji'], '😊');
      expect(result[0]['id'], 'testDocId');
      expect(result[0]['tags'], ['업무', '성취']);

      // Verify
      verify(mockFirestore.collection('emotion_records')).called(1);
      verify(mockCollection.where('userId', isEqualTo: testUserId)).called(1);
      verify(mockQuery.orderBy('timestamp', descending: true)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('getEmotionRecords - 날짜 필터링 테스트', () async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 12, 31);
      final startTimestamp = Timestamp.fromDate(startDate);
      final adjustedEndDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      final endTimestamp = Timestamp.fromDate(adjustedEndDate);
      
      when(mockFirestore.collection('emotion_records')).thenReturn(mockCollection);
      when(mockCollection.where('userId', isEqualTo: testUserId))
          .thenReturn(mockQuery);
      when(mockQuery.orderBy('timestamp', descending: true))
          .thenReturn(mockQuery);
      when(mockQuery.where('timestamp', isGreaterThanOrEqualTo: startTimestamp))
          .thenReturn(mockQuery);
      when(mockQuery.where('timestamp', isLessThanOrEqualTo: endTimestamp))
          .thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs).thenReturn([]);

      // Act
      final result = await emotionRepository.getEmotionRecords(
        userId: testUserId,
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(result, isEmpty);

      // Verify
      verifyInOrder([
        mockFirestore.collection('emotion_records'),
        mockCollection.where('userId', isEqualTo: testUserId),
        mockQuery.orderBy('timestamp', descending: true),
        mockQuery.where('timestamp', isGreaterThanOrEqualTo: startTimestamp),
        mockQuery.where('timestamp', isLessThanOrEqualTo: endTimestamp),
        mockQuery.get(),
      ]);
    });

    test('saveEmotionRecord - 성공 케이스', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final testData = testEmotionRecord.toJson();

      when(mockFirestore.collection('emotion_records')).thenReturn(mockCollection);
      when(mockCollection.add(argThat(isA<Map<String, dynamic>>()))).thenAnswer((_) async => mockDocRef);
      when(mockDocRef.id).thenReturn('newDocId');

      // Act
      final result = await emotionRepository.saveEmotionRecord(testData);

      // Assert
      expect(result, 'newDocId');

      // Verify
      verify(mockCollection.add(argThat(isA<Map<String, dynamic>>()))).called(1);
    });

    test('saveEmotionRecord - userId 누락 시 실패', () async {
      // Arrange
      final invalidData = Map<String, dynamic>.from(testEmotionRecord.toJson())
        ..remove('userId');

      when(mockFirestore.collection('emotion_records')).thenReturn(mockCollection);

      // Act
      final result = await emotionRepository.saveEmotionRecord(invalidData);

      // Assert
      expect(result, isNull);

      // Verify
      verifyNever(mockCollection.add(argThat(isA<Map<String, dynamic>>())));
    });

    test('saveEmotionRecord - Firestore 오류 발생 시 null 반환', () async {
      // Arrange
      final testData = testEmotionRecord.toJson();

      when(mockFirestore.collection('emotion_records')).thenReturn(mockCollection);
      when(mockCollection.add(argThat(isA<Map<String, dynamic>>()))).thenThrow(
        FirebaseException(plugin: 'firestore', message: 'Test error')
      );

      // Act
      final result = await emotionRepository.saveEmotionRecord(testData);

      // Assert
      expect(result, isNull);
    });
  });
} 