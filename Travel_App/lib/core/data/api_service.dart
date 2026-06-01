import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'category_model.dart';
import 'destination_model.dart';
import 'review_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'http://10.0.2.2:8080/api';
  static const Duration _requestTimeout = Duration(seconds: 5);

  Future<Map<String, String>> _headers({
    bool jsonContent = true,
    bool includeAuth = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonContent) {
      headers['Content-Type'] = 'application/json';
    }
    if (includeAuth) {
      final token = await _firebaseToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<String?> _firebaseToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DestinationModel>> getTrending({int limit = 6}) async {
    final uri = Uri.parse('$_baseUrl/destinations/latest?limit=$limit');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<DestinationModel> getFeatured() async {
    final uri = Uri.parse('$_baseUrl/destinations/latest?limit=1');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    final data = _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
    if (data.isEmpty) throw Exception('No featured destination found');
    return data.first;
  }

  Future<List<DestinationModel>> getAll() async {
    final uri = Uri.parse('$_baseUrl/destinations');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<List<DestinationModel>> search(String keyword) async {
    return searchDestinations(q: keyword);
  }

  Future<List<DestinationModel>> searchDestinations({
    String? q,
    String? city,
    String? district,
    String? placeType,
    String? priceLevel,
    String? category,
    double? minRating,
    int? nearId,
    double? radiusKm,
    String? sortBy,
  }) async {
    final queryParameters = <String, String>{};
    void addParam(String key, Object? value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      queryParameters[key] = text;
    }

    addParam('q', q);
    addParam('city', city);
    addParam('district', district);
    addParam('placeType', placeType);
    addParam('priceLevel', priceLevel);
    addParam('category', category);
    addParam('minRating', minRating);
    addParam('nearId', nearId);
    addParam('radiusKm', radiusKm);
    addParam('sortBy', sortBy);

    final uri = Uri.parse('$_baseUrl/destinations/search').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<List<DestinationModel>> getByCategory(String category) async {
    final Uri uri;
    if (category == 'Tất cả') {
      uri = Uri.parse('$_baseUrl/destinations');
    } else {
      uri = Uri.parse(
        '$_baseUrl/destinations/by-category/${Uri.encodeQueryComponent(category)}',
      );
    }
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<DestinationModel> getById(int id) async {
    final uri = Uri.parse('$_baseUrl/destinations/$id');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DestinationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/categories');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(response.body, (item) => CategoryModel.fromJson(item));
  }

  Future<List<ReviewModel>> getReviews(int destinationId) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews');
    final response = await _get(uri, auth: false);
    _assertOk(response);
    return _decodeList(response.body, (item) => ReviewModel.fromJson(item));
  }

  Future<List<ReviewModel>> getUserReviews(String username) async {
    final uri = Uri.parse('$_baseUrl/users/$username/reviews');
    final response = await _get(uri);
    if (response.statusCode == 404) return [];
    _assertOk(response);
    return _decodeList(response.body, (item) => ReviewModel.fromJson(item));
  }

  Future<ReviewModel> addReview(
    int destinationId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews');
    final response = await _post(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ReviewModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ReviewModel> updateReview(
    int destinationId,
    int reviewId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/$destinationId/reviews/$reviewId',
    );
    final response = await _put(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ReviewModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReview(int destinationId, int reviewId) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/$destinationId/reviews/$reviewId',
    );
    final response = await _delete(uri);
    _assertOk(response);
  }

  Future<void> addReply(int reviewId, String userId, String content) async {
    final uri = Uri.parse('$_baseUrl/destinations/reviews/$reviewId/replies');
    final response = await _post(
      uri,
      body: jsonEncode({'userId': userId, 'comment': content}),
    );
    _assertOk(response);
  }

  Future<void> updateReply(
    int reviewId,
    int replyId,
    String userId,
    String content,
  ) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/reviews/$reviewId/replies/$replyId?userId=$userId',
    );
    final response = await _put(
      uri,
      body: jsonEncode({'userId': userId, 'comment': content}),
    );
    _assertOk(response);
  }

  Future<Map<String, dynamic>> toggleLike(
    int reviewId,
    String userId, {
    String type = 'LIKE',
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/reviews/$reviewId/like?userId=$userId&type=$type',
    );
    final response = await _post(uri);
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> deleteReply(int reviewId, int replyId, String userId) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/reviews/$reviewId/replies/$replyId?userId=$userId',
    );
    final response = await _delete(uri);
    _assertOk(response);
  }

  Future<List<int>> getFavoriteIds(String userId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites');
    final response = await _get(uri);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<List<int>> addFavorite(String userId, int destinationId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites/$destinationId');
    final response = await _post(uri);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<List<int>> removeFavorite(String userId, int destinationId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites/$destinationId');
    final response = await _delete(uri);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<Map<String, dynamic>> getUserProfile(String username) async {
    final uri = Uri.parse('$_baseUrl/users/$username');
    final response = await _get(uri);
    if (response.statusCode == 404) return {};
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/sync');
    final payload = {'uid': uid, 'email': email, 'displayName': displayName};
    if (photoUrl != null) {
      payload['photoUrl'] = photoUrl;
    }

    final response = await _post(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    String? fullName,
    String? avatarPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/$username');
    final request = http.MultipartRequest('PUT', uri);
    request.headers.addAll(await _headers(jsonContent: false));

    if (fullName != null && fullName.isNotEmpty) {
      request.fields['fullName'] = fullName;
    }

    if (avatarPath != null && avatarPath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatarPath),
      );
    }

    final streamedResponse = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    _assertOk(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<DestinationModel> createAdminDestination(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/admin/destinations');
    final response = await _post(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DestinationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<DestinationModel> updateAdminDestination(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/admin/destinations/$id');
    final response = await _put(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DestinationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAdminDestination(int id) async {
    final uri = Uri.parse('$_baseUrl/admin/destinations/$id');
    final response = await _delete(uri);
    _assertOk(response);
  }

  Future<CategoryModel> createAdminCategory(
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/admin/categories');
    final response = await _post(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CategoryModel> updateAdminCategory(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/admin/categories/$id');
    final response = await _put(uri, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CategoryModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAdminCategory(int id) async {
    final uri = Uri.parse('$_baseUrl/admin/categories/$id');
    final response = await _delete(uri);
    _assertOk(response);
  }

  Future<Map<String, dynamic>> getAdminOverview() async {
    final uri = Uri.parse('$_baseUrl/admin/statistics/overview');
    final response = await _get(uri);
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminTopRated() async {
    final uri = Uri.parse('$_baseUrl/admin/statistics/top-rated');
    return _getAdminMapList(uri);
  }

  Future<List<Map<String, dynamic>>> getAdminTopFavorited() async {
    final uri = Uri.parse('$_baseUrl/admin/statistics/top-favorited');
    return _getAdminMapList(uri);
  }

  Future<List<Map<String, dynamic>>> getAdminByCategory() async {
    final uri = Uri.parse('$_baseUrl/admin/statistics/by-category');
    return _getAdminMapList(uri);
  }

  Future<List<Map<String, dynamic>>> _getAdminMapList(Uri uri) async {
    final response = await _get(uri);
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  List<T> _decodeList<T>(String body, T Function(Map<String, dynamic>) mapper) {
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>? ?? [];
    return data.map((e) => mapper(e as Map<String, dynamic>)).toList();
  }

  List<T> _decodePrimitiveList<T>(
    String body,
    T Function(dynamic value) mapper,
  ) {
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final data = payload['data'] as List<dynamic>? ?? [];
    return data.map(mapper).toList();
  }

  Future<http.Response> _get(Uri uri, {bool auth = true}) {
    return _headers(includeAuth: auth).then(
      (headers) => http.get(uri, headers: headers).timeout(_requestTimeout),
    );
  }

  Future<http.Response> _post(Uri uri, {Object? body}) {
    return _headers().then(
      (headers) =>
          http.post(uri, headers: headers, body: body).timeout(_requestTimeout),
    );
  }

  Future<http.Response> _put(Uri uri, {Object? body}) {
    return _headers().then(
      (headers) =>
          http.put(uri, headers: headers, body: body).timeout(_requestTimeout),
    );
  }

  Future<http.Response> _delete(Uri uri) {
    return _headers().then(
      (headers) => http.delete(uri, headers: headers).timeout(_requestTimeout),
    );
  }

  void _assertOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
