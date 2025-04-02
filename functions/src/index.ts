/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onCall} from "firebase-functions/v2/https";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

export const generateAiRecommendation = onCall((request) => {
  // 감정 데이터 분석 및 추천 생성 로직
  const emotion = request.data.emotion;
  const intensity = request.data.intensity || 5;

  // 기본 추천 목록
  const recommendations: Record<string, string[]> = {
    joy: [
      "좋아하는 음악 감상하기",
      "가족이나 친구와 시간 보내기",
      "자연 속에서 산책하기",
    ],
    sadness: [
      "마음을 진정시키는 음악 듣기",
      "일기 쓰기",
      "감정을 표현할 수 있는 그림 그리기",
    ],
    anger: [
      "심호흡하기",
      "운동하기",
      "명상하기",
    ],
    fear: [
      "지지해주는 사람과 대화하기",
      "근육 이완 운동하기",
      "명상 앱 사용하기",
    ],
    disgust: [
      "깨끗한 환경으로 이동하기",
      "좋은 향기 맡기",
      "마음을 환기시키는 활동하기",
    ],
    surprise: [
      "놀라운 일에 대해 일기 쓰기",
      "새로운 정보 찾아보기",
      "명상으로 마음 진정시키기",
    ],
  };

  // 감정에 따른 추천 선택
  const emotionRecommendations = recommendations[emotion] || recommendations.joy;

  // 강도에 따라 다른 추천 제공
  let selectedRecommendation;
  if (intensity <= 3) {
    selectedRecommendation = emotionRecommendations[0];
  } else if (intensity <= 7) {
    selectedRecommendation = emotionRecommendations[1];
  } else {
    selectedRecommendation = emotionRecommendations[2];
  }

  const message = "당신의 " + emotion + " 감정에 맞게 " +
    "\"" + selectedRecommendation + "\"를 추천합니다.";

  return {
    recommendation: selectedRecommendation,
    message,
  };
});
