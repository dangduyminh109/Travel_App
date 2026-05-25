import 'dart:convert';

class DestinationModel {
  static const String _localBackendOrigin = 'http://10.0.2.2:8080';

  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String region;
  final String city;
  final String district;
  final String address;
  final String placeType;
  final String priceLevel;
  final int? minPrice;
  final int? maxPrice;
  final String openingHours;
  final String highlights;
  final String suitableFor;
  final int? categoryId;
  final String categoryName;
  final String tags;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  const DestinationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.region,
    required this.city,
    required this.district,
    required this.address,
    required this.placeType,
    required this.priceLevel,
    required this.minPrice,
    required this.maxPrice,
    required this.openingHours,
    required this.highlights,
    required this.suitableFor,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    required this.rating,
    required this.reviewCount,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isFavorite = false,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final categoryName =
        (json['categoryName'] ?? json['category']) as String? ?? '';
    final rawTags = json['tags'] as String?;
    return DestinationModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: _processImageUrl(json['imageUrl'] as String? ?? ''),
      region: json['region'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      address: json['address'] as String? ?? '',
      placeType: json['placeType'] as String? ?? '',
      priceLevel: json['priceLevel'] as String? ?? '',
      minPrice: _parseInt(json['minPrice']),
      maxPrice: _parseInt(json['maxPrice']),
      openingHours: json['openingHours'] as String? ?? '',
      highlights: json['highlights'] as String? ?? '',
      suitableFor: json['suitableFor'] as String? ?? '',
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: categoryName,
      tags: rawTags ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  factory DestinationModel.fromCacheMap(Map<String, Object?> map) {
    final rawJson = map['rawJson'] as String?;
    if (rawJson != null && rawJson.isNotEmpty) {
      final json = jsonDecode(rawJson) as Map<String, dynamic>;
      return DestinationModel.fromJson(json);
    }

    return DestinationModel(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      region: map['region'] as String? ?? '',
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      address: map['address'] as String? ?? '',
      placeType: map['placeType'] as String? ?? '',
      priceLevel: map['priceLevel'] as String? ?? '',
      minPrice: _parseInt(map['minPrice']),
      maxPrice: _parseInt(map['maxPrice']),
      openingHours: map['openingHours'] as String? ?? '',
      highlights: map['highlights'] as String? ?? '',
      suitableFor: map['suitableFor'] as String? ?? '',
      categoryId: (map['categoryId'] as num?)?.toInt(),
      categoryName: map['categoryName'] as String? ?? '',
      tags: map['tags'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson({bool includeDistance = true}) {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'region': region,
      'city': city,
      'district': district,
      'address': address,
      'placeType': placeType,
      'priceLevel': priceLevel,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'openingHours': openingHours,
      'highlights': highlights,
      'suitableFor': suitableFor,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'latitude': latitude,
      'longitude': longitude,
      if (includeDistance) 'distanceKm': distanceKm,
    };
  }

  Map<String, Object?> toCacheMap({int? cachedAt}) {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'region': region,
      'city': city,
      'district': district,
      'address': address,
      'placeType': placeType,
      'priceLevel': priceLevel,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'openingHours': openingHours,
      'highlights': highlights,
      'suitableFor': suitableFor,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'latitude': latitude,
      'longitude': longitude,
      'rawJson': jsonEncode(toJson(includeDistance: false)),
      'cachedAt': cachedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  static String _processImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('/uploads/')) {
      return '$_localBackendOrigin$trimmed';
    }
    if (trimmed.startsWith('uploads/')) {
      return '$_localBackendOrigin/$trimmed';
    }
    if (trimmed.startsWith('http://localhost:8080')) {
      return trimmed.replaceFirst('http://localhost:8080', _localBackendOrigin);
    }
    if (trimmed.startsWith('http://127.0.0.1:8080')) {
      return trimmed.replaceFirst('http://127.0.0.1:8080', _localBackendOrigin);
    }
    if (trimmed.startsWith(_localBackendOrigin)) {
      return trimmed;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final encodedUrl = Uri.encodeComponent(trimmed);
      return '$_localBackendOrigin/api/images/proxy?url=$encodedUrl';
    }
    return trimmed;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> get tagsList {
    final list = _splitCsv(tags);
    if (list.isEmpty && categoryName.isNotEmpty) {
      return [categoryName];
    }
    return list;
  }

  List<String> get highlightsList => _splitCsv(highlights);

  List<String> get suitableForList => _splitCsv(suitableFor);

  bool get hasReviews => reviewCount > 0 && rating > 0;

  String get ratingText => hasReviews ? rating.toStringAsFixed(1) : '';

  String get reviewSummaryText =>
      hasReviews ? '($reviewCount đánh giá)' : 'Chưa có đánh giá';

  String get distanceText {
    final distance = distanceKm;
    if (distance == null) return '';
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  String get placeTypeLabel {
    return switch (placeType.toUpperCase()) {
      'FOOD' => 'Ăn uống',
      'ENTERTAINMENT' => 'Vui chơi',
      'HOTEL' => 'Nghỉ ngơi',
      'CAFE' => 'Cafe/check-in',
      'CULTURE_HISTORY' => 'Văn hóa/lịch sử',
      'SHOPPING' => 'Mua sắm',
      _ => '',
    };
  }

  String get priceLevelLabel {
    return switch (priceLevel.toUpperCase()) {
      'FREE' => 'Miễn phí',
      'BUDGET' => 'Bình dân',
      'MODERATE' => 'Tầm trung',
      'PREMIUM' => 'Cao cấp',
      'LUXURY' => 'Sang trọng',
      _ => '',
    };
  }

  String get priceRangeText {
    if (priceLevel.toUpperCase() == 'FREE') return 'Miễn phí';
    final min = _positivePrice(minPrice);
    final max = _positivePrice(maxPrice);
    if (min == null && max == null) return priceLevelLabel;
    if (min != null && max != null) {
      if (min == max) return _formatVnd(min);
      return '${_formatVnd(min)} - ${_formatVnd(max)}';
    }
    if (min != null) return 'Từ ${_formatVnd(min)}';
    return 'Đến ${_formatVnd(max!)}';
  }

  String get shortLocationText {
    final parts = [
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return region;
  }

  String get fullAddressText {
    final parts = <String>[];
    _appendIfMissing(parts, address);
    _appendIfMissing(parts, district);
    _appendIfMissing(parts, city);
    return parts.join(', ');
  }

  static int? _positivePrice(int? value) {
    if (value == null || value <= 0) return null;
    return value;
  }

  static void _appendIfMissing(List<String> parts, String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) return;
    final lowerValue = normalizedValue.toLowerCase();
    final alreadyCovered = parts.any((part) {
      final lowerPart = part.toLowerCase();
      return lowerPart == lowerValue || lowerPart.contains(lowerValue);
    });
    if (!alreadyCovered) {
      parts.add(normalizedValue);
    }
  }

  static String _formatVnd(int value) {
    final text = value.toString();
    final groups = <String>[];
    for (var end = text.length; end > 0; end -= 3) {
      final start = end - 3 < 0 ? 0 : end - 3;
      groups.insert(0, text.substring(start, end));
    }
    return '${groups.join('.')}đ';
  }

  DestinationModel copyWith({bool? isFavorite, double? distanceKm}) {
    return DestinationModel(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      imageUrl: imageUrl,
      region: region,
      city: city,
      district: district,
      address: address,
      placeType: placeType,
      priceLevel: priceLevel,
      minPrice: minPrice,
      maxPrice: maxPrice,
      openingHours: openingHours,
      highlights: highlights,
      suitableFor: suitableFor,
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags,
      rating: rating,
      reviewCount: reviewCount,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
