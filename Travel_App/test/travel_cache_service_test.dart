import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:travel_app/core/data/destination_model.dart';
import 'package:travel_app/core/data/travel_cache_service.dart';

void main() {
  late TravelCacheService cache;

  setUp(() {
    sqfliteFfiInit();
    cache = TravelCacheService.forTest(
      databaseFactory: databaseFactoryFfi,
      databaseName: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await cache.close();
  });

  DestinationModel place({
    required int id,
    required String title,
    required String city,
    required String district,
    required String placeType,
    required String priceLevel,
    required double rating,
    double? latitude,
    double? longitude,
  }) {
    return DestinationModel.fromJson({
      'id': id,
      'title': title,
      'subtitle': '',
      'description': '$title description',
      'imageUrl': '',
      'region': city,
      'city': city,
      'district': district,
      'address': district,
      'placeType': placeType,
      'priceLevel': priceLevel,
      'categoryName': placeType,
      'tags': '$city,$district,$placeType',
      'rating': rating,
      'reviewCount': rating > 0 ? 5 : 0,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  test('upsertDestinations replaces rows by id', () async {
    await cache.upsertDestinations([
      place(
        id: 1,
        title: 'Old title',
        city: 'TP.HCM',
        district: 'Quan 1',
        placeType: 'FOOD',
        priceLevel: 'BUDGET',
        rating: 4,
      ),
      place(
        id: 1,
        title: 'New title',
        city: 'TP.HCM',
        district: 'Quan 1',
        placeType: 'FOOD',
        priceLevel: 'BUDGET',
        rating: 4.5,
      ),
    ]);

    final rows = await cache.getAllDestinations();

    expect(rows, hasLength(1));
    expect(rows.single.title, 'New title');
    expect(rows.single.rating, 4.5);
  });

  test(
    'searchDestinations filters city district type price and rating',
    () async {
      await cache.upsertDestinations([
        place(
          id: 1,
          title: 'Ben Thanh food',
          city: 'TP.HCM',
          district: 'Quan 1',
          placeType: 'FOOD',
          priceLevel: 'BUDGET',
          rating: 4.6,
        ),
        place(
          id: 2,
          title: 'Beach hotel',
          city: 'Vung Tau',
          district: 'Bai Sau',
          placeType: 'HOTEL',
          priceLevel: 'PREMIUM',
          rating: 4.2,
        ),
      ]);

      final results = await cache.searchDestinations(
        q: 'food',
        city: 'TP.HCM',
        district: 'Quan 1',
        placeType: 'FOOD',
        priceLevel: 'BUDGET',
        minRating: 4.5,
      );

      expect(results.map((item) => item.id), [1]);
    },
  );

  test('searchDestinations supports nearby distance filtering', () async {
    await cache.upsertDestinations([
      place(
        id: 1,
        title: 'Anchor',
        city: 'TP.HCM',
        district: 'Quan 1',
        placeType: 'ENTERTAINMENT',
        priceLevel: 'FREE',
        rating: 4,
        latitude: 10.0,
        longitude: 106.0,
      ),
      place(
        id: 2,
        title: 'Near food',
        city: 'TP.HCM',
        district: 'Quan 1',
        placeType: 'FOOD',
        priceLevel: 'BUDGET',
        rating: 4,
        latitude: 10.005,
        longitude: 106.005,
      ),
      place(
        id: 3,
        title: 'Far food',
        city: 'TP.HCM',
        district: 'Quan 3',
        placeType: 'FOOD',
        priceLevel: 'BUDGET',
        rating: 4,
        latitude: 11.0,
        longitude: 107.0,
      ),
    ]);

    final results = await cache.searchDestinations(
      nearId: 1,
      radiusKm: 2,
      placeType: 'FOOD',
      sortBy: 'distance',
    );

    expect(results.map((item) => item.id), [2]);
    expect(results.single.distanceKm, isNotNull);
  });
}
