import 'dart:convert';

class CategoryModel {
  final int id;
  final String name;
  final String icon;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
    );
  }

  factory CategoryModel.fromCacheMap(Map<String, Object?> map) {
    final rawJson = map['rawJson'] as String?;
    if (rawJson != null && rawJson.isNotEmpty) {
      final json = jsonDecode(rawJson) as Map<String, dynamic>;
      return CategoryModel.fromJson(json);
    }
    return CategoryModel(
      id: (map['id'] as num).toInt(),
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon};
  }

  Map<String, Object?> toCacheMap({int? cachedAt}) {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'rawJson': jsonEncode(toJson()),
      'cachedAt': cachedAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
}
