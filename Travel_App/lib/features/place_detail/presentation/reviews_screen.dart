import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/data/api_service.dart';
import '../../../core/data/auth_service.dart';
import '../../../core/data/review_model.dart';
import '../../../core/data/realtime_sync_service.dart';

class ReviewsScreen extends StatefulWidget {
  final int destinationId;
  const ReviewsScreen({super.key, required this.destinationId});

  @override
  State<ReviewsScreen> createState() => ReviewsScreenState();
}

class ReviewsScreenState extends State<ReviewsScreen> {
  final _api = ApiService();
  final _sync = RealtimeSyncService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  int _rating = 5;
  String _currentUserName = '';
  String? _userId;

  StreamSubscription? _reviewSub;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    _sync.initGlobalNotifications();
    _loadReviews();
    _initUser().then((_) {
      _sync.startDestinationSync(widget.destinationId);
      _setupRealtimeListeners();
    });
  }

  /// Resolve the current user's ID and display name.
  Future<void> _initUser() async {
    final user = _authService.currentUser;
    final session = await _authService.getUserSession();

    // Set userId FIRST
    _userId = user?.uid ?? (session?['uid'] as String?);

    if (mounted) {
      setState(() {
        _currentUserName = user?.displayName ?? (session?['displayName'] as String?) ?? 'Ẩn danh';
      });
    }

    // Ensure user exists in backend DB
    if (_userId != null) {
      try {
        await _api.syncUser(
          uid: _userId!,
          email: user?.email ?? (session?['email'] as String?) ?? '',
          displayName: user?.displayName ?? (session?['displayName'] as String?) ?? '',
          photoUrl: user?.photoURL ?? (session?['photoUrl'] as String?),
        );
      } catch (e) {
        debugPrint('=== SYNC USER ERROR: $e ===');
      }
    }

    debugPrint('=== USER INIT: _userId=$_userId, name=$_currentUserName ===');
  }

  void _setupRealtimeListeners() {
    _reviewSub = _sync.reviewsStream.listen((newReview) {
      if (!mounted) return;
      setState(() {
        final index = _reviews.indexWhere((r) => r.id == newReview.id);
        if (index != -1) {
          _reviews[index] = newReview;
        } else {
          _reviews.insert(0, newReview);
        }
      });
    });

    _notifSub = _sync.notificationsStream.listen((notif) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notif.title}: ${notif.message}'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _reviewSub?.cancel();
    _notifSub?.cancel();
    _sync.stopDestinationSync(widget.destinationId);
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getReviews(widget.destinationId);
      if (!mounted) return;
      setState(() {
        _reviews = data;
        _isLoading = false;
      });
      for (final review in data) {
        _sync.listenToReviewMeta(review.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải đánh giá.';
        _isLoading = false;
      });
    }
  }

  /// Ensure _userId is available, return true if OK.
  Future<bool> _ensureUserId() async {
    if (_userId != null) return true;
    // Try to resolve again
    final user = _authService.currentUser;
    final session = await _authService.getUserSession();
    _userId = user?.uid ?? (session?['uid'] as String?);
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để thực hiện.')),
        );
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWriteReviewSheet,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Viết đánh giá'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? buildErrorState()
                  : _reviews.isEmpty
                  ? buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) =>
                          buildReviewCard(_reviews[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final avg = _averageRating();
    return Container(
      height: size.height * 0.3,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF005B7F), Color(0xFF007F8C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Đánh giá & Xếp hạng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 18, left: 4),
                    child: Text(
                      '/ 5',
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCriteriaRow('Vị trí', avg / 5, avg),
                      const SizedBox(height: 10),
                      buildCriteriaRow('Dịch vụ', avg / 5, avg),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReviewCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _getAvatarImage(review.avatarUrl),
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                  child: _getAvatarImage(review.avatarUrl) == null
                      ? Text(
                          review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.authorName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(review.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (review.authorName == _currentUserName && _currentUserName != 'Ẩn danh')
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openWriteReviewSheet(review: review);
                      } else if (value == 'delete') {
                        _deleteReview(review.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Sửa bình luận')),
                      const PopupMenuItem(value: 'delete', child: Text('Xóa bình luận')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Like + Dislike + Reply buttons
            _buildReactionsRow(review),
            // Replies list
            _buildRepliesList(review),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsRow(ReviewModel review) {
    return StreamBuilder<MapEntry<int, Map<String, int>>>(
      stream: _sync.reactionsStream.where((e) => e.key == review.id),
      initialData: MapEntry(review.id, _sync.getReactionsFor(review.id)),
      builder: (context, snapshot) {
        final counts = snapshot.data?.value ?? {'likes': 0, 'dislikes': 0};
        final likes = counts['likes'] ?? 0;
        final dislikes = counts['dislikes'] ?? 0;
        return Row(
          children: [
            // Like button
            InkWell(
              onTap: () => _handleReaction(review.id, 'LIKE'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up_alt_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      likes > 0 ? '$likes' : '',
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Dislike button
            InkWell(
              onTap: () => _handleReaction(review.id, 'DISLIKE'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_down_alt_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      dislikes > 0 ? '$dislikes' : '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Reply button
            InkWell(
              onTap: () => _openReplySheet(review),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.reply_outlined, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Phản hồi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleReaction(int reviewId, String type) async {
    if (!await _ensureUserId()) return;
    try {
      await _api.toggleLike(reviewId, _userId!, type: type);
    } catch (e) {
      debugPrint('=== REACTION ERROR: $e ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildRepliesList(ReviewModel review) {
    return StreamBuilder<MapEntry<int, List<ReplyModel>>>(
      stream: _sync.repliesStream.where((e) => e.key == review.id),
      initialData: MapEntry(review.id, _sync.getRepliesFor(review.id)),
      builder: (context, snapshot) {
        final replies = snapshot.data?.value ?? [];
        if (replies.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: replies.map((reply) {
            final isMyReply = _userId != null && reply.userId == _userId;
            return Container(
              margin: const EdgeInsets.only(top: 8, left: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(reply.content, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (isMyReply)
                    InkWell(
                      onTap: () => _handleDeleteReply(review.id, reply.id),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: Colors.red),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  Future<void> _handleDeleteReply(int reviewId, int replyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phản hồi'),
        content: const Text('Bạn có chắc chắn muốn xóa phản hồi này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || _userId == null) return;
    try {
      await _api.deleteReply(reviewId, replyId, _userId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa phản hồi')));
      }
    } catch (e) {
      debugPrint('=== DELETE REPLY ERROR: $e ===');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openReplySheet(ReviewModel review) async {
    if (!await _ensureUserId()) return;

    final replyController = TextEditingController();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: 'Nhập phản hồi...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = replyController.text.trim();
                  if (text.isEmpty) return;
                  try {
                    debugPrint('=== REPLY: reviewId=${review.id}, userId=$_userId ===');
                    await _api.addReply(review.id, _userId!, text);
                    debugPrint('=== REPLY SUCCESS ===');
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    debugPrint('=== REPLY ERROR: $e ===');
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Gửi phản hồi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bình luận'),
        content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
       await _api.deleteReview(widget.destinationId, reviewId);
       _loadReviews();
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa bình luận thành công')));
       }
    } catch (e) {
       setState(() => _isLoading = false);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa bình luận')));
       }
    }
  }

  Widget buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 54, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _loadReviews, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 54, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text('Chưa có đánh giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          const Text('Hãy là người đầu tiên đánh giá!', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _openWriteReviewSheet, icon: const Icon(Icons.rate_review_outlined), label: const Text('Viết đánh giá')),
        ],
      ),
    );
  }

  void _openWriteReviewSheet({ReviewModel? review}) {
    _rating = (review?.rating ?? 5.0).toInt();
    _commentController.text = review?.comment ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Viết đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(5, (index) => IconButton(
                      onPressed: () => setModalState(() => _rating = index + 1),
                      icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                    )),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Chia sẻ trải nghiệm của bạn...', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        final ok = await _submitReview(reviewId: review?.id);
                        if (!ctx.mounted) return;
                        if (ok) Navigator.pop(ctx);
                      },
                      child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Gửi đánh giá'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _submitReview({int? reviewId}) async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá.')));
      return false;
    }
    setState(() => _isSubmitting = true);
    try {
      if (!await _ensureUserId()) return false;

      if (reviewId != null) {
        await _api.updateReview(widget.destinationId, reviewId, {
          'userId': _userId!, 'rating': _rating, 'comment': comment,
        });
        _loadReviews();
      } else {
        final created = await _api.addReview(widget.destinationId, {
          'userId': _userId!, 'rating': _rating, 'comment': comment,
        });
        setState(() => _reviews = [created, ..._reviews]);
        _sync.listenToReviewMeta(created.id);
      }
      _commentController.clear();
      return true;
    } catch (e) {
      debugPrint('=== REVIEW SUBMIT ERROR: $e ===');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), duration: const Duration(seconds: 5)));
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  ImageProvider? _getAvatarImage(String? url) {
    if (url == null || url.isEmpty) return null;
    String resolvedUrl = url;
    if (resolvedUrl.startsWith('/uploads')) resolvedUrl = 'http://10.0.2.2:8080$resolvedUrl';
    if (!resolvedUrl.startsWith('http')) return null;
    return NetworkImage(resolvedUrl);
  }

  double _averageRating() {
    if (_reviews.isEmpty) return 0.0;
    return _reviews.fold<double>(0.0, (total, item) => total + item.rating) / _reviews.length;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget buildCriteriaRow(String label, double progress, double score) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Row(children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(score.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0), minHeight: 6,
              backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
