# Travel App - Ứng Dụng Du Lịch TP.HCM Và Vũng Tàu

Travel App là đồ án mobile dùng để quảng bá, tra cứu và quản lý địa điểm du lịch tại TP.HCM và Vũng Tàu. Người dùng có thể mở app xem địa điểm mà không cần đăng nhập; các thao tác cá nhân như đánh giá, phản hồi, yêu thích, hồ sơ và quản trị yêu cầu Firebase Authentication.

## Kiến Trúc Tổng Thể

- `Travel_App/`: Flutter mobile app.
- `travel_Api/`: Spring Boot REST API.
- MySQL 8: lưu dữ liệu chính.
- Firebase Auth: đăng nhập email/password và Google.
- Firebase Admin SDK: backend verify Firebase ID token và đồng bộ realtime review/notification.
- SQLite trong Flutter: cache danh mục và địa điểm để xem text/metadata khi offline.

## Chức Năng Chính

- Xem Home/Search/Detail không cần đăng nhập.
- Search/filter theo keyword, thành phố, quận/khu vực, loại địa điểm, mức giá, rating, địa điểm gần nhau.
- Dữ liệu địa điểm đa loại: ăn uống, vui chơi, nghỉ ngơi/khách sạn, cafe/check-in, văn hóa/lịch sử, mua sắm.
- Offline text + metadata bằng SQLite sau khi app đã tải dữ liệu online một lần.
- Review, phản hồi review, sửa/xóa phản hồi, like/dislike review.
- Favorite local khi chưa đăng nhập và đồng bộ khi đăng nhập.
- Admin dashboard, thống kê, CRUD địa điểm, CRUD danh mục.
- Image proxy qua backend để hiển thị ảnh ngoài internet ổn định hơn.

## Chạy Nhanh Sau Khi Pull Repo

Yêu cầu:

- Java 21
- Flutter SDK
- Docker Desktop
- Android Studio hoặc Android Emulator

1. Chuẩn bị file cấu hình thật

Nếu pull từ GitHub/public, copy các file mẫu rồi điền key thật:

```powershell
copy .env.example .env
copy travel_Api\src\main\resources\application.example.yaml travel_Api\src\main\resources\application-local.yaml
copy travel_Api\src\main\resources\serviceAccountKey.example.json travel_Api\src\main\resources\serviceAccountKey.json
copy Travel_App\lib\core\constants\api_keys.example.dart Travel_App\lib\core\constants\api_keys.dart
copy Travel_App\android\app\google-services.example.json Travel_App\android\app\google-services.json
copy Travel_App\android\secrets.example.properties Travel_App\android\secrets.properties
```

Nếu nhận gói source nộp/bàn giao nội bộ, các file thật có thể đã được kèm sẵn. Không đưa các file thật này lên GitHub public.

2. Chạy MySQL bằng Docker

```powershell
docker compose up -d
```

Thông tin mặc định:

- host: `localhost`
- port: `3306`
- database: `travel_db`
- username: `root`
- password: `root`

3. Chạy backend

```powershell
cd travel_Api
.\mvnw.cmd spring-boot:run
```

Backend chạy tại:

```text
http://localhost:8080
```

4. Chạy Flutter app

```powershell
cd Travel_App
flutter pub get
flutter run
```

Android Emulator gọi backend qua:

```text
http://10.0.2.2:8080/api
```

Nếu dùng điện thoại thật, đổi `_baseUrl` trong `Travel_App/lib/core/data/api_service.dart` sang IP máy chạy backend, ví dụ:

```text
http://192.168.1.10:8080/api
```

## Phân Quyền Và Bàn Giao

Project dùng Firebase Auth làm nguồn đăng nhập chính. Backend không tự nhận email/password; app đăng nhập Firebase, lấy Firebase ID token, sau đó gửi token cho backend qua header:

```text
Authorization: Bearer <firebase_id_token>
```

Luồng phân quyền:

1. User đăng nhập trong Flutter bằng Firebase.
2. Flutter gọi `POST /api/users/sync` kèm Firebase ID token.
3. Backend verify token bằng Firebase Admin SDK.
4. Backend tạo/cập nhật user trong bảng `users`.
5. Nếu email nằm trong `app.admin-emails`, user được gán role `ADMIN`; còn lại là `USER`.
6. App lưu role local và chỉ hiển thị màn quản trị nếu role là `ADMIN`.
7. Backend vẫn là lớp chặn quyền chính: `/api/admin/**` chỉ role `ADMIN` gọi được.

### Cấu Hình Admin

Trong file local ignored `travel_Api/src/main/resources/application-local.yaml`:

```yaml
app:
  admin-emails: admin1@example.com,admin2@example.com
```

Hoặc dùng biến môi trường:

```powershell
$env:ADMIN_EMAILS="admin1@example.com,admin2@example.com"
```

