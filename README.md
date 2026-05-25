# Travel App - Ứng Dụng Quảng Bá Du Lịch Việt Nam

Travel App là đồ án mobile giới thiệu và tra cứu địa điểm du lịch, tập trung vào TP.HCM và Vũng Tàu. Ứng dụng cho phép người dùng xem địa điểm không cần đăng nhập, tìm kiếm/lọc theo nhu cầu du khách, xem chi tiết địa điểm, lưu yêu thích, đánh giá, phản hồi đánh giá và đọc dữ liệu text/metadata offline sau khi đã cache một lần.

## Kiến Trúc Tổng Thể

- `Travel_App`: ứng dụng Flutter. Các màn chính gồm Home, Search/Filter, Detail, Favorite, Profile, Auth và Map.
- `travel_Api`: backend Spring Boot REST API. Backend quản lý địa điểm, danh mục, đánh giá, phản hồi, yêu thích, người dùng và proxy ảnh.
- MySQL 8: lưu dữ liệu chính. Backend dùng `ddl-auto=update`, tự tạo bảng và seed dữ liệu khi chạy lần đầu.
- Firebase: dùng cho Firebase Auth ở app và Firebase Realtime Database cho đồng bộ review/notification.
- SQLite trong Flutter: cache danh mục và địa điểm để xem text/metadata khi offline.

## Chạy Nhanh Bằng Docker MySQL

Yêu cầu cài sẵn:

- Java 21
- Flutter SDK/Dart đúng với project
- Docker Desktop
- Android Studio hoặc emulator Android

Chạy MySQL:

```powershell
docker compose up -d
```

Chạy backend:

```powershell
cd travel_Api
.\mvnw.cmd spring-boot:run
```

Backend chạy ở:

```text
http://localhost:8080
```

Chạy Flutter app:

```powershell
cd Travel_App
flutter pub get
flutter run
```

Với Android Emulator, app gọi backend qua `http://10.0.2.2:8080/api`. Nếu chạy trên điện thoại thật, cần đổi base URL trong `Travel_App/lib/core/data/api_service.dart` sang IP máy đang chạy backend, ví dụ `http://192.168.1.10:8080/api`.

## Config Và Secret

Project có 2 cách dùng source:

- **Bản push GitHub/public**: không commit secret thật. Cần copy các file `.example` thành file thật và liên hệ chủ project để lấy key/config.
- **Bản nộp thầy**: source zip có thể kèm file config thật để thầy chạy ngay theo hướng dẫn trên.

Các file secret thật cần có khi chạy đủ tính năng:

- `Travel_App/lib/core/constants/api_keys.dart`
- `Travel_App/android/app/google-services.json`
- `Travel_App/android/secrets.properties`
- `travel_Api/src/main/resources/serviceAccountKey.json`
- `travel_Api/src/main/resources/application-local.yaml` nếu cần override Firebase/JWT/DB local

Các file mẫu tương ứng:

- `Travel_App/lib/core/constants/api_keys.example.dart`
- `Travel_App/android/app/google-services.example.json`
- `Travel_App/android/secrets.example.properties`
- `travel_Api/src/main/resources/serviceAccountKey.example.json`
- `travel_Api/src/main/resources/application.example.yaml`
- `.env.example`

## Database

Docker Compose tạo sẵn MySQL:

- host: `localhost`
- port: `3306`
- database: `travel_db`
- username: `root`
- password: `root`

Nếu không dùng Docker, có thể tự cài MySQL 8 và tạo database `travel_db`. Backend sẽ tự tạo bảng khi chạy.

## Các Chức Năng Đã Làm

- Không bắt buộc đăng nhập khi mở app và xem địa điểm.
- Đăng nhập chỉ cần cho review, phản hồi, like/dislike, đồng bộ favorite/profile.
- Dữ liệu địa điểm đa loại: ăn uống, vui chơi, nghỉ ngơi, cafe/check-in, văn hóa/lịch sử, mua sắm.
- Seed dữ liệu tập trung TP.HCM và Vũng Tàu, giữ dữ liệu cũ để không đứt review/favorite.
- Search/filter theo keyword, city, district, place type, price level, rating, nearby và sort.
- Home tối ưu cho app du lịch với gợi ý theo khu vực và nhu cầu.
- Offline cache bằng SQLite cho địa điểm/danh mục text + metadata.
- Review, reply, sửa/xóa reply, like/dislike review.
- Proxy ảnh backend để app hiển thị ảnh ổn định hơn.

## Kiểm Tra

Backend:

```powershell
cd travel_Api
.\mvnw.cmd test
```

Flutter:

```powershell
cd Travel_App
flutter analyze
flutter test
```

Trước khi push GitHub, kiểm tra secret:

```powershell
git status --short
git ls-files | findstr /i "api_keys google-services serviceAccountKey secrets.properties application-local"
```

Kết quả mong muốn khi push public: chỉ có file `.example`, không có file secret thật.

## Ghi Chú Khi Nộp Source Cho Thầy

Khi tạo ZIP nộp bài, nên loại bỏ thư mục nặng/cache:

- `.git`
- `Travel_App/build`
- `Travel_App/.dart_tool`
- `Travel_App/android/.gradle`
- `travel_Api/target`

Với gói nộp thầy, giữ lại các file config thật ở phần **Config Và Secret** để thầy chỉ cần chạy Docker, backend và app là dùng được.
