import 'api_service.dart';
import 'cached_result.dart';
import 'category_model.dart';
import 'destination_model.dart';
import 'travel_cache_service.dart';

class TravelRepository {
  static final TravelRepository _instance = TravelRepository._internal();

  factory TravelRepository() => _instance;

  TravelRepository._internal({
    ApiService? apiService,
    TravelCacheService? cacheService,
  }) : _api = apiService ?? ApiService(),
       _cache = cacheService ?? TravelCacheService();

  TravelRepository.forTest({
    required ApiService apiService,
    required TravelCacheService cacheService,
  }) : _api = apiService,
       _cache = cacheService;

  final ApiService _api;
  final TravelCacheService _cache;

  static const _cacheEmptyMessage =
      'Chưa có dữ liệu offline. '
      'Hãy mở app khi có mạng một lần.';
  static const _offlineMessage = 'Đang xem dữ liệu offline';

  Future<CachedResult<List<DestinationModel>>> getAll() async {
    try {
      final data = await _api.getAll();
      await _cache.upsertDestinations(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.getAllDestinations();
      return CachedResult.cache(
        cached,
        message: cached.isEmpty ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }

  Future<CachedResult<List<DestinationModel>>> getTrending({
    int limit = 6,
  }) async {
    try {
      final data = await _api.getTrending(limit: limit);
      await _cache.upsertDestinations(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.getAllDestinations();
      final sorted = [...cached]..sort((a, b) => b.rating.compareTo(a.rating));
      return CachedResult.cache(
        sorted.take(limit).toList(),
        message: cached.isEmpty ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }

  Future<CachedResult<DestinationModel?>> getFeatured() async {
    try {
      final data = await _api.getFeatured();
      await _cache.upsertDestination(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.getAllDestinations();
      if (cached.isEmpty) {
        return const CachedResult.cache(null, message: _cacheEmptyMessage);
      }
      final sorted = [...cached]..sort((a, b) => b.rating.compareTo(a.rating));
      return CachedResult.cache(sorted.first, message: _offlineMessage);
    }
  }

  Future<CachedResult<DestinationModel?>> getById(int id) async {
    try {
      final data = await _api.getById(id);
      await _cache.upsertDestination(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.getDestinationById(id);
      return CachedResult.cache(
        cached,
        message: cached == null ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }

  Future<CachedResult<List<CategoryModel>>> getCategories() async {
    try {
      final data = await _api.getCategories();
      await _cache.upsertCategories(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.getCategories();
      return CachedResult.cache(
        cached,
        message: cached.isEmpty ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }

  Future<CachedResult<List<DestinationModel>>> getByCategory(
    String category,
  ) async {
    try {
      final data = await _api.getByCategory(category);
      await _cache.upsertDestinations(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.searchDestinations(
        category: category == 'T\u1ea5t c\u1ea3' ? null : category,
      );
      return CachedResult.cache(
        cached,
        message: cached.isEmpty ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }

  Future<CachedResult<List<DestinationModel>>> searchDestinations({
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
    try {
      final data = await _api.searchDestinations(
        q: q,
        city: city,
        district: district,
        placeType: placeType,
        priceLevel: priceLevel,
        category: category,
        minRating: minRating,
        nearId: nearId,
        radiusKm: radiusKm,
        sortBy: sortBy,
      );
      await _cache.upsertDestinations(data);
      return CachedResult.network(data);
    } catch (_) {
      final cached = await _cache.searchDestinations(
        q: q,
        city: city,
        district: district,
        placeType: placeType,
        priceLevel: priceLevel,
        category: category,
        minRating: minRating,
        nearId: nearId,
        radiusKm: radiusKm,
        sortBy: sortBy,
      );
      return CachedResult.cache(
        cached,
        message: cached.isEmpty ? _cacheEmptyMessage : _offlineMessage,
      );
    }
  }
}
