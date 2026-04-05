class ReviewModel {
  final int id;
  final int destinationId;
  final String? destinationName;
  final String? destinationImage;
  final String authorName;
  final String avatarUrl;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.destinationId,
    this.destinationName,
    this.destinationImage,
    required this.authorName,
    required this.avatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    return ReviewModel(
      id: json['id'] as int,
      destinationId: json['destinationId'] as int,
      destinationName: json['destinationName'] as String?,
      destinationImage: json['destinationImage'] as String?,
      authorName: json['authorName'] as String? ?? 'Anonymous',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}