Khi bàn giao cho người khác:

- Tạo tài khoản Firebase bằng email admin.
- Thêm email đó vào `app.admin-emails`.
- Chạy backend.
- Đăng nhập app bằng email admin.
- Vào tab `Hồ sơ`, app sẽ hiện role `Quản trị viên` và nút mở trang quản trị.

### Ma Trận Quyền

| Nhóm API | Quyền |
| --- | --- |
| `GET /api/destinations/**` | Public |
| `GET /api/categories/**` | Public |
| `GET /api/images/**` | Public |
| `POST /api/users/sync` | Đã đăng nhập Firebase |
| `/api/users/**` | Đã đăng nhập, chỉ chính chủ hoặc ADMIN |
| `POST/PUT/DELETE /api/destinations/**` cho review/reply/reaction | Đã đăng nhập |
| `/api/admin/**` | Chỉ ADMIN |

### Các File Chính Của Phân Quyền

- Backend:
  - `travel_Api/src/main/java/com/vn/huit/travelApp/config/SecurityConfig.java`
  - `travel_Api/src/main/java/com/vn/huit/travelApp/security/FirebaseAuthenticationFilter.java`
  - `travel_Api/src/main/java/com/vn/huit/travelApp/security/FirebaseUserPrincipal.java`
  - `travel_Api/src/main/java/com/vn/huit/travelApp/service/AuthenticatedUserService.java`
  - `travel_Api/src/main/java/com/vn/huit/travelApp/service/UserService.java`
- Flutter:
  - `Travel_App/lib/core/data/api_service.dart`
  - `Travel_App/lib/core/data/auth_service.dart`
  - `Travel_App/lib/core/data/auth_local_service.dart`
  - `Travel_App/lib/features/profile/presentation/profile_screen.dart`
  - `Travel_App/lib/features/admin/`

## Secret Không Được Public

Các file thật đang được `.gitignore` chặn:

```text
.env
travel_Api/src/main/resources/application-local.yaml
travel_Api/src/main/resources/serviceAccountKey.json
travel_Api/uploads/
Travel_App/lib/core/constants/api_keys.dart
Travel_App/android/app/google-services.json
Travel_App/android/secrets.properties
```

Chỉ commit các file `.example`.

Kiểm tra trước khi push:

```powershell
git status --short
git ls-files | findstr /i "api_keys google-services serviceAccountKey secrets.properties application-local .env"
```

Kết quả mong muốn: chỉ thấy file `.example`, không thấy secret thật.

## Kiểm Tra Trước Khi Bàn Giao

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

Smoke test thủ công:

- Mở app không đăng nhập, Home/Search/Detail tải dữ liệu.
- Đăng nhập USER thường, viết review/favorite được, không thấy trang quản trị.
- Đăng nhập ADMIN, thấy trang quản trị trong Hồ sơ.
- ADMIN thêm/sửa/xóa địa điểm mới.
- ADMIN thêm/sửa/xóa danh mục chưa được sử dụng.
- ADMIN xem thống kê overview/top-rated/top-favorited/by-category.
- Tắt backend sau khi đã cache, Home/Search/Detail vẫn đọc được text/metadata offline.

## Kịch Bản Push GitHub Bàn Giao

1. Kiểm tra nhánh hiện tại:

```powershell
git branch --show-current
git status --short
```

2. Chạy test:

```powershell
cd Travel_App
flutter analyze
flutter test
cd ..\travel_Api
.\mvnw.cmd test
cd ..
```

3. Kiểm tra secret:

```powershell
git ls-files | findstr /i "api_keys google-services serviceAccountKey secrets.properties application-local .env"
```

Nếu thấy file thật, gỡ khỏi Git index nhưng giữ file local:

```powershell
git rm --cached Travel_App\lib\core\constants\api_keys.dart
git rm --cached Travel_App\android\app\google-services.json
git rm --cached Travel_App\android\secrets.properties
git rm --cached travel_Api\src\main\resources\serviceAccountKey.json
git rm --cached travel_Api\src\main\resources\application-local.yaml
```

4. Add source và README:

```powershell
git add README.md Travel_App travel_Api docker-compose.yml .gitignore .env.example
git status --short
```

5. Commit:

```powershell
git commit -m "Finalize handover docs and admin authorization"
```

6. Push:

```powershell
git push origin <ten-nhanh>
```

Với repo bàn giao cho nhóm khác, nên tạo tag:

```powershell
git tag handover-v1
git push origin handover-v1
```

## Ghi Chú Khi Nộp Source ZIP

Nếu nộp ZIP cho thầy hoặc bàn giao nội bộ cần chạy ngay, có thể kèm file config thật. Không kèm các thư mục nặng/cache:

```text
.git/
Travel_App/build/
Travel_App/.dart_tool/
Travel_App/android/.gradle/
travel_Api/target/
```
