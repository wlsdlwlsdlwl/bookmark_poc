📋 프로젝트 개요

* 목표: 앱 실행 시 시간·위치에 맞춰 미열람 북마크를 추천
* 주요 기능
  시간 기반 추천 (time_recommender.dart)
  위치 기반 추천 (geo_recommender.dart)
  Firestore 로그(logs 컬렉션) 기록 및 추천 갱신
* 구조
  lib/
  ├─ services/                # 추천 로직 (Time / Geo)
  ├─ controllers/             # PoC용 Controller
  ├─ models/                  # Data models
  ├─ views/                   # UI (HomeView, BookmarkListView)
  └─ main.dart                # 앱 시작 및 환경 로드


🔧 초기 설정

1. 레포지토리 클론 및 의존성 설치

2. .env 파일 생성
  프로젝트 루트(예: android/, ios/ 폴더와 동일 위치)에 .env 파일을 생성합니다.
  .env 파일은 notion에 첨부해두었습니다. (https://www.notion.so/seongjxn-lab/PoC-1ee60461f44e801fb87ec29e0989dd3b?pvs=4)

3. pubspec.yaml 에 애셋 등록 확인
  flutter:
    assets:
      - .env    # 환경변수 파일
