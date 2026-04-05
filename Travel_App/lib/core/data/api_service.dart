import 'dart:convert';
import 'package:http/http.dart' as http;
import 'category_model.dart';
import 'destination_model.dart';
import 'review_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _baseUrl = 'http://10.0.2.2:8080/api';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<DestinationModel>> getTrending({int limit = 6}) async {
    final uri = Uri.parse('$_baseUrl/destinations/latest?limit=$limit');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<DestinationModel> getFeatured() async {
    final uri = Uri.parse('$_baseUrl/destinations/latest?limit=1');
    final response = await http.get(uri, headers: _headers);
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
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<List<DestinationModel>> search(String keyword) async {
    final uri = Uri.parse(
      '$_baseUrl/destinations/search?q=${Uri.encodeQueryComponent(keyword)}',
    );
    final response = await http.get(uri, headers: _headers);
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
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodeList(
      response.body,
      (item) => DestinationModel.fromJson(item),
    );
  }

  Future<DestinationModel> getById(int id) async {
    final uri = Uri.parse('$_baseUrl/destinations/$id');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return DestinationModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/categories');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodeList(response.body, (item) => CategoryModel.fromJson(item));
  }

  Future<List<ReviewModel>> getReviews(int destinationId) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodeList(response.body, (item) => ReviewModel.fromJson(item));
  }

  Future<List<ReviewModel>> getUserReviews(String username) async {
    final uri = Uri.parse('$_baseUrl/users/$username/reviews');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 404) return [];
    _assertOk(response);
    return _decodeList(response.body, (item) => ReviewModel.fromJson(item));
  }

  Future<ReviewModel> addReview(
    int destinationId,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(payload),
    );
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ReviewModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<ReviewModel> updateReview(int destinationId, int reviewId, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews/$reviewId');
    final response = await http.put(uri, headers: _headers, body: jsonEncode(payload));
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ReviewModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReview(int destinationId, int reviewId) async {
    final uri = Uri.parse('$_baseUrl/destinations/$destinationId/reviews/$reviewId');
    final response = await http.delete(uri, headers: _headers);
    _assertOk(response);
  }

  Future<List<int>> getFavoriteIds(String userId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites');
    final response = await http.get(uri, headers: _headers);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<List<int>> addFavorite(String userId, int destinationId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites/$destinationId');
    final response = await http.post(uri, headers: _headers);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<List<int>> removeFavorite(String userId, int destinationId) async {
    final uri = Uri.parse('$_baseUrl/users/$userId/favorites/$destinationId');
    final response = await http.delete(uri, headers: _headers);
    _assertOk(response);
    return _decodePrimitiveList<int>(
      response.body,
      (value) => (value as num).toInt(),
    );
  }

  Future<Map<String, dynamic>> getUserProfile(String username) async {
    final uri = Uri.parse('$_baseUrl/users/$username');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 404) return {}; // Handle not found gracefully
    _assertOk(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> syncUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/sync');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
      }),
    );
    _assertOk(response);
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String username,
    String? fullName,
    String? avatarPath,
  }) async {
    final uri = Uri.parse('$_baseUrl/users/$username');
    final request = http.MultipartRequest('PUT', uri);

    if (fullName != null && fullName.isNotEmpty) {
      request.fields['fullName'] = fullName;
    }

    if (avatarPath != null && avatarPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _assertOk(response);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
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

  void _assertOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }
  }
}
