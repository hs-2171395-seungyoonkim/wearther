# Wearther

> **날씨 기반 내 옷장 코디 추천 iOS 앱**  
> "오늘 뭐 입지?" — 내 옷장과 날씨를 연결해 AI가 코디를 추천합니다.

## 유튜브 링크
https://youtu.be/oXkey0wTvEQ 
---

## 주요 기능

| 기능 | 설명 |
|------|------|
| **홈 날씨 카드** | 현재 위치 자동 감지, 실시간 기온·습도·풍속·날씨 이모지 표시 |
| **AI 오늘 코디 추천** | 내 옷장 아이템 기반 Gemini AI 코디 추천 |
| **착용 기록 캘린더** | 날짜별 착용 아이템 기록 및 월별 캘린더 조회 |
| **여행지 날씨** | 지도 탭 / 도시 검색 / 퀵칩(서울·도쿄·방콕·파리 등)으로 여행지 날씨 확인 |
| **여행 일정 관리** | 여행 생성 시 일차별 날씨 예보 자동 조회, 패킹 리스트 AI 생성 |
| **여행 일차별 AI 코디** | 일차 날씨 기반 코디 3가지 추천, 결과 캐시로 불필요한 재호출 방지 |
| **디지털 옷장** | 옷 사진·카테고리·태그·적정 기온 등록, 카테고리 필터, 즐겨찾기 |
| **옷 수정** | 사진 교체 포함 모든 정보 수정 가능 |
| **AI 아이템 분석** | 아이템별 스타일 특징·코디 방법 AI 분석 메모 |
| **코디 저장** | 추천 코디를 저장하여 프로필에서 확인 |
| **프로필 설정** | 스타일 취향, 기본 위치, 날씨 알림 시간 설정 |
| **JWT 인증** | 토큰 만료 시 자동 로그아웃 처리 |

---

## 기술 스택

### Frontend (iOS)
- **Swift 5.9 / SwiftUI** — 전체 UI
- **MapKit** — 여행지 지도 및 위치 탭
- **PhotosUI** — 옷 사진 선택
- **CoreLocation** — 현재 위치 날씨 자동 감지
- **UserNotifications** — 매일 날씨 알림 설정
- **NSCache 기반 `CachedAsyncImage`** — 이미지 로딩 캐시 (SwiftUI AsyncImage 리렌더 이슈 해결)

### Backend (Spring Boot)
- **Spring Boot 3** / **Spring Security** (JWT)
- **Spring Data JPA** / **H2 Database**
- **Multipart 파일 업로드** — 옷 이미지 서버 저장 및 정적 서빙

### External APIs
- **Google Gemini API** — 코디 추천, 아이템 분석, 패킹 리스트 생성
- **OpenWeatherMap API** — 현재 날씨, 5일 예보, 도시 Geocoding

---

## 프로젝트 구조

```
Wearther/
├── FE/                          # iOS 앱 (Swift/SwiftUI)
│   └── Wearther/
│       ├── ContentView.swift    # 루트 뷰 (로그인/메인 탭 분기)
│       ├── HomeView.swift       # 홈 탭
│       ├── TravelView.swift     # 여행 탭
│       ├── ClosetView.swift     # 옷장 탭
│       ├── ProfileView.swift    # 프로필 탭
│       ├── APIClient.swift      # REST API 클라이언트 (모든 모델 포함)
│       ├── CachedAsyncImage.swift  # NSCache 기반 이미지 로더
│       ├── WeatherService.swift # OpenWeatherMap 연동
│       └── ...
└── BE/                          # Spring Boot 서버
    └── api/src/main/java/com/Wearther/api/
        ├── controller/          # REST 컨트롤러
        ├── service/             # 비즈니스 로직 (AiService, WornLogService 등)
        ├── entity/              # JPA 엔티티
        ├── dto/                 # 요청/응답 DTO
        ├── security/            # JWT 인증 필터
        └── config/              # Security, Web, Swagger 설정
```

---

## 설치 및 실행

### 사전 요구사항
- Xcode 15+
- JDK 17+
- Gemini API 키
- OpenWeatherMap API 키

### BE 실행

```bash
cd BE/api
# application.properties에 API 키 설정 후
./gradlew bootRun
```

### FE 실행

1. `FE/Wearther/Config.swift.example`을 `Config.swift`로 복사
2. `baseURL` 등 설정값 입력
3. Xcode에서 `Wearther.xcodeproj` 열고 시뮬레이터 실행

> 이미지 서빙: BE가 `http://localhost:8080/images/` 경로로 정적 파일을 서빙합니다.  
> `Info.plist`에 `NSAllowsLocalNetworking: true` 설정으로 HTTP 로컬 통신을 허용합니다.

---

## API 엔드포인트 요약

| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | `/api/auth/signup` | 회원가입 |
| POST | `/api/auth/login` | 로그인 (JWT 발급) |
| GET | `/api/user/profile` | 프로필 조회 |
| PATCH | `/api/user/profile` | 프로필 수정 |
| GET | `/api/closet/items` | 옷장 목록 조회 |
| POST | `/api/closet/items` | 옷 등록 (multipart) |
| PATCH | `/api/closet/items/{id}` | 옷 정보 수정 |
| PATCH | `/api/closet/items/{id}/image` | 옷 이미지 수정 (multipart) |
| DELETE | `/api/closet/items/{id}` | 옷 삭제 |
| GET | `/api/trips` | 여행 목록 조회 |
| POST | `/api/trips` | 여행 생성 |
| GET | `/api/trips/{id}/days` | 일차별 날씨 조회 |
| GET | `/api/outfits` | 저장된 코디 조회 |
| POST | `/api/outfits` | 코디 저장 |
| POST | `/api/ai/recommend-today` | 오늘 날씨 코디 추천 |
| POST | `/api/ai/outfit-suggestions` | 도시 날씨 코디 3가지 추천 |
| POST | `/api/ai/closet/items/{id}/analyze` | 아이템 AI 분석 |
| POST | `/api/worn-logs` | 착용 기록 저장 |
| GET | `/api/worn-logs` | 월별 착용 기록 조회 |
| GET | `/images/**` | 업로드 이미지 정적 서빙 (인증 불필요) |

---

## 개발자

김승윤
