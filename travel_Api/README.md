# travel_Api - Backend Spring Boot

Backend cung cấp REST API cho ứng dụng Travel App. Dữ liệu chính được lưu trong MySQL, Firebase Admin dùng để đẩy review/reply/reaction/notification lên Firebase Realtime Database.

## Công Nghệ

- Java 21
- Spring Boot 4
- Spring Data JPA
- Spring Security
- MySQL 8
- Firebase Admin SDK
- Swagger/OpenAPI qua Springdoc

## Cấu Trúc Chính

- `config`: cấu hình Firebase, Security, CORS, static uploads và seed data.
- `controller`: REST API cho categories, destinations, reviews, favorites, users và image proxy.
- `dto`: object trả về/nhận vào từ API.
- `entity`: JPA entities như `Destination`, `Category`, `Review`, `Reply`, `Favorite`, `User`.
- `repository`: Spring Data repository.
- `service`: logic hỗ trợ search/filter, Firebase Realtime và user profile.
- `src/main/resources`: cấu hình runtime và Firebase service account local.

## API Chính

- `GET /api/destinations`: danh sách địa điểm.
- `GET /api/destinations/{id}`: chi tiết địa điểm.
- `GET /api/destinations/search`: search/filter theo `q`, `city`, `district`, `placeType`, `priceLevel`, `minRating`, `nearId`, `radiusKm`, `sortBy`.
- `GET /api/destinations/latest`: địa điểm mới/nổi bật.
- `GET /api/destinations/by-category/{category}`: lọc theo danh mục.
- `GET /api/categories`: danh mục.
- `GET/POST/PUT/DELETE /api/destinations/{id}/reviews`: đánh giá địa điểm.
- `POST/PUT/DELETE /api/destinations/reviews/{reviewId}/replies`: phản hồi đánh giá.
- `POST /api/destinations/reviews/{reviewId}/like`: like/dislike review.
- `GET/POST/DELETE /api/users/{userId}/favorites`: yêu thích.
- `GET/PUT /api/users/{username}`: hồ sơ người dùng.
- `GET /api/images/proxy?url=...`: proxy ảnh ngoài internet.

## Cấu Hình

File chính: `src/main/resources/application.yaml`.

Backend hỗ trợ override bằng biến môi trường hoặc file ignored `src/main/resources/application-local.yaml`.

Các biến quan trọng:

```text
DB_URL
DB_USERNAME
DB_PASSWORD
JWT_SECRET
JWT_EXPIRATION
FIREBASE_SERVICE_ACCOUNT_PATH
FIREBASE_DATABASE_URL
```

File Firebase Admin thật cần nằm ở:

```text
src/main/resources/serviceAccountKey.json
```

Nếu lấy source từ GitHub/public, copy:

```powershell
copy src\main\resources\serviceAccountKey.example.json src\main\resources\serviceAccountKey.json
copy src\main\resources\application.example.yaml src\main\resources\application-local.yaml
```

Sau đó điền thông tin thật. Nếu dùng gói nộp thầy, các file thật có thể đã được kèm sẵn.

## Chạy Backend

Từ thư mục cha, chạy MySQL:

```powershell
docker compose up -d
```

Từ thư mục backend:

```powershell
.\mvnw.cmd spring-boot:run
```

Backend chạy ở:

```text
http://localhost:8080
```

Swagger UI nếu bật:

```text
http://localhost:8080/swagger-ui.html
```

## Database Và Seed

- Database mặc định: `travel_db`.
- Backend dùng `spring.jpa.hibernate.ddl-auto=update`.
- `DataSeeder` tự thêm danh mục và địa điểm TP.HCM/Vũng Tàu.
- Seed dùng upsert, không xóa destination/review/favorite cũ để tránh đứt liên kết dữ liệu người dùng.

## Kiểm Tra

```powershell
.\mvnw.cmd test
```

Một số API nên test thủ công:

```text
GET http://localhost:8080/api/destinations
GET http://localhost:8080/api/destinations/search?city=TP.HCM&placeType=FOOD
GET http://localhost:8080/api/destinations/search?nearId=1&radiusKm=2&sortBy=distance
GET http://localhost:8080/api/categories
```

## Lưu Ý Bảo Mật

Không public các file thật sau:

- `src/main/resources/serviceAccountKey.json`
- `src/main/resources/application-local.yaml`
- `.env`
- thư mục `uploads/`
