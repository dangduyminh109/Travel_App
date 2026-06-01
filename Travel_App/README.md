# Travel_App - Flutter Mobile App

Flutter app cho hệ thống Travel App. App ưu tiên trải nghiệm khách du lịch: xem địa điểm không cần đăng nhập, đăng nhập khi cần thao tác cá nhân, và có màn quản trị cho tài khoản ADMIN.

## Công Nghệ

- Flutter / Dart
- Firebase Auth
- Firebase Realtime Database
- REST API tới Spring Boot backend
- SQLite local cache qua `sqflite`
- Google Maps Flutter

## Cấu Trúc Thư Mục

```text
lib/
├── core/
│   ├── constants       # app config, colors, API keys local
│   └── data            # model, api service, repository, cache, auth, favorite
└── features/
    ├── admin           # dashboard, CRUD địa điểm, CRUD danh mục
    ├── auth            # login, sign up, forgot password
    ├── favorites       # yêu thích
    ├── home            # trang chủ
    ├── place_detail    # chi tiết, map, review/reply
    ├── profile         # hồ sơ, role, nút quản trị
    └── search          # search/filter
```

## Cấu Hình Secret

Các file thật không được public GitHub:

```text
lib/core/constants/api_keys.dart
android/app/google-services.json
android/secrets.properties
```

Nếu pull từ GitHub, copy file mẫu:

```powershell
copy lib\core\constants\api_keys.example.dart lib\core\constants\api_keys.dart
copy android\app\google-services.example.json android\app\google-services.json
copy android\secrets.example.properties android\secrets.properties
```

`android/secrets.properties`:

```properties
GOOGLE_MAPS_API_KEY=YOUR_ANDROID_MAPS_KEY
```

`google-services.json` phải đúng Firebase project và đúng package:

```text
vn.com.huit.travelapp
```

## Backend URL

Mặc định app gọi backend qua Android Emulator:

```text
http://10.0.2.2:8080/api
```

File cấu hình:

```text
lib/core/data/api_service.dart
```

Nếu chạy trên điện thoại thật, đổi `_baseUrl` thành IP máy chạy backend:

```text
http://<IP_MAY_TINH>:8080/api
```

## Chạy App

```powershell
flutter pub get
flutter run
```

Nên chạy backend và MySQL trước để app tải dữ liệu lần đầu và ghi cache offline.

## Luồng Đăng Nhập Và Phân Quyền

App dùng Firebase Auth. Backend chỉ nhận Firebase ID token, không nhận password trực tiếp.

Luồng:

1. User đăng nhập bằng email/password hoặc Google trong Flutter.
2. `AuthService` lấy Firebase user.
3. `ApiService.syncUser()` gọi `POST /api/users/sync`.
4. `ApiService` tự thêm header:

```text
Authorization: Bearer <firebase_id_token>
```

5. Backend verify token và trả user có `role`.
6. `AuthLocalService` lưu session local gồm `uid`, `email`, `displayName`, `photoUrl`, `role`.
7. `ProfileScreen` đọc role:
   - `USER`: chỉ thấy chức năng người dùng.
   - `ADMIN`: thấy nút mở trang quản trị.

Các file liên quan:

```text
lib/core/data/auth_service.dart
lib/core/data/api_service.dart
lib/core/data/auth_local_service.dart
lib/features/profile/presentation/profile_screen.dart
lib/features/admin/
```

## Màn Admin

Admin mở từ tab `Hồ sơ` sau khi đăng nhập tài khoản có role `ADMIN`.

Các màn:

- `admin_dashboard_screen.dart`: thống kê tổng quan, top rating, top favorite, thống kê theo danh mục.
- `admin_destination_list_screen.dart`: danh sách địa điểm.
- `admin_destination_form_screen.dart`: thêm/sửa địa điểm.
- `admin_category_list_screen.dart`: thêm/sửa/xóa danh mục.

Lưu ý khi nhập URL ảnh:

- Chỉ nhập link ảnh gốc như `https://...jpg`.
- Không tự thêm `http://10.0.2.2:8080/api/images/proxy?...`.
- App/backend sẽ tự chuyển ảnh qua proxy khi hiển thị.

## Quyền Trên UI

- Khách chưa đăng nhập vẫn xem Home/Search/Detail.
- Khi bấm review/reply/like/dislike mà chưa đăng nhập, app mời đăng nhập.
- USER không thấy nút quản trị.
- ADMIN thấy nút quản trị trong Hồ sơ.
- Nếu API admin trả `401/403`, màn admin hiển thị lỗi quyền.

Lưu ý: UI chỉ là lớp hỗ trợ trải nghiệm; backend mới là lớp chặn quyền chính.

## Offline Cache

App dùng SQLite database `travel_cache.db`.

Cache:

- destinations
- categories
- raw JSON metadata

Luồng:

- Online: gọi API backend, hiển thị dữ liệu mới, lưu cache.
- Offline/backend tắt: đọc cache để xem Home/Search/Detail.
- Không cache ảnh, review, Firebase realtime hoặc Google Maps.

Nếu cache rỗng, cần mở app online một lần.

## Test

```powershell
flutter analyze
flutter test
```

Kỳ vọng:

- `flutter analyze`: không có issue.
- `flutter test`: toàn bộ test pass.

## Lỗi Thường Gặp

- Login Firebase xoay lâu: kiểm tra emulator có internet thật; mở Chrome trong emulator thử vào Google.
- Không gọi được backend: backend phải chạy tại `localhost:8080`; emulator dùng `10.0.2.2`.
- Không thấy ảnh: backend phải chạy để image proxy hoạt động; link ảnh gốc ngoài internet cũng phải còn truy cập được.
- Google Maps lỗi: kiểm tra `android/secrets.properties`, package name, SHA restriction trên Google Cloud.
- Không thấy nút quản trị: kiểm tra email đã nằm trong `app.admin-emails`, đăng xuất/đăng nhập lại để sync role.

## File Không Được Commit Public

```text
lib/core/constants/api_keys.dart
android/app/google-services.json
android/secrets.properties
.dart_tool/
build/
android/.gradle/
```

Chỉ commit:

```text
lib/core/constants/api_keys.example.dart
android/app/google-services.example.json
android/secrets.example.properties
```
