// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart'; // @GenerateMocks 제거
import 'package:fake_async/fake_async.dart'; // 비동기 테스트를 위해
import 'package:cloud_firestore/cloud_firestore.dart';

// 테스트 대상 클래스 임포트
import 'package:emotion_control/models/user_stats.dart';
import 'package:emotion_control/repositories/user_repository.dart';

// Mock 클래스 임포트 제거
// import 'user_repository_test.mocks.dart';

// Firestore 모킹을 위한 수동 Mock 클래스 정의 (기존 것 사용)
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

// Mockito 코드 생성을 위한 어노테이션 제거
/*
@GenerateMocks([
  MockFirebaseFirestore,
  MockCollectionReference,
  MockDocumentReference,
  MockDocumentSnapshot
])
*/
void main() {
  // Mock 객체 선언
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDocument;
  late MockDocumentSnapshot mockDocumentSnapshot;
  late UserRepository userRepository;

  // 각 테스트 전에 실행될 설정
  setUp(() {
    // Mock 객체 초기화
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDocument = MockDocumentReference();
    mockDocumentSnapshot = MockDocumentSnapshot();
    
    // UserRepository에 Mock Firestore 주입
    userRepository = UserRepository(firestore: mockFirestore);

    // Firestore 메서드 호출 시 Mock 객체 반환 설정
    when(mockFirestore.collection(any)).thenReturn(mockUsersCollection);
    when(mockUsersCollection.doc(any)).thenReturn(mockUserDocument);
  });

  group('UserRepository Tests (No Build Runner)', () {
    const testUserId = 'testUserId';
    final testUserStats = UserStats(level: 2, experience: 50, recordCount: 10, completedQuests: 3);
    final testUserStatsJson = testUserStats.toJson();
    // Firestore 저장을 위해 Timestamp 변환 필요
    final firestoreTimestamp = Timestamp.fromMillisecondsSinceEpoch(testUserStatsJson['lastRecordDate']);
    final testUserStatsFirestoreJson = {
      ...testUserStatsJson,
      'lastRecordDate': firestoreTimestamp,
    };
    
    test('getUserStats - 데이터가 있을 때 UserStats 객체 반환', () async {
      // Arrange
      when(mockDocumentSnapshot.exists).thenReturn(true);
      when(mockDocumentSnapshot.data()).thenReturn(testUserStatsFirestoreJson);
      when(mockUserDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

      // Act
      final result = await userRepository.getUserStats(testUserId);

      // Assert
      expect(result, isA<UserStats>());
      expect(result?.level, testUserStats.level);
      expect(result?.experience, testUserStats.experience);
      expect(result?.lastRecordDate.millisecondsSinceEpoch, testUserStats.lastRecordDate.millisecondsSinceEpoch);
      
      // Verify
      verify(mockFirestore.collection('users')).called(1);
      verify(mockUsersCollection.doc(testUserId)).called(1);
      verify(mockUserDocument.get()).called(1);
    });

    test('getUserStats - 데이터가 없을 때 null 반환', () async {
      // Arrange
      when(mockDocumentSnapshot.exists).thenReturn(false);
      // when(mockDocumentSnapshot.data()).thenReturn(null); // 데이터 없을 때 data() 호출 시 null 반환 명시 (옵션)
      when(mockUserDocument.get()).thenAnswer((_) async => mockDocumentSnapshot);

      // Act
      final result = await userRepository.getUserStats(testUserId);

      // Assert
      expect(result, isNull);
      
      // Verify
      verify(mockUserDocument.get()).called(1);
    });
    
    test('getUserStats - Firestore 오류 발생 시 null 반환', () async {
      // Arrange
      when(mockUserDocument.get()).thenThrow(FirebaseException(plugin: 'firestore', message: 'Test error'));

      // Act
      final result = await userRepository.getUserStats(testUserId);

      // Assert
      expect(result, isNull);
    });

    test('saveUserStats - Firestore set 메서드 호출 확인', () async {
      // Arrange
      when(mockUserDocument.set(any)).thenAnswer((_) async {}); 

      // Act
      await userRepository.saveUserStats(testUserId, testUserStats);

      // Assert
      final captured = verify(mockUserDocument.set(captureAny)).captured;
      expect(captured.length, 1);
      final capturedData = captured.first as Map<String, dynamic>;
      
      expect(capturedData['level'], testUserStats.level);
      expect(capturedData['experience'], testUserStats.experience);
      expect(capturedData['lastRecordDate'], isA<Timestamp>());
      expect((capturedData['lastRecordDate'] as Timestamp).millisecondsSinceEpoch, testUserStats.lastRecordDate.millisecondsSinceEpoch);
      expect(capturedData.containsKey('updatedAt'), isTrue); 
    });
    
    test('saveUserStats - Firestore 오류 발생 시 예외 처리 확인', () async {
      // Arrange
      when(mockUserDocument.set(any)).thenThrow(FirebaseException(plugin: 'firestore', message: 'Save error'));
      
      // Act & Assert
      expectLater(() async => await userRepository.saveUserStats(testUserId, testUserStats), returnsNormally);
    });
  });
} 