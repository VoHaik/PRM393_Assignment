# HistoryTalk Flutter — Codebase Knowledge Summary

> Tài liệu này tổng hợp toàn bộ kiến thức về source code Flutter của dự án HistoryTalk để agent/developer mới có thể hiểu nhanh và làm việc hiệu quả.

---

## 1. Tổng quan dự án

**HistoryTalk** là ứng dụng mobile Flutter cho phép người dùng:
- Trò chuyện với các nhân vật lịch sử Việt Nam bằng AI (chat + voice)
- Khám phá các bối cảnh / sự kiện lịch sử
- Làm bài trắc nghiệm lịch sử
- Nâng cấp tài khoản (subscription tiers) qua PayOS

**Backend:** Spring Boot 3 Java (deployed tại `https://historytalk.app/Historical-tell`)  
**API Base URL:** `https://historytalk.app/Historical-tell/api/v1`  
**Flutter SDK:** `^3.11.0`

---

## 2. Kiến trúc tổng thể

```
Clean Architecture (3 lớp):
├── domain/         ← Entities + Repository interfaces (pure Dart, không phụ thuộc)
├── data/           ← Repository implementations + Models (fromJson/toJson) + DataSources
└── presentation/   ← BLoC + Screens + Widgets (Flutter UI)

core/              ← Network client, theme, utils, constants
injection_container.dart  ← GetIt DI setup
main.dart          ← App entry point
```

### Dependency Injection
- Dùng **GetIt** (`sl` = service locator)
- Setup tại [`injection_container.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/injection_container.dart)
- Repositories: `registerLazySingleton` (1 instance dùng mãi)
- BLoCs: `registerFactory` (tạo mới mỗi lần dùng)
- Gọi trong widget: `sl<CharacterRepository>()`

### State Management
- **BLoC pattern** (`flutter_bloc ^8.1.6`)
- 4 BLoC hiện có: `AuthBloc`, `ChatBloc`, `QuizBloc`, `PaymentBloc`
- Các màn hình đơn giản (HomeScreen, ExploreScreen…) dùng `StatefulWidget` + `setState` trực tiếp với repository

---

## 3. Cấu trúc thư mục chi tiết

```
lib/
├── core/
│   ├── constants/env_config.dart     ← Đọc .env (apiBaseUrl, Google OAuth, Azure Speech)
│   ├── network/dio_client.dart       ← Dio setup + interceptors (auth header, token refresh, path normalization)
│   ├── theme/
│   │   ├── app_theme.dart            ← Light/Dark theme, AppColors constants
│   │   └── lucide_icons.dart         ← Custom icon mapping (Icons.xxx aliases)
│   └── utils/
│       ├── azure_tts_client.dart     ← Azure Cognitive Services TTS (text → audio stream)
│       └── speech_to_text_service.dart  ← STT microphone input
│
├── data/
│   ├── datasources/local/
│   │   ├── hive_helper.dart          ← Hive offline cache init
│   │   └── secure_storage_service.dart ← FlutterSecureStorage (access/refresh token)
│   ├── models/                       ← Data models (extends entity, adds fromJson/toJson)
│   │   ├── character_model.dart
│   │   ├── chat_model.dart
│   │   ├── historical_context_model.dart
│   │   ├── payment_model.dart
│   │   ├── quiz_model.dart
│   │   └── user_model.dart
│   └── repositories/                 ← Implementations gọi Dio
│       ├── auth_repository_impl.dart
│       ├── character_repository_impl.dart
│       ├── chat_repository_impl.dart
│       ├── historical_context_repository_impl.dart
│       ├── payment_repository_impl.dart
│       └── quiz_repository_impl.dart
│
├── domain/
│   ├── entities/                     ← Pure Dart classes (no JSON)
│   │   ├── character.dart
│   │   ├── chat.dart
│   │   ├── historical_context.dart
│   │   ├── payment.dart
│   │   ├── quiz.dart
│   │   └── user.dart
│   └── repositories/                 ← Abstract interfaces
│       ├── auth_repository.dart
│       ├── character_repository.dart
│       ├── chat_repository.dart
│       ├── historical_context_repository.dart
│       ├── payment_repository.dart
│       └── quiz_repository.dart
│
├── presentation/
│   ├── auth/
│   │   ├── auth_bloc.dart            ← AuthBloc: AppStarted, Login, Register, GoogleAuth, Logout
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── characters/
│   │   └── character_detail_screen.dart  ← Load character → load sessions (với contextId)
│   ├── chat/
│   │   ├── chat_bloc.dart            ← ChatBloc: sessions, messages, SSE stream, TTS, STT
│   │   └── chat_screen.dart
│   ├── contexts/
│   │   └── explore_screen.dart       ← Grid 2 cột context cards, filter theo era
│   ├── historical_context/
│   │   └── historical_context_detail_screen.dart ← Detail screen (mới tạo)
│   ├── home/
│   │   └── home_screen.dart          ← Featured characters + Hot contexts
│   ├── payment/
│   │   ├── payment_bloc.dart
│   │   └── payment_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── quiz/
│   │   ├── quiz_bloc.dart
│   │   ├── quiz_list_screen.dart
│   │   ├── quiz_play_screen.dart
│   │   └── quiz_result_screen.dart
│   ├── widgets/
│   │   ├── character_card.dart       ← Reusable character card (compact/full)
│   │   └── context_card.dart         ← Reusable context card + EraTheme config
│   └── main_tabs_screen.dart         ← Bottom nav (Home, Explore, Quiz, Payment, Profile)
│
├── injection_container.dart
└── main.dart                         ← Entry: .env load → DI init → Hive init → runApp
```

---

## 4. Luồng xác thực (Auth Flow)

```
App start
  → AuthBloc receives AppStarted
  → reads token from SecureStorage
  → if token exists → Authenticated → MainTabsScreen
  → if not → Unauthenticated → LoginScreen

Login options:
  1. Email/Password: POST /auth/login
  2. Google OAuth:   Google Sign-In → ID token → POST /auth/google
                     (Backend verify ID token qua Google tokeninfo API)

Token storage: FlutterSecureStorage (key-value encrypted)
  - accessToken
  - refreshToken

Token refresh: DioClient interceptor tự động retry khi nhận 401
```

---

## 5. Network Layer — DioClient

File: [`dio_client.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/core/network/dio_client.dart)

