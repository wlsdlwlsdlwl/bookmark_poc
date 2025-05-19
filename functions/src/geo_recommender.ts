// functions/src/geo_recommender.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as dotenv from "dotenv";
import fetch from "node-fetch";

dotenv.config();
const PLACES_API_URL = "https://places.googleapis.com/v1/places:searchNearby";
const API_KEY = process.env.GOOGLE_PLACES_API_KEY;

// Cloud Function: 장소 기반 북마크 추천
export const geoRecommender = functions.https.onCall(async (data, context) => {
  const { userId, latitude, longitude } = data;
    if (
    typeof userId !== "string" ||
    typeof latitude !== "number" ||
    typeof longitude !== "number"
    ) {
    throw new functions.https.HttpsError("invalid-argument", "userId (string), latitude (number), longitude (number)는 필수입니다.");
    }

  try {
    // 1) 장소 유형 조회
    const placeType = await fetchPrimaryPlaceType(latitude, longitude);

    // 2) logs에서 해당 장소 유형 + 태그 빈도 분석
    const logsSnapshot = await admin.firestore()
      .collection("logs")
      .where("userId", "==", userId)
      .where("location", "==", placeType)
      .get();

    const tagCount: Record<string, number> = {};
    logsSnapshot.forEach(doc => {
      const tags = (doc.get("tags") ?? []) as string[];
      tags.forEach(tag => {
        tagCount[tag] = (tagCount[tag] || 0) + 1;
      });
    });

    if (Object.keys(tagCount).length === 0) {
      return { placeType, recommendations: [] };
    }

    // 3) 가장 많이 사용된 태그 추출
    const topTag = Object.entries(tagCount).reduce((a, b) => a[1] > b[1] ? a : b)[0];

    // 4) 해당 태그 기반, 열람하지 않은 북마크 추천
    const bookmarksSnapshot = await admin.firestore()
      .collection("bookmarks")
      .where("userId", "==", userId)
      .where("tags", "array-contains", topTag)
      .where("wasOpened", "==", false)
      .get();

    const recommendations = bookmarksSnapshot.docs.map(doc => doc.get("title"));
    return { placeType, recommendations };

  } catch (err) {
    console.error("[geoRecommender] 오류:", err);
    throw new functions.https.HttpsError("internal", "추천 처리 중 오류가 발생했습니다.");
  }
});

// Places API 호출 → 장소 유형(한글명) 추출
async function fetchPrimaryPlaceType(lat: number, lng: number): Promise<string> {
  if (!API_KEY) throw new Error("Google Places API 키가 설정되지 않았습니다.");

  const res = await fetch(PLACES_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": API_KEY,
      "X-Goog-FieldMask": "places.primaryTypeDisplayName.text",
    },
    body: JSON.stringify({
      languageCode: "ko",
      maxResultCount: 1,
      locationRestriction: {
        circle: {
          center: { latitude: lat, longitude: lng },
          radius: 50.0,
        },
      },
    }),
  });

  if (!res.ok) {
    console.error("[Places API] 응답 실패:", await res.text());
    return "알 수 없음";
    }
  const json = await res.json();
  return json?.places?.[0]?.primaryTypeDisplayName?.text || "알 수 없음";
}
