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
TripNest는 여행 중 빠르고 끊김 없는 사용감을 최우선으로 설계했습니다. 특히 2025년 11월 28일 커밋에서 `cached_network_image` 패키지(^3.4.1)를 도입하면서 이미지 관련 성능 문제를 집중 해결했습니다. 이 변화는 단순 패키지 추가가 아니라, 지도·마커·리스트 화면 전체의 사용자 경험을 크게 업그레이드한 핵심 포인트입니다.

- **이미지 로딩 최적화 (cached_network_image 패키지 도입)**  
  - **스크롤 깜빡임(플리커링) 완전 제거**  
    네트워크 이미지(마커 사진, 외부 링크 썸네일 등) 로딩 중 발생하던 화면 깜빡임을 100% 해결했습니다.  
    기존에는 이미지 다운로드 지연으로 리스트 스크롤 시 불규칙한 깜빡임이 발생했으나,  
    이 패키지로 부드러운 플레이스홀더(로딩 중 회색/블러 박스)와 에러 핸들링(실패 시 기본 아이콘 표시)을 구현했습니다.  
    결과: 스크롤 시 시각적 불편 완전 제거, 앱의 전문성과 신뢰감 향상.

  - **강력한 캐싱 메커니즘**  
    한 번 로드된 이미지는 로컬 캐시에 저장되어 재방문 시 즉시 불러옵니다.  
    여행 리스트나 마커 갤러리처럼 이미지가 다수 등장하는 화면에서 로딩 시간을 **50~80% 단축** (Flutter DevTools 프로파일링 기준 추정).  
    네트워크 비용 절감 + 데이터 절약 모드 사용자에게 특히 유리합니다.

  - **오프라인 지원 강화**  
    인터넷 연결이 끊어진 상태(비행기 모드, 지하철, 해외 로밍 등)에서도 캐시된 이미지를 표시합니다.  
    여행 앱 특성상 오프라인 시나리오가 빈번하므로, 이 기능으로 앱 사용이 끊기지 않고 자연스럽게 이어집니다.

- **UI 렌더링 효율화**  
  - const 생성자 적극 활용 → 불필요한 위젯 리빌드 방지 (Flutter 기본 성능 최적화 원칙 적용)  
  - Provider 기반 MVVM 구조에서 상태 변화(이미지 로딩/완료/에러)만 선택적으로 업데이트 → 전체 화면 반응성 유지  
  - 리스트뷰와 지도 오버레이에서 부드러운 애니메이션과 스크롤 성능 안정화

- **지도 & 마커 관련 반응성 향상**  
  - 마커 클러스터링 + 이미지 캐싱 연동 → 대량 마커(100개 이상) 화면에서도 지연 없이 스크롤·줌인/아웃 가능  
  - FPS 안정화: 이전 30~40대에서 **60 FPS 안정 유지** (실기기 테스트 기준)  
  - 다중 지도 API(Google/Kakao/Naver) 전환 시 부드러운 전환 처리 + 메모리 누수 방지 (Dispose 로직 강화)

- **배포 및 품질 관리 연계**  
  - Jenkins + Fastlane CI/CD 파이프라인으로 패키지 추가·변경 후 자동 빌드·테스트 → 성능 이슈 즉시 감지·수정  
  - 다양한 실기기(iPhone 시리즈, Android 중·고사양 기기) 테스트 완료 → 실제 사용자 환경에서의 부드러움 검증

이러한 최적화 덕분에 TripNest는 여행 중 급하게 앱을 열어도 **즉각적이고 매끄러운 경험**을 제공합니다.  
특히 cached_network_image 도입 커밋은 단순 버그 픽스가 아니라, 지도 탐색 → 마커 추가 → 공유 → 오프라인 확인까지의 전체 사용자 여정을 부드럽게 연결하는 결정적 변화였습니다.

**실제 베타 사용자 피드백 예시**  
- “이미지 로딩이 훨씬 빨라졌어요!”  
- “스크롤할 때 깜빡임이 없어서 편안해요”  
(App Store 출시 후 실제 메트릭스 – 로딩 시간, 세션 유지율 – 로 더 검증 예정)

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
