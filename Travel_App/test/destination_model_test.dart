import 'package:flutter_test/flutter_test.dart';
import 'package:travel_app/core/data/category_model.dart';
import 'package:travel_app/core/data/destination_model.dart';

void main() {
  test('DestinationModel parses legacy JSON without new metadata', () {
    final model = DestinationModel.fromJson({
      'id': 1,
      'title': 'Cho Ben Thanh',
      'subtitle': 'Market',
      'description': 'Historic market',
      'imageUrl': '/uploads/ben-thanh.jpg',
      'region': 'Mien Nam',
      'categoryId': 2,
      'categoryName': 'Van hoa',
      'tags': '',
      'rating': 4.5,
      'reviewCount': 12,
    });

    expect(model.city, isEmpty);
    expect(model.district, isEmpty);
    expect(model.placeTypeLabel, isEmpty);
    expect(model.priceRangeText, isEmpty);
    expect(model.highlightsList, isEmpty);
    expect(model.suitableForList, isEmpty);
    expect(model.tagsList, ['Van hoa']);
    expect(model.imageUrl, 'http://10.0.2.2:8080/uploads/ben-thanh.jpg');
    expect(model.hasReviews, isTrue);
    expect(model.ratingText, '4.5');
  });

  test('DestinationModel round-trips through cache map', () {
    final model = DestinationModel.fromJson({
      'id': 6,
      'title': 'Ho May Park',
      'subtitle': 'Vui choi',
      'description': 'Khu du lich tren nui',
      'imageUrl': 'https://example.com/ho-may.jpg',
      'region': 'Vung Tau',
      'city': 'Vung Tau',
      'district': 'Nui Lon',
      'address': '1A Tran Phu',
      'placeType': 'ENTERTAINMENT',
      'priceLevel': 'MODERATE',
      'minPrice': 200000,
      'maxPrice': 500000,
      'openingHours': '08:00 - 18:00',
      'highlights': 'cap treo,view bien',
      'suitableFor': 'gia dinh,nhom ban',
      'categoryId': 3,
      'categoryName': 'Vui choi',
      'tags': 'ho may,cap treo',
      'rating': 4.4,
      'reviewCount': 9,
      'latitude': 10.365,
      'longitude': 107.071,
      'distanceKm': 2.1,
    });

    final restored = DestinationModel.fromCacheMap(model.toCacheMap());

    expect(restored.id, model.id);
    expect(restored.title, model.title);
    expect(restored.city, model.city);
    expect(restored.placeType, model.placeType);
    expect(restored.priceLevel, model.priceLevel);
    expect(restored.latitude, model.latitude);
    expect(restored.longitude, model.longitude);
    expect(restored.distanceKm, isNull);
  });

  test('CategoryModel round-trips through cache map', () {
    const model = CategoryModel(id: 1, name: 'An uong', icon: 'restaurant');

    final restored = CategoryModel.fromCacheMap(model.toCacheMap());

    expect(restored.id, model.id);
    expect(restored.name, model.name);
    expect(restored.icon, model.icon);
  });

  test('DestinationModel exposes labels and parsed metadata lists', () {
    final model = DestinationModel.fromJson({
      'id': 2,
      'title': 'Banh mi Huynh Hoa',
      'subtitle': 'Banh mi',
      'description': 'Popular food spot',
      'imageUrl': 'https://example.com/banh-mi.jpg',
      'region': 'Mien Nam',
      'city': 'TP.HCM',
      'district': 'Quan 1',
      'address': '26 Le Thi Rieng',
      'placeType': 'FOOD',
      'priceLevel': 'BUDGET',
      'minPrice': 45000,
      'maxPrice': 75000,
      'openingHours': '06:00 - 22:00',
      'highlights': 'dac san, gan trung tam',
      'suitableFor': 'an nhanh, khach du lich',
      'categoryName': 'Am thuc',
      'tags': 'banh mi,duong pho',
      'rating': 4.7,
      'reviewCount': 30,
      'latitude': 10.0,
      'longitude': 106.0,
      'distanceKm': 1.24,
    });

    expect(model.placeTypeLabel, 'Ăn uống');
    expect(model.priceLevelLabel, 'Bình dân');
    expect(model.priceRangeText, '45.000đ - 75.000đ');
    expect(model.shortLocationText, 'Quan 1, TP.HCM');
    expect(model.fullAddressText, '26 Le Thi Rieng, Quan 1, TP.HCM');
    expect(model.highlightsList, ['dac san', 'gan trung tam']);
    expect(model.suitableForList, ['an nhanh', 'khach du lich']);
    expect(model.tagsList, ['banh mi', 'duong pho']);
    expect(model.hasReviews, isTrue);
    expect(model.reviewSummaryText, '(30 đánh giá)');
    expect(model.distanceText, '1.2km');
  });

  test('DestinationModel marks places without reviews clearly', () {
    final model = DestinationModel.fromJson({
      'id': 3,
      'title': 'New place',
      'subtitle': '',
      'description': '',
      'imageUrl': '',
      'region': 'TP.HCM',
      'categoryName': 'Cafe',
      'rating': 0,
      'reviewCount': 0,
    });

    expect(model.hasReviews, isFalse);
    expect(model.ratingText, isEmpty);
    expect(model.reviewSummaryText, 'Chưa có đánh giá');
  });

  test('DestinationModel avoids duplicated address parts', () {
    final model = DestinationModel.fromJson({
      'id': 4,
      'title': 'Ben Thanh Market',
      'subtitle': '',
      'description': '',
      'imageUrl': '',
      'region': '',
      'city': 'TP.HCM',
      'district': 'Quận 1',
      'address': 'Đường Lê Lợi, phường Bến Thành, Quận 1',
      'categoryName': 'Mua sắm',
    });

    expect(
      model.fullAddressText,
      'Đường Lê Lợi, phường Bến Thành, Quận 1, TP.HCM',
    );
  });

  test('DestinationModel ignores zero values in paid price ranges', () {
    final model = DestinationModel.fromJson({
      'id': 5,
      'title': 'Landmark 81',
      'subtitle': '',
      'description': '',
      'imageUrl': '',
      'region': '',
      'priceLevel': 'PREMIUM',
      'minPrice': 0,
      'maxPrice': 810000,
      'categoryName': 'Vui chơi',
    });

    expect(model.priceRangeText, 'Đến 810.000đ');
  });
}
