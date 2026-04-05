class DestinationModel {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String imageUrl;
  final String region;
  final int? categoryId;
  final String categoryName;
  final String tags;
  final double rating;
  final int reviewCount;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;

  const DestinationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.region,
    required this.categoryId,
    required this.categoryName,
    required this.tags,
    required this.rating,
    required this.reviewCount,
    this.latitude,
    this.longitude,
    this.isFavorite = false,
  });

  factory DestinationModel.fromJson(Map<String, dynamic> json) {
    final categoryName =
        (json['categoryName'] ?? json['category']) as String? ?? '';
    final rawTags = json['tags'] as String?;
    return DestinationModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: _processImageUrl(json['imageUrl'] as String? ?? ''),
      region: json['region'] as String? ?? '',
      categoryId: json['categoryId'] as int?,
      categoryName: categoryName,
      tags: rawTags ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  static String _processImageUrl(String url) {
    if (url.startsWith('/uploads/')) {
      return 'http://10.0.2.2:8080$url';
    }
    return url;
  }

  List<String> get tagsList {
    final list = tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (list.isEmpty && categoryName.isNotEmpty) {
      return [categoryName];
    }
    return list;
  }

  DestinationModel copyWith({bool? isFavorite}) {
    return DestinationModel(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      imageUrl: imageUrl,
      region: region,
      categoryId: categoryId,
      categoryName: categoryName,
      tags: tags,
      rating: rating,
      reviewCount: reviewCount,
      latitude: latitude,
      longitude: longitude,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
