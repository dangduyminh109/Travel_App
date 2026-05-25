import 'dart:math';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'category_model.dart';
import 'destination_model.dart';

class TravelCacheService {
  static final TravelCacheService _instance = TravelCacheService._internal();

  factory TravelCacheService() => _instance;

  TravelCacheService._internal({
    DatabaseFactory? databaseFactory,
    String databaseName = 'travel_cache.db',
  }) : _databaseFactory = databaseFactory,
       _databaseName = databaseName;

  TravelCacheService.forTest({
    required DatabaseFactory databaseFactory,
    required String databaseName,
  }) : _databaseFactory = databaseFactory,
       _databaseName = databaseName;

  final DatabaseFactory? _databaseFactory;
  final String _databaseName;
  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _initDb() async {
    final factory = _databaseFactory ?? databaseFactory;
    final dbPath = _databaseFactory == null
        ? join(await getDatabasesPath(), _databaseName)
        : _databaseName;
    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE destinations (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        description TEXT,
        imageUrl TEXT,
        region TEXT,
        city TEXT,
        district TEXT,
        address TEXT,
        placeType TEXT,
        priceLevel TEXT,
        minPrice INTEGER,
        maxPrice INTEGER,
        openingHours TEXT,
        highlights TEXT,
        suitableFor TEXT,
        categoryId INTEGER,
        categoryName TEXT,
        tags TEXT,
        rating REAL DEFAULT 0,
        reviewCount INTEGER DEFAULT 0,
        latitude REAL,
        longitude REAL,
        rawJson TEXT NOT NULL,
        cachedAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_destinations_city ON destinations(city)',
    );
    await db.execute(
      'CREATE INDEX idx_destinations_district ON destinations(district)',
    );
    await db.execute(
      'CREATE INDEX idx_destinations_place_type ON destinations(placeType)',
    );
    await db.execute(
      'CREATE INDEX idx_destinations_price_level ON destinations(priceLevel)',
    );
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        rawJson TEXT NOT NULL,
        cachedAt INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_meta (
        key TEXT PRIMARY KEY,
        value TEXT,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> upsertDestinations(List<DestinationModel> destinations) async {
    if (destinations.isEmpty) return;
    final database = await db;
    final cachedAt = DateTime.now().millisecondsSinceEpoch;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final destination in destinations) {
        batch.insert(
          'destinations',
          destination.toCacheMap(cachedAt: cachedAt),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert('cache_meta', {
        'key': 'lastDestinationSync',
        'value': cachedAt.toString(),
        'updatedAt': cachedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertDestination(DestinationModel destination) {
    return upsertDestinations([destination]);
  }

  Future<void> upsertCategories(List<CategoryModel> categories) async {
    if (categories.isEmpty) return;
    final database = await db;
    final cachedAt = DateTime.now().millisecondsSinceEpoch;
    await database.transaction((txn) async {
      final batch = txn.batch();
      for (final category in categories) {
        batch.insert(
          'categories',
          category.toCacheMap(cachedAt: cachedAt),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert('cache_meta', {
        'key': 'lastCategorySync',
        'value': cachedAt.toString(),
        'updatedAt': cachedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Future<List<DestinationModel>> getAllDestinations() async {
    final database = await db;
    final rows = await database.query('destinations', orderBy: 'id DESC');
    return rows.map(DestinationModel.fromCacheMap).toList();
  }

  Future<DestinationModel?> getDestinationById(int id) async {
    final database = await db;
    final rows = await database.query(
      'destinations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DestinationModel.fromCacheMap(rows.first);
  }

  Future<List<CategoryModel>> getCategories() async {
    final database = await db;
    final rows = await database.query('categories', orderBy: 'id ASC');
    return rows.map(CategoryModel.fromCacheMap).toList();
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
    final allPlaces = await getAllDestinations();
    DestinationModel? anchor;
    if (nearId != null) {
      anchor = allPlaces.where((place) => place.id == nearId).firstOrNull;
      if (anchor == null ||
          anchor.latitude == null ||
          anchor.longitude == null) {
        return [];
      }
    }

    final query = _normalize(q);
    final normalizedCity = _normalize(city);
    final normalizedDistrict = _normalize(district);
    final normalizedPlaceType = _normalize(placeType);
    final normalizedPriceLevel = _normalize(priceLevel);
    final normalizedCategory = _normalize(category);
    final maxDistance = nearId == null ? null : (radiusKm ?? 3);

    var results = <DestinationModel>[];
    for (final place in allPlaces) {
      if (nearId != null && place.id == nearId) continue;
      if (query.isNotEmpty && !_matchesText(place, query)) continue;
      if (normalizedCity.isNotEmpty &&
          _normalize(place.city) != normalizedCity &&
          _normalize(place.region) != normalizedCity) {
        continue;
      }
      if (normalizedDistrict.isNotEmpty &&
          _normalize(place.district) != normalizedDistrict) {
        continue;
      }
      if (normalizedPlaceType.isNotEmpty &&
          _normalize(place.placeType) != normalizedPlaceType) {
        continue;
      }
      if (normalizedPriceLevel.isNotEmpty &&
          _normalize(place.priceLevel) != normalizedPriceLevel) {
        continue;
      }
      if (normalizedCategory.isNotEmpty &&
          _normalize(place.categoryName) != normalizedCategory) {
        continue;
      }
      if (minRating != null && place.rating < minRating) continue;

      var result = place;
      if (anchor != null && maxDistance != null) {
        final distance = _distanceKm(anchor, place);
        if (distance == null || distance > maxDistance) continue;
        result = place.copyWith(distanceKm: distance);
      }
      results.add(result);
    }

    _sort(results, sortBy ?? (nearId == null ? 'relevance' : 'distance'));
    return results;
  }

  bool _matchesText(DestinationModel place, String query) {
    final values = [
      place.title,
      place.subtitle,
      place.description,
      place.region,
      place.city,
      place.district,
      place.address,
      place.categoryName,
      place.tags,
      place.highlights,
      place.suitableFor,
      place.placeTypeLabel,
      place.priceLevelLabel,
    ];
    return values.any((value) => _normalize(value).contains(query));
  }

  void _sort(List<DestinationModel> results, String sortBy) {
    switch (sortBy) {
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        results.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'price_asc':
        results.sort((a, b) => _sortPrice(a).compareTo(_sortPrice(b)));
        break;
      case 'price_desc':
        results.sort((a, b) => _sortPrice(b).compareTo(_sortPrice(a)));
        break;
      case 'distance':
        results.sort(
          (a, b) => (a.distanceKm ?? double.infinity).compareTo(
            b.distanceKm ?? double.infinity,
          ),
        );
        break;
      default:
        results.sort((a, b) => b.rating.compareTo(a.rating));
    }
  }

  int _sortPrice(DestinationModel place) {
    return place.minPrice ?? place.maxPrice ?? 1 << 30;
  }

  double? _distanceKm(DestinationModel from, DestinationModel to) {
    final lat1 = from.latitude;
    final lon1 = from.longitude;
    final lat2 = to.latitude;
    final lon2 = to.longitude;
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  String _normalize(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
