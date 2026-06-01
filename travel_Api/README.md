# travel_Api - Spring Boot Backend

Backend cung cấp REST API cho Travel App. Dữ liệu chính lưu trong MySQL, xác thực dùng Firebase ID token, role lưu trong bảng `users`.

## Công Nghệ

- Java 21
- Spring Boot 4
- Spring Data JPA
- Spring Security
- MySQL 8
- Firebase Admin SDK
- Springdoc OpenAPI

## Cấu Trúc Thư Mục

```text
src/main/java/com/vn/huit/travelApp
├── config        # Firebase, Security, CORS, seed data
├── controller    # REST controllers
├── dto           # Request/response DTO
├── entity        # JPA entities
├── repository    # Spring Data repositories
├── security      # Firebase token filter, principal
└── service       # Business logic, search, auth helper, realtime
```

## Cấu Hình Local

File chính:

```text
src/main/resources/application.yaml
```

File local ignored:

```text
src/main/resources/application-local.yaml
```

Backend tự import `application-local.yaml` nếu file tồn tại:

```yaml
spring:
  config:
    import: optional:file:src/main/resources/application-local.yaml
```

Các biến quan trọng:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
FIREBASE_SERVICE_ACCOUNT_PATH
FIREBASE_DATABASE_URL
JWT_SECRET
JWT_EXPIRATION
ADMIN_EMAILS
```

Ví dụ `application-local.yaml`:

```yaml
firebase:
  service-account-path: src/main/resources/serviceAccountKey.json
  database-url: https://<project-id>-default-rtdb.asia-southeast1.firebasedatabase.app

app:
  admin-emails: admin1@example.com,admin2@example.com
```

Firebase Admin service account thật đặt tại:

```text
src/main/resources/serviceAccountKey.json
```

Nếu pull từ GitHub, copy file mẫu:

```powershell
copy src\main\resources\application.example.yaml src\main\resources\application-local.yaml
copy src\main\resources\serviceAccountKey.example.json src\main\resources\serviceAccountKey.json
```

## Chạy Backend

Từ thư mục cha chạy MySQL:

```powershell
docker compose up -d
```

Từ thư mục `travel_Api`:

```powershell
.\mvnw.cmd spring-boot:run
```

Backend chạy tại:

```text
http://localhost:8080
```

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

## Phân Quyền

Backend dùng Firebase ID token. Client gửi token qua header:

```text
Authorization: Bearer <firebase_id_token>
```

Các class chính:

- `config/SecurityConfig.java`: khai báo rule public/user/admin.
- `security/FirebaseAuthenticationFilter.java`: verify token bằng Firebase Admin SDK.
- `security/FirebaseUserPrincipal.java`: principal chứa `uid`, `email`, `name`, `role`.
- `service/AuthenticatedUserService.java`: lấy user hiện tại, kiểm tra chính chủ hoặc admin.
- `service/UserService.java`: sync user và gán role theo email admin.

### Rule Hiện Tại

| API | Quyền |
| --- | --- |
| `GET /api/destinations/**` | Public |
| `GET /api/categories/**` | Public |
| `GET /api/images/**` | Public |
| `POST /api/users/sync` | Đã đăng nhập Firebase |
| `/api/users/**` | Đã đăng nhập, chính chủ hoặc ADMIN tùy endpoint |
| `POST/PUT/DELETE /api/destinations/**` | Đã đăng nhập |
| `/api/admin/**` | Role `ADMIN` |

### Cách Tạo Admin

1. Tạo tài khoản trong Firebase Authentication.
2. Thêm email vào cấu hình:

```yaml
app:
  admin-emails: admin@example.com
```

hoặc:

```powershell
$env:ADMIN_EMAILS="admin@example.com"
```

3. Đăng nhập app bằng email đó.
4. App gọi `POST /api/users/sync`.
5. Backend lưu user với role `ADMIN`.

Nếu user đã tồn tại là `USER`, khi email được thêm vào `admin-emails` và sync lại, backend sẽ nâng role thành `ADMIN`.

## Admin API

Các API dưới đây yêu cầu role `ADMIN`:

```text
POST   /api/admin/destinations
PUT    /api/admin/destinations/{id}
DELETE /api/admin/destinations/{id}

POST   /api/admin/categories
PUT    /api/admin/categories/{id}
DELETE /api/admin/categories/{id}

GET    /api/admin/statistics/overview
GET    /api/admin/statistics/top-rated
GET    /api/admin/statistics/top-favorited
GET    /api/admin/statistics/by-category
```

Ràng buộc chính:

- Destination bắt buộc có `title`, `description`, `city`, `placeType`, `priceLevel`, `categoryId`.
- `placeType`: `FOOD`, `ENTERTAINMENT`, `HOTEL`, `CAFE`, `CULTURE_HISTORY`, `SHOPPING`.
- `priceLevel`: `FREE`, `BUDGET`, `MODERATE`, `PREMIUM`, `LUXURY`.
- `minPrice <= maxPrice`.
- Rating nếu nhập phải trong khoảng `0..5`.
- Không xóa destination đã có review/favorite.
- Không xóa category đang được destination sử dụng.

## Public API Chính

```text
GET /api/destinations
GET /api/destinations/{id}
GET /api/destinations/latest?limit=10
GET /api/destinations/by-category/{name}
GET /api/destinations/search?q=&city=&district=&placeType=&priceLevel=&minRating=&nearId=&radiusKm=&sortBy=
GET /api/categories
GET /api/images/proxy?url=<encoded-url>
```

Search nearby dùng `nearId` và tọa độ `latitude/longitude` trong database, tính khoảng cách bằng công thức Haversine. Kết quả có `distanceKm` khi dùng nearby.

## User/Review/Favorite API

Các API ghi dữ liệu cần đăng nhập:

```text
POST /api/users/sync
GET  /api/users/{username}
PUT  /api/users/{username}
GET  /api/users/{username}/reviews

POST /api/destinations/{destinationId}/reviews
PUT  /api/destinations/{destinationId}/reviews/{reviewId}
DELETE /api/destinations/{destinationId}/reviews/{reviewId}

POST /api/destinations/reviews/{reviewId}/replies
PUT  /api/destinations/reviews/{reviewId}/replies/{replyId}
DELETE /api/destinations/reviews/{reviewId}/replies/{replyId}

POST /api/destinations/reviews/{reviewId}/like
GET/POST/DELETE /api/users/{userId}/favorites
```

Backend kiểm tra chính chủ bằng Firebase UID, không nên tin `userId` client gửi lên cho các thao tác nhạy cảm.

## Database Và Seed

- Database mặc định: `travel_db`.
- `spring.jpa.hibernate.ddl-auto=update`.
- `DataSeeder` thêm/cập nhật danh mục và địa điểm TP.HCM/Vũng Tàu.
- Seeder không xóa destination/review/favorite cũ để tránh đứt khóa ngoại.

## Test

```powershell
.\mvnw.cmd test
```

Smoke test nhanh:

```text
GET http://localhost:8080/api/destinations
GET http://localhost:8080/api/destinations/search?city=TP.HCM&placeType=FOOD
GET http://localhost:8080/api/destinations/search?nearId=1&radiusKm=2&sortBy=distance
GET http://localhost:8080/api/categories
```

## File Không Được Commit Public

```text
src/main/resources/application-local.yaml
src/main/resources/serviceAccountKey.json
uploads/
target/
```

Chỉ commit:

```text
src/main/resources/application.example.yaml
src/main/resources/serviceAccountKey.example.json
```
