# Emotion Control App (감정 조절 앱)

감정을 기록하고 관리하며 감정 조절 퀘스트를 통해 심리적 안정감을 찾을 수 있도록 도와주는 Flutter 애플리케이션입니다.

## 주요 기능

- 감정 기록 및 추적
- 감정별 맞춤형 퀘스트 제공
- 감정 통계 및 분석 리포트
- 감정 태그 시스템
- 경험치 시스템

## 프로젝트 설정

### 사전 요구사항

- Flutter SDK (최신 버전 권장)
- Firebase 계정
- Android Studio 또는 VS Code

### 설치 방법

1. 저장소 클론하기
   ```
   git clone https://github.com/[YOUR_USERNAME]/emotion-control-app.git
   cd emotion-control-app
   ```

2. 종속성 설치
   ```
   flutter pub get
   ```

3. Firebase 설정
   - Firebase 콘솔에서 새 프로젝트 생성
   - Flutter 앱 추가 (Android, iOS, 웹)
   - `firebase_options_template.dart` 파일을 `firebase_options.dart`로 복사하고 Firebase 설정 정보 입력
   - FlutterFire CLI를 사용하여 자동 설정 (선택 사항):
     ```
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

4. 앱 실행
   ```
   flutter run
   ```

## 프로젝트 구조

```
lib/
├── common/         # 공통 상수, 유틸리티 함수
├── models/         # 데이터 모델
├── repositories/   # 데이터 저장소
├── screens/        # UI 화면
├── services/       # 비즈니스 로직
└── main.dart       # 앱 진입점
```

## 기여 방법

1. 이슈 생성 또는 기존 이슈 확인
2. 저장소 포크
3. 기능 브랜치 생성 (`git checkout -b feature/amazing-feature`)
4. 변경사항 커밋 (`git commit -m 'Add some amazing feature'`)
5. 브랜치 푸시 (`git push origin feature/amazing-feature`)
6. Pull Request 생성 