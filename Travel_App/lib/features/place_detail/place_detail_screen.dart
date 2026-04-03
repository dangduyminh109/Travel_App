import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/auth_service.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/favorite_local_service.dart';
import 'presentation/reviews_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final DestinationModel destination;
  const PlaceDetailScreen({super.key, required this.destination});

  @override
  State<PlaceDetailScreen> createState() => PlaceDetailScreenState();
}

class PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _favLocal = FavoriteLocalService();
  final _api = ApiService();
  final _authService = AuthService();
  String? _userId;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _initUserAndFavorite();
  }

  Future<void> _initUserAndFavorite() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
    } else {
      final session = await _authService.getUserSession();
      _userId = session?['uid'] as String?;
    }
    await _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final result = await _favLocal.isFavorite(widget.destination.id);
    if (!mounted) return;
    setState(() => isFavorited = result);
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null || _userId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để lưu yêu thích.')),
      );
      return;
    }
    if (isFavorited) {
      await _favLocal.removeFavorite(widget.destination.id);
      _syncRemove(widget.destination.id);
    } else {
      await _favLocal.addFavorite(widget.destination.id);
      _syncAdd(widget.destination.id);
    }
    if (!mounted) return;
    setState(() => isFavorited = !isFavorited);
  }

  Future<void> _syncAdd(int destinationId) async {
    if (_userId == null || _userId!.isEmpty) {
      return;
    }
    try {
      await _api.addFavorite(_userId!, destinationId);
      await _favLocal.markSyncedAdd(destinationId);
    } catch (_) {}
  }

  Future<void> _syncRemove(int destinationId) async {
    if (_userId == null || _userId!.isEmpty) {
      return;
    }
    try {
      await _api.removeFavorite(_userId!, destinationId);
      await _favLocal.markSyncedRemove(destinationId);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          buildHeroImage(size),
          buildTopButtons(context),
          buildContentSheet(size),
        ],
      ),
      bottomNavigationBar: buildBottomButton(),
    );
  }

  Widget buildHeroImage(Size size) {
    return SizedBox(
      height: size.height * 0.42,
      width: double.infinity,
      child: Image.network(
        widget.destination.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.primaryLight],
            ),
          ),
          child: const Center(
            child: Icon(Icons.landscape, size: 80, color: Colors.white38),
          ),
        ),
      ),
    );
  }

  Widget buildTopButtons(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            circleButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            circleButton(
              icon: isFavorited ? Icons.favorite : Icons.favorite_border,
              iconColor: Colors.redAccent,
              onTap: _toggleFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget circleButton({
    required IconData icon,
    Color iconColor = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  Widget buildContentSheet(Size size) {
    final tags = widget.destination.tagsList;

    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.58,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.destination.title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.destination.region,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatPrice(widget.destination.price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    '/người',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags.map(buildTag).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                widget.destination.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReviewsScreen(destinationId: widget.destination.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        widget.destination.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${widget.destination.reviewCount} đánh giá)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined, size: 20),
          label: const Text('Mở bản đồ', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final formatted = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formattedđ';
  }
}
