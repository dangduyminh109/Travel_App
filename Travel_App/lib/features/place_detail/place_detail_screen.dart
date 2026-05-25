import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/auth_service.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/favorite_local_service.dart';
import '../../core/data/travel_repository.dart';
import 'presentation/reviews_screen.dart';
import 'presentation/map_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final DestinationModel destination;
  const PlaceDetailScreen({super.key, required this.destination});

  @override
  State<PlaceDetailScreen> createState() => PlaceDetailScreenState();
}

class PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final _favLocal = FavoriteLocalService();
  final _api = ApiService();
  final _repository = TravelRepository();
  final _authService = AuthService();
  String? _userId;
  bool isFavorited = false;
  late DestinationModel _destination;
  List<DestinationModel> _nearbyPlaces = [];
  bool _isOffline = false;
  String? _offlineMessage;

  @override
  void initState() {
    super.initState();
    _destination = widget.destination;
    _refreshDestination();
    _initUserAndFavorite();
    _loadNearbyPlaces();
  }

  Future<void> _refreshDestination() async {
    try {
      final result = await _repository.getById(_destination.id);
      final updated = result.data;
      if (updated == null) return;
      if (mounted) {
        setState(() {
          _destination = updated;
          _isOffline = result.isFromCache;
          _offlineMessage = result.message;
        });
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _loadNearbyPlaces() async {
    try {
      final result = await _repository.searchDestinations(
        nearId: _destination.id,
        radiusKm: 2,
        sortBy: 'distance',
      );
      final places = result.data;
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places.take(4).toList();
        _isOffline = _isOffline || result.isFromCache;
        if (result.isFromCache) {
          _offlineMessage = result.message ?? 'Đang xem dữ liệu offline.';
        }
      });
    } catch (_) {
      // Nearby suggestions are optional. Keep detail readable if search fails.
    }
  }

  Future<void> _initUserAndFavorite() async {
    final firebaseUser = _authService.currentUser;
    final session = await _authService.getUserSession();

    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
      try {
        await _api.syncUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
        );
      } catch (_) {}
    } else if (session != null) {
      _userId = session['uid'] as String?;
      if (_userId != null) {
        try {
          await _api.syncUser(
            uid: _userId!,
            email: session['email'] ?? '',
            displayName: session['displayName'] ?? '',
            photoUrl: session['photoUrl'],
          );
        } catch (_) {}
      }
    }
    await _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final result = await _favLocal.isFavorite(_destination.id);
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
      await _favLocal.removeFavorite(_destination.id);
      _syncRemove(_destination.id);
    } else {
      await _favLocal.addFavorite(_destination.id);
      _syncAdd(_destination.id);
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
        _destination.imageUrl,
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
    final tags = _destination.tagsList;

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
              if (_isOffline) ...[
                buildOfflineBanner(),
                const SizedBox(height: 14),
              ],
              Text(
                _destination.title.toUpperCase(),
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
                    _destination.region,
                    style: const TextStyle(
                      fontSize: 14,
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
              if (hasDestinationMetadata()) ...[
                const SizedBox(height: 20),
                buildDestinationMetadata(),
              ],
              const SizedBox(height: 20),
              Text(
                _destination.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  if (_isOffline) {
                    _showNetworkRequired(
                      '\u0110\u00e1nh gi\u00e1 c\u1ea7n k\u1ebft n\u1ed1i internet.',
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReviewsScreen(destinationId: _destination.id),
                    ),
                  ).then((_) {
                    _refreshDestination();
                  });
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
                      Icon(
                        _destination.hasReviews
                            ? Icons.star
                            : Icons.rate_review_outlined,
                        color: _destination.hasReviews
                            ? Colors.amber
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _destination.hasReviews
                            ? _destination.ratingText
                            : _destination.reviewSummaryText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_destination.hasReviews) ...[
                        const SizedBox(width: 6),
                        Text(
                          _destination.reviewSummaryText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
              if (_nearbyPlaces.isNotEmpty) ...[
                const SizedBox(height: 8),
                buildNearbySection(),
              ],
            ],
          ),
        );
      },
    );
  }

  bool hasDestinationMetadata() {
    return _destination.fullAddressText.isNotEmpty ||
        _destination.placeTypeLabel.isNotEmpty ||
        _destination.priceRangeText.isNotEmpty ||
        _destination.openingHours.isNotEmpty ||
        _destination.highlightsList.isNotEmpty ||
        _destination.suitableForList.isNotEmpty;
  }

  Widget buildDestinationMetadata() {
    final rows = <Widget>[
      if (_destination.fullAddressText.isNotEmpty)
        buildInfoRow(
          Icons.location_on_outlined,
          'Địa chỉ',
          _destination.fullAddressText,
        ),
      if (_destination.placeTypeLabel.isNotEmpty)
        buildInfoRow(
          Icons.category_outlined,
          'Loại địa điểm',
          _destination.placeTypeLabel,
        ),
      if (_destination.priceRangeText.isNotEmpty)
        buildInfoRow(
          Icons.payments_outlined,
          'Giá tham khảo',
          _destination.priceRangeText,
        ),
      if (_destination.openingHours.isNotEmpty)
        buildInfoRow(
          Icons.schedule_outlined,
          'Giờ mở cửa',
          _destination.openingHours,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty) ...rows,
        if (_destination.highlightsList.isNotEmpty) ...[
          const SizedBox(height: 14),
          buildChipSection('Điểm nổi bật', _destination.highlightsList),
        ],
        if (_destination.suitableForList.isNotEmpty) ...[
          const SizedBox(height: 14),
          buildChipSection('Phù hợp với', _destination.suitableForList),
        ],
      ],
    );
  }

  Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AppColors.secondaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _offlineMessage ?? '\u0110ang xem d\u1eef li\u1ec7u offline.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChipSection(String title, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map(buildTag).toList(),
        ),
      ],
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

  Widget buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gần địa điểm này',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _nearbyPlaces.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                buildNearbyCard(_nearbyPlaces[index]),
          ),
        ),
      ],
    );
  }

  Widget buildNearbyCard(DestinationModel place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(destination: place),
          ),
        );
      },
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 78,
              width: double.infinity,
              child: Image.network(
                place.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    place.distanceText.isNotEmpty
                        ? 'Cách ${place.distanceText}'
                        : place.shortLocationText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
          onPressed: () {
            if (_isOffline) {
              _showNetworkRequired(
                'B\u1ea3n \u0111\u1ed3 c\u1ea7n k\u1ebft n\u1ed1i internet.',
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(destination: _destination),
              ),
            );
          },
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

  void _showNetworkRequired(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