**Interceptors:**
1. **onRequest**: 
   - Strip trailing slash khỏi path (Spring Boot 3 không accept `/characters/`)
   - Inject `Authorization: Bearer <token>` nếu không có `extra['skipAuth'] = true`
2. **onError**:
   - 401 → thử refresh token → retry request gốc
   - Refresh thất bại → clear storage

**Timeout:** connect 30s, receive 60s

**Logging:** chỉ bật ở `kDebugMode`

---

## 6. Backend API — Endpoints đã xác nhận

> Base: `https://historytalk.app/Historical-tell/api/v1`

| Domain | Method | Path | Auth | Note |
|---|---|---|---|---|
| Auth | POST | `/auth/login` | Public | `{email, password}` |
| Auth | POST | `/auth/google` | Public | `{idToken}` |
| Auth | POST | `/auth/register` | Public | |
| Characters | GET | `/characters` | Public | Paginated (`data.content[]`) |
| Characters | GET | `/characters/{characterId}` | Public | |
| Historical Contexts | GET | `/historical-contexts` | Public | Paginated |
| Historical Contexts | GET | `/historical-contexts/{contextId}` | Public | |
| Chat | GET | `/chat/sessions` | Authenticated | **Bắt buộc** `?characterId=&contextId=` |
| Chat | POST | `/chat/sessions` | Authenticated | `{characterId, contextId}` |
| Chat | DELETE | `/chat/sessions/{id}` | Authenticated | |
| Chat | GET | `/chat/sessions/{id}/messages` | Authenticated | |
| Chat | POST | `/chat/messages` | Authenticated | |
| Chat | GET | `/chat/history` | Authenticated | Group by context |
| Quizzes | GET | `/quizzes` | Public | |
| Quizzes | GET | `/quizzes/{quizId}` | Public | |
| Quizzes | POST | `/quizzes/{quizId}/start` | CUSTOMER | |
| Quizzes | POST | `/quizzes/submit` | CUSTOMER | |
| Quizzes | GET | `/quizzes/results/me` | CUSTOMER | |
| Payments | GET | `/payments/tiers` | Public | Danh sách gói |
| Payments | POST | `/payments/checkout` | CUSTOMER | `{tierId}` → PayOS link |
| Payments | GET | `/payments/me` | CUSTOMER | Lịch sử thanh toán |
| Users | GET | `/users/me` | Any role | Profile |
| Users | PATCH | `/users/me` | Any role | Cập nhật profile |

---

## 7. JSON Field Mapping — Backend vs Model

> **Quan trọng:** Backend dùng naming khác với convention thông thường. Các model đã được sửa để xử lý đúng.

### Character (`character_model.dart`)
| Backend JSON field | Flutter model field | Ghi chú |
|---|---|---|
| `characterId` | `id` | Không phải `id` |
| `status: "ACTIVE"` | `isActive` | Không phải boolean `isActive` |
| `createdDate` | `createdAt` | Không phải `createdAt` |
| `updatedDate` | `updatedAt` | Không phải `updatedAt` |
| `contexts[].contextId` | `contexts[].id` | `contextId` là String thẳng (không nested Map) |

### Historical Context (`historical_context_model.dart`)
| Backend JSON field | Flutter model field | Ghi chú |
|---|---|---|
| `contextId` | `id` | Không phải `id` |
| `status: "ACTIVE"` | `isActive` | Enum string |
| `imageUrl` | `image` | Không phải `image` |
| `createdDate` | `createdAt` | |
| `updatedDate` | `updatedAt` | |

### Quiz (`quiz_model.dart`)
- `quizId` → `quizId` ✅ (đúng rồi)

### Payment (`payment_model.dart`)
- `createOrder` → POST `/payments/checkout` (không phải `/payments/orders`)
- `getMyOrders` → GET `/payments/me` (không phải `/payments/orders`)
- `getOrderStatus` → fallback: tìm trong list `/payments/me` (không có endpoint riêng)

