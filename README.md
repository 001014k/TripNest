<!-- 헤더 배너: 더 크고 반짝이는 효과로 시선 강탈 -->
![header](https://capsule-render.vercel.app/api?type=waving&color=gradient&height=140&section=header&text=%F0%9F%8C%8D%20TripNest&animation=twinkling&fontSize=50&fontColor=white)

<!-- 방문자 카운트 -->
<p align="center">
  <img src="https://komarev.com/ghpvc/?username=001014k&style=flat-square&color=blue" alt="Profile views" />
</p>

<!-- 첫인상 핵심: 큰 제목 + 강렬한 카피 + 대표 스크린샷 6개 -->
<h1 align="center">📱 TripNest</h1>
<h3 align="center"><strong>지도 위에 나의 여행을 그리다 — 실시간으로 친구와 함께</strong></h3>

<p align="center">
  <img src="https://github.com/user-attachments/assets/43f10e13-c8e1-42fd-84ce-ce7a0d53fd79" width="18%" />
  <img src="https://github.com/user-attachments/assets/b958e800-e5d3-4247-8926-1b5054a2fded" width="18%" />
  <img src="https://github.com/user-attachments/assets/103d1964-0977-430f-a5cc-744f1fe9255e" width="18%" />
  <img src="https://github.com/user-attachments/assets/fe766f95-df61-482f-b85d-c154dd35195d" width="18%" />
  <img src="https://github.com/user-attachments/assets/7f7cc537-7751-47f2-965f-ca903669aea1" width="18%" />
  <img src="https://github.com/user-attachments/assets/75a5381c-a821-4f6e-99ff-d4be42e3c267" width="18%" />
</p>

<p align="center">
  <strong style="font-size:1.2em;">
    여행 중 떠오른 그 장소, 더 이상 메모에 흩어지지 않게 해드릴게요.<br>
    친구와 실시간으로 함께 그리고, AI가 숨은 명소까지 추천해드려요.
  </strong>
</p>

<hr>

### 🚀 지금 TripNest는…
- **개발 완료 단계** — 최종 폴리싱, 성능 최적화, Gemini AI 통합 마무리 중
- **2026년 3월 App Store 정식 출시 예정** (현재 TestFlight 베타 배포 중)
- **Jenkins + Fastlane CI/CD 완전 자동화** — 빌드 → 테스트 → TestFlight 업로드까지 무인 배포 가능

### ✨ 이런 순간을 위해 만들었어요
| 당신의 여행 고민                          | TripNest가 해결해요                                                                 |
|-------------------------------------------|-------------------------------------------------------------------------------------|
| 가고 싶은 곳이 메모, 카톡, 노트에 흩어져서 다시 찾기 힘들어요 | 지도 위에 직관적으로 마커 찍기 + 북마크 + 한눈에 리스트 관리                        |
| 친구와 일정 공유할 때 스크린샷 주고받기 번거로워요 | Supabase Realtime으로 **동시 편집** · 초대 · 변경 즉시 반영 (실시간 협업 리스트)   |
| 숨은 맛집·명소는 어떻게 찾죠?             | (개발 중) Gemini AI가 사용자 취향·위치 기반으로 숨은 명소 추천                     |
| 저장한 인스타·유튜브 링크 어디 갔지?      | 외부 링크(Instagram, YouTube 등) 바로 저장 → 마커에 연결 → 클릭 시 바로 열기       |
| 길찾기는 또 별도 앱 켜야 하나요?         | 마커 클릭 한 번으로 Google·Kakao·Naver 지도 중 원하는 앱으로 즉시 길 안내         |

### 🔍 기능 상세 소개
#### 1. 지도 기반 마커 & 북마크 관리
- Google Maps, Kakao Maps, Naver Maps **다중 지원** (사용자 설정에서 선택 가능)
- 마커 등록: 장소 검색 → 핀 찍기 → 메모·사진·링크 추가
- **클러스터링** 적용: 마커 많아져도 지도 깨끗하게
- 북마크: 좋아하는 장소 따로 저장 → 나의 컬렉션처럼 관리

#### 2. 실시간 친구 협업 (Supabase Realtime 핵심)
- 친구 초대 → 공유 리스트 생성
- **동시 편집**: 한 명이 마커 추가/수정/삭제 → 다른 친구 화면에 즉시 반영 (지연 거의 없음)
- 변경 히스토리 간단 표시 (누가 언제 무엇을 바꿨는지)

#### 3. 외부 링크 저장 & 연결
- Instagram 게시물, YouTube 영상, 웹사이트 등 URL 입력 → 자동으로 마커에 붙임
- 마커 클릭 시 링크 목록 팝업 → 바로 브라우저/앱 열기

#### 4. Gemini AI 추천 (개발 중 → 곧 완성)
- 사용자 입력 (취향, 테마, 위치) 기반으로 주변 숨은 명소·맛집 추천
- 추천 결과 → 한 번에 마커로 추가 가능

#### 5. 성능 & 사용자 경험 최적화
- **cached_network_image** 도입 → 이미지 로딩 깜빡임 완전 제거 + 오프라인 캐싱 지원
- const 위젯 적극 활용 + 불필요 리빌드 최소화
- 다크/라이트 모드 완벽 지원

### 🛠️ 아키텍처 & 기술 스택
- **Flutter + Dart** (크로스플랫폼: Android, iOS, Web, Desktop 지원)
- **상태 관리**: Provider (MVVM 패턴 기반 클린 아키텍처)
- **백엔드**:
  - 초기: Firebase (Authentication, Hosting, Firestore) → 빠른 프로토타이핑
  - 전환: Supabase (PostgreSQL + Realtime) → 관계형 데이터(리스트-마커-친구) 관리 용이, 복잡한 쿼리·데이터 흐름 파악 쉬움, 실시간 기능 강화
- **지도 API**: Google Maps Flutter + Kakao/Naver 링크 연동
- **CI/CD**: Jenkins 파이프라인 + Fastlane → iOS 빌드·TestFlight 자동 업로드
- **기타**: analysis_options.yaml 린팅, unit/widget 테스트 폴더 존재

### 📲 직접 실행해보기
<p align="center">
  <a href="https://testflight.apple.com/join/wP415NqW">
    <img src="https://img.shields.io/badge/TestFlight-베타%20체험하기-000000?style=for-the-badge&logo=apple&logoColor=white" alt="TestFlight" />
  </a>
</p>

**피드백 언제든 환영합니다!** 🚀  
App Store 출시 후에도 지속 업데이트 예정입니다.
