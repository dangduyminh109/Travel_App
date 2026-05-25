class ReviewModel {
  final int id;
  final int destinationId;
  final String? destinationName;
  final String? destinationImage;
  final String authorName;
  final String avatarUrl;
  final double rating;
  final String comment;
  final DateTime? createdAt;
  final int likeCount;
  final int dislikeCount;
  final bool isLiked;
  final List<ReplyModel> replies;

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
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] as String?;
    final repliesRaw = json['replies'] as List<dynamic>? ?? [];
    return ReviewModel(
      id: json['id'] as int,
      destinationId: json['destinationId'] as int? ?? 0,
      destinationName: json['destinationName'] as String?,
      destinationImage: json['destinationImage'] as String?,
      authorName: json['authorName'] as String? ?? 'Anonymous',
      avatarUrl:
          json['avatarUrl'] as String? ?? json['avatar'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      dislikeCount: (json['dislikeCount'] as num?)?.toInt() ?? 0,
      replies: repliesRaw
          .whereType<Map<String, dynamic>>()
          .map(ReplyModel.fromJson)
          .toList(),
    );
  }

  ReviewModel copyWith({
    int? likeCount,
    int? dislikeCount,
    bool? isLiked,
    List<ReplyModel>? replies,
  }) {
    return ReviewModel(
      id: id,
      destinationId: destinationId,
      destinationName: destinationName,
      destinationImage: destinationImage,
      authorName: authorName,
      avatarUrl: avatarUrl,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }
}

class ReplyModel {
  final int id;
  final String userId;
  final String authorName;
  final String content;
  final String createdAt;

  ReplyModel({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory ReplyModel.fromJson(Map<String, dynamic> json) {
    return ReplyModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  factory ReplyModel.fromFirebase(Map<dynamic, dynamic> json) {
    return ReplyModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: json['userId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final String userId;
  final int createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    required this.createdAt,
  });

  factory AppNotificationModel.fromFirebase(Map<dynamic, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'REVIEW',
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
    );
  }
}