---

## 8. Chat — Lưu ý quan trọng

```
Backend: GET /chat/sessions?characterId=<uuid>&contextId=<uuid>
```
- **Cả hai params là BẮT BUỘC** (mandatory @RequestParam trên backend)
- Nếu thiếu 1 trong 2 → **400 Bad Request**
- `chat_repository_impl.getSessions()` trả `[]` ngay nếu thiếu 1 trong 2 param (tránh 400)

**Luồng mở chat từ CharacterDetailScreen:**
1. Load character by ID
2. Lấy `contextId` từ `character.contexts.first.id`
3. Gọi `getSessions(characterId: ..., contextId: ...)`
4. Nếu character không có context → không load sessions

**SSE Streaming (chat):** ChatRepositoryImpl dùng `StreamController<String>` để stream từng token response từ server.

---

## 9. Navigation Flow

```
AuthGateScreen (BLocBuilder)
  ├── Loading → Splash screen
  ├── Authenticated → MainTabsScreen (IndexedStack)
  │     ├── Tab 0: HomeScreen → CharacterDetailScreen → ChatScreen
  │     │                    → HistoricalContextDetailScreen
  │     ├── Tab 1: ExploreScreen → HistoricalContextDetailScreen
  │     ├── Tab 2: QuizListScreen → QuizPlayScreen → QuizResultScreen
  │     ├── Tab 3: PaymentScreen
  │     └── Tab 4: ProfileScreen
  └── Unauthenticated → LoginScreen → RegisterScreen
```

---

## 10. Theme & Colors

File: [`app_theme.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/core/theme/app_theme.dart)

- `AppColors.darkAccent` / `AppColors.lightAccent` — màu chủ đạo theo theme
- `AppColors.darkTextSecondary` / `AppColors.lightTextSecondary`
- `AppColors.darkSurface` / `AppColors.lightSurface`
- `AppColors.darkBorder` / `AppColors.lightBorder`
- Dùng `ThemeMode.system` — tự động theo setting điện thoại

**Era Themes** (trong `context_card.dart`):
- `ancient` → Vàng/Nâu
- `medieval` → Tím
- `modern` → Xanh lá
- `contemporary` → Xanh dương

---

## 11. Patrol Testing

> **Trạng thái hiện tại: CHƯA CÓ**

- Dự án **chưa setup Patrol** (chỉ có `flutter_test` cơ bản trong dev_dependencies)
- File `test/widget_test.dart` là boilerplate mặc định của Flutter, **chưa có test thực sự**
- Chưa có `integration_test/` directory
- Patrol package (`patrol: ^x.x.x`) **chưa được thêm vào `pubspec.yaml`**

**Để setup Patrol testing cần:**
1. Thêm vào `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     patrol: ^3.x.x
     integration_test:
       sdk: flutter
   ```
2. Tạo `integration_test/` directory
3. Chạy: `patrol test`

---

## 12. Environment Variables (.env)

```env
API_BASE_URL=https://historytalk.app/Historical-tell/api/v1
GOOGLE_WEB_CLIENT_ID=<id>
GOOGLE_ANDROID_CLIENT_ID=<id>
GOOGLE_IOS_CLIENT_ID=<id>
AZURE_SPEECH_KEY=<key>
AZURE_SPEECH_REGION=<region>
AZURE_SPEECH_VOICE=vi-VN-NamMinhNeural
```

File `.env` được bundle vào assets (`flutter.assets: [.env]` trong pubspec.yaml).

---

## 13. Android Emulator Quirks (máy dev này)

> **BUG ĐẶC BIỆT** — SLIRP NAT corruption

Metro bundle bị corrupt khi load qua `10.0.2.2` (SLIRP NAT của QEMU). Triệu chứng: splash screen đứng hoặc `Invalid UTF-8` / `Requiring unknown module`.

**Fix mỗi lần boot emulator:**
```bash
emulator -avd <name> -allow-host-audio
npx expo start
npm run android:launch   # adb reverse + launch với 127.0.0.1
```

---

## 14. Các file quan trọng cần biết

| File | Vai trò |
|---|---|
| [`injection_container.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/injection_container.dart) | DI wiring toàn bộ app |
| [`dio_client.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/core/network/dio_client.dart) | HTTP client, interceptors |
| [`auth_bloc.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/presentation/auth/auth_bloc.dart) | Auth state machine |
| [`chat_repository_impl.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/data/repositories/chat_repository_impl.dart) | Chat + SSE streaming |
| [`character_model.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/data/models/character_model.dart) | JSON mapping phức tạp nhất |
| [`context_card.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/presentation/widgets/context_card.dart) | Reusable card + EraTheme |
| [`character_detail_screen.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/presentation/characters/character_detail_screen.dart) | Load sequence: char → context → sessions |
| [`historical_context_detail_screen.dart`](file:///c:/Users/KHAI/Documents/semester%208/PRM-Final-Project/historytalk_flutter/lib/presentation/historical_context/historical_context_detail_screen.dart) | Context detail (mới tạo, load by contextId) |
