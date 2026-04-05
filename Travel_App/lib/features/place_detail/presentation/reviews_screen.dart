import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/data/api_service.dart';
import '../../../core/data/auth_service.dart';
import '../../../core/data/review_model.dart';

class ReviewsScreen extends StatefulWidget {
  final int destinationId;
  const ReviewsScreen({super.key, required this.destinationId});

  @override
  State<ReviewsScreen> createState() => ReviewsScreenState();
}

class ReviewsScreenState extends State<ReviewsScreen> {
  final _api = ApiService();
  final _authService = AuthService();
  final _commentController = TextEditingController();
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;
  int _rating = 5;
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _initUser();
    _loadReviews();
  }

  Future<void> _initUser() async {
    final user = _authService.currentUser;
    final session = await _authService.getUserSession();
    if (mounted) {
      setState(() {
        _currentUserName = user?.displayName ?? (session?['displayName'] as String?) ?? 'Ẩn danh';
      });
    }
    
    // Tự động sync user để phòng hờ trường hợp session cũ chưa được đưa xuống Database
    if (user != null) {
      try {
        await _api.syncUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
        );
      } catch (_) {}
    } else if (session != null && session['uid'] != null) {
      try {
        await _api.syncUser(
          uid: session['uid']!,
          email: session['email'] ?? '',
          displayName: session['displayName'] ?? '',
          photoUrl: session['photoUrl'],
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải đánh giá.';
        _isLoading = false;
      });
    }
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
                  backgroundColor: AppColors.primaryLight.withValues(
                    alpha: 0.3,
                  ),
                  child: _getAvatarImage(review.avatarUrl) == null
                      ? Text(
                          review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(review.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
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
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
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
          const Icon(
            Icons.wifi_off_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadReviews,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 54,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chưa có đánh giá',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy là người đầu tiên đánh giá!',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openWriteReviewSheet,
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Viết đánh giá'),
          ),
        ],
      ),
    );
  }

  void _openWriteReviewSheet({ReviewModel? review}) {
    _rating = review?.rating ?? 5;
    _commentController.text = review?.comment ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    'Viết đánh giá',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        onPressed: () =>
                            setModalState(() => _rating = index + 1),
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final ok = await _submitReview(reviewId: review?.id);
                              if (!ctx.mounted) return;
                              if (ok) Navigator.pop(ctx);
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
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
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá.')),
      );
      return false;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = _authService.currentUser;
      final session = await _authService.getUserSession();
      final userId = user?.uid ?? (session?['uid'] as String?);
      
      if (userId == null) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá.')),
        );
        return false;
      }

      // Đảm bảo user tồn tại trong DB trước khi gửi review
      final email = user?.email ?? (session?['email'] as String?) ?? '';
      final displayName = user?.displayName ?? (session?['displayName'] as String?) ?? '';
      final photoUrl = user?.photoURL ?? (session?['photoUrl'] as String?);
      await _api.syncUser(
        uid: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );

      if (reviewId != null) {
        await _api.updateReview(widget.destinationId, reviewId, {
          'userId': userId,
          'rating': _rating,
          'comment': comment,
        });
        _loadReviews();
      } else {
        final created = await _api.addReview(widget.destinationId, {
          'userId': userId,
          'rating': _rating,
          'comment': comment,
        });
        setState(() {
          _reviews = [created, ..._reviews];
        });
      }
      
      _commentController.clear();
      if (!mounted) return false;
      return true;
    } catch (e) {
      debugPrint('=== REVIEW SUBMIT ERROR: $e ===');
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  ImageProvider? _getAvatarImage(String? url) {
    if (url == null || url.isEmpty) return null;
    String resolvedUrl = url;
    if (resolvedUrl.startsWith('/uploads')) {
      resolvedUrl = 'http://10.0.2.2:8080$resolvedUrl';
    }
    if (!resolvedUrl.startsWith('http')) return null;
    return NetworkImage(resolvedUrl);
  }

  double _averageRating() {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (total, item) => total + item.rating);
    return sum / _reviews.length;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
