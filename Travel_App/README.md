# Travel_App - Flutter Mobile App

Travel_App là frontend Flutter cho ứng dụng quảng bá và tra cứu địa điểm du lịch TP.HCM + Vũng Tàu. App ưu tiên cho người dùng xem nội dung không cần đăng nhập, chỉ yêu cầu đăng nhập khi thực hiện thao tác cá nhân như review, phản hồi, like/dislike, profile và đồng bộ yêu thích.

## Công Nghệ

- Flutter / Dart
- Firebase Auth
- Firebase Realtime Database
- SQLite local cache qua `sqflite`
- Google Maps Flutter
- HTTP REST API tới Spring Boot backend

## Cấu Trúc Chính

- `lib/main.dart`: khởi tạo Firebase và mở app vào `MainScreen`.
- `lib/core/constants`: màu sắc, config, API keys local.
- `lib/core/data`: model, API service, repository, local cache, auth, favorite local, realtime sync.
- `lib/features/home`: Home gợi ý địa điểm/khu vực/nhu cầu.
- `lib/features/search`: Search/filter địa điểm theo API và fallback offline cache.
- `lib/features/place_detail`: chi tiết địa điểm, map, review, reply.
- `lib/features/favorites`: danh sách yêu thích local/online.
- `lib/features/profile`: hồ sơ, chỉnh profile, danh sách review.
- `lib/features/auth`: login, register, forgot password.
- `test`: unit/widget test cho model, cache và flow mở app không cần login.

## Chức Năng Chính

- Mở app và xem địa điểm không cần đăng nhập.
- Home hiển thị gợi ý nổi bật, khu vực và nhu cầu du khách.
- Search/filter theo thành phố, khu vực, loại địa điểm, giá, rating, nearby.
- Detail hiển thị địa chỉ, quận/khu vực, giá, giờ mở cửa, highlights, phù hợp với ai.
- Offline text + metadata bằng SQLite sau khi mở app online một lần.
- Review, phản hồi, sửa/xóa phản hồi, like/dislike review.
- Favorite local khi chưa đăng nhập và sync khi có tài khoản.
- Map hiển thị marker địa điểm; các dịch vụ cần internet sẽ báo trạng thái phù hợp khi lỗi.

## Cấu Hình Secret

Các file thật không public GitHub:

```text
lib/core/constants/api_keys.dart
android/app/google-services.json
android/secrets.properties
```

Nếu lấy source từ GitHub/public, copy file mẫu:

```powershell
copy lib\core\constants\api_keys.example.dart lib\core\constants\api_keys.dart
copy android\app\google-services.example.json android\app\google-services.json
copy android\secrets.example.properties android\secrets.properties
```

Sau đó điền key thật. Nếu dùng gói nộp thầy, các file thật có thể đã được kèm sẵn.

`android/secrets.properties` cần có:

```properties
GOOGLE_MAPS_API_KEY=YOUR_ANDROID_MAPS_KEY
```

## Backend URL

Mặc định app gọi backend qua:

```text
http://10.0.2.2:8080/api
```

Địa chỉ này dùng cho Android Emulator. Nếu chạy trên điện thoại thật, đổi `_baseUrl` trong `lib/core/data/api_service.dart` sang IP máy chạy backend:

```text
http://<IP_MAY_TINH>:8080/api
```

## Chạy App

Từ thư mục `Travel_App`:

```powershell
flutter pub get
flutter run
```

Trước khi mở app, nên chạy backend và MySQL để app tải dữ liệu lần đầu và ghi cache offline.

## Offline Cache

App dùng `travel_cache.db` để lưu:

- destinations
- categories
- raw JSON metadata

Luồng hoạt động:

- Online: gọi API backend, hiển thị dữ liệu mới và lưu SQLite.
- Offline/backend tắt: đọc dữ liệu đã cache để xem Home/Search/Detail.
- Không cache ảnh, review, Firebase realtime hoặc Google Maps offline.

Nếu cache trống, cần mở app khi có backend/internet ít nhất một lần.

## Kiểm Tra

```powershell
flutter analyze
flutter test
```

Kỳ vọng:

- `flutter analyze`: không có issue.
- `flutter test`: toàn bộ test pass.

## Lỗi Thường Gặp

- Không đăng nhập được Firebase: kiểm tra emulator/thiết bị có internet thật và DNS hoạt động.
- Không gọi được backend trên emulator: đảm bảo backend chạy ở `localhost:8080` trên máy tính, app dùng `10.0.2.2`.
- Không thấy ảnh: đảm bảo backend đang chạy để dùng image proxy, hoặc ảnh ngoài internet không bị chặn.
- Google Maps không hiện đúng: kiểm tra `android/secrets.properties`, package name và SHA restriction trên Google Cloud.
