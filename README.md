# 감정 퀘스트 (Emotion Quest)

감정 퀘스트는 일상 속 감정을 기록하고 분석할 수 있는 Flutter 기반 모바일/웹 애플리케이션입니다.

## 주요 기능

### 1. 감정 기록
- 기본 제공되는 감정(행복, 기쁨, 사랑, 화남, 슬픔, 불안, 무기력, 지루함) 및 사용자 정의 감정 기록
- 감정별 세부 내용 및 다이어리 작성
- **간편 기록**: 감정 일기만 작성해도 감정 기록 저장 가능
- 태그 기능으로 감정에 추가 컨텍스트 부여

### 2. 감정 분석
- 시간별, 요일별 감정 추세 분석
- 월간 캘린더 뷰로 감정 흐름 파악
- 태그별 감정 검색 및 필터링

### 3. 커스터마이징
- 사용자 정의 감정 추가 및 관리
- 사용자 정의 태그 추가 및 관리
- 다크모드 / 라이트모드 전환

### 4. 데이터 관리
- Firebase를 통한 사용자 데이터 저장 및 동기화
- 사용자 인증으로 개인 데이터 보호

### 5. 키보드 단축키
- **로그인/회원가입**: 이메일 입력 후 Enter 키로 비밀번호 필드로 자동 이동, 비밀번호 입력 후 Enter 키로 자동 제출
- **감정 기록**: 감정 설명 작성 후 Enter 키로 다음 필드로 이동, Shift+Enter로 줄바꿈, Ctrl+S로 저장
- **태그 관리**: Enter 키로 새 태그 추가, 태그 추가 후 자동으로 다음 입력 준비
- **태그 검색**: Enter 키로 검색 실행, 태그 칩 선택으로 빠른 필터링
- **사용자 정의 감정**: 감정 이름 입력 후 Enter 키로 이모지 필드로 이동, 이모지 입력 후 Enter 키로 자동 추가

## 최근 업데이트

### 2023년 8월
- 사용자 정의 태그 기능 추가
- 감정 기록 시 태그 선택 기능 추가
- 태그 관리 화면 추가

### 2023년 9월
- 감정 기록 저장 기능 개선: 감정 설명이 없어도 감정 일기만 작성하거나 태그만 선택해도 저장 가능
- 웹 버전 로딩 속도 개선
- 다크 모드 UI 개선

## 기술 스택

- **프레임워크**: Flutter
- **언어**: Dart
- **백엔드**: Firebase (Authentication, Firestore, Hosting)
- **상태 관리**: Provider
- **차트 시각화**: fl_chart
- **캘린더**: table_calendar

## 설치 및 실행

### 요구사항
- Flutter 3.0 이상
- Firebase 계정
- Firebase CLI

### 설치 방법

1. 저장소 클론
```
git clone https://github.com/yourusername/emotion_control.git
cd emotion_control/emotion_control
```

2. 의존성 설치
```
flutter pub get
```

3. 앱 실행
```
flutter run
```

### 웹 배포
```
flutter build web
firebase deploy --only hosting
```

## 프로젝트 구조

```
lib/
├── main.dart             # 앱 진입점
├── models/               # 데이터 모델
│   └── emotion_record.dart
├── screens/              # 화면 UI
│   ├── auth_screen.dart
│   ├── custom_emotion_screen.dart
│   ├── emotion_detail_screen.dart
│   ├── home_screen.dart
│   ├── report_screen.dart
│   └── tag_management_screen.dart
├── services/             # 비즈니스 로직 및 API
│   ├── emotion_service.dart
│   ├── firebase_service.dart
│   └── theme_service.dart
└── widgets/              # 재사용 가능한 UI 컴포넌트
    └── emotion_button.dart
```

## 라이선스

MIT 라이선스

## 데모

웹 데모: [https://emotionalquest.web.app](https://emotionalquest.web.app)
