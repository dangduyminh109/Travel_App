import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/travel_repository.dart';
import '../place_detail/place_detail_screen.dart';
import '../search/search_explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _repository = TravelRepository();

  List<DestinationModel> _trending = [];
  List<DestinationModel> _allPlaces = [];
  DestinationModel? _featured;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _offlineMessage;
  String? _error;

  static const _featuredPriority = [
    'Chợ Bến Thành',
    'Phố đi bộ Nguyễn Huệ',
    'Bãi Sau Vũng Tàu',
    'Hồ Mây Park',
  ];

  static const _areaActions = [
    _HomeAction(
      title: 'TP.HCM',
      subtitle: 'Trung tâm, ẩm thực, lịch sử',
      icon: Icons.location_city,
      city: 'TP.HCM',
    ),
    _HomeAction(
      title: 'Vũng Tàu',
      subtitle: 'Biển, hải sản, nghỉ dưỡng',
      icon: Icons.beach_access,
      city: 'Vũng Tàu',
    ),
    _HomeAction(
      title: 'Quận 1',
      subtitle: 'Gần phố đi bộ và di tích',
      icon: Icons.apartment,
      district: 'Quận 1',
    ),
    _HomeAction(
      title: 'Quận 3',
      subtitle: 'Bảo tàng, cafe, món Việt',
      icon: Icons.museum,
      district: 'Quận 3',
    ),
    _HomeAction(
      title: 'Bình Thạnh',
      subtitle: 'Landmark, công viên ven sông',
      icon: Icons.park,
      district: 'Bình Thạnh',
    ),
    _HomeAction(
      title: 'Thủ Đức',
      subtitle: 'Cafe, chùa, khu vui chơi',
      icon: Icons.temple_buddhist,
      district: 'Thủ Đức',
    ),
    _HomeAction(
      title: 'Bãi Sau',
      subtitle: 'Tắm biển, khách sạn, ăn đêm',
      icon: Icons.waves,
      district: 'Bãi Sau',
    ),
    _HomeAction(
      title: 'Bãi Trước',
      subtitle: 'Dạo biển và ngắm hoàng hôn',
      icon: Icons.wb_twilight,
      district: 'Bãi Trước',
    ),
  ];

  static const _headerActions = [
    _HomeAction(
      title: 'TP.HCM',
      subtitle: 'Lọc theo thành phố',
      icon: Icons.location_city,
      city: 'TP.HCM',
    ),
    _HomeAction(
      title: 'Vũng Tàu',
      subtitle: 'Lọc theo thành phố',
      icon: Icons.beach_access,
      city: 'Vũng Tàu',
    ),
    _HomeAction(
      title: 'Ăn uống',
      subtitle: 'Ẩm thực, đặc sản',
      icon: Icons.restaurant,
      placeType: 'FOOD',
    ),
    _HomeAction(
      title: 'Vui chơi',
      subtitle: 'Giải trí, đi buổi tối',
      icon: Icons.attractions,
      placeType: 'ENTERTAINMENT',
    ),
    _HomeAction(
      title: 'Nghỉ ngơi',
      subtitle: 'Khách sạn, resort',
      icon: Icons.hotel,
      placeType: 'HOTEL',
    ),
    _HomeAction(
      title: 'Cafe',
      subtitle: 'Check-in, cà phê',
      icon: Icons.local_cafe,
      placeType: 'CAFE',
    ),
    _HomeAction(
      title: 'Văn hóa',
      subtitle: 'Văn hóa/lịch sử',
      icon: Icons.account_balance,
      placeType: 'CULTURE_HISTORY',
    ),
    _HomeAction(
      title: 'Mua sắm',
      subtitle: 'Chợ, trung tâm thương mại',
      icon: Icons.shopping_bag,
      placeType: 'SHOPPING',
    ),
  ];

  static const _needActions = [
    _HomeAction(
      title: 'Ăn đặc sản',
      subtitle: 'Quán ăn, hải sản, món địa phương',
      icon: Icons.restaurant,
      placeType: 'FOOD',
    ),
    _HomeAction(
      title: 'Cafe/check-in',
      subtitle: 'Góc ảnh đẹp, quán cà phê',
      icon: Icons.local_cafe,
      placeType: 'CAFE',
    ),
    _HomeAction(
      title: 'Đi buổi tối',
      subtitle: 'Phố đi bộ, chợ đêm, nightlife',
      icon: Icons.nights_stay,
      keyword: 'buổi tối',
    ),
    _HomeAction(
      title: 'Nghỉ ngơi',
      subtitle: 'Khách sạn gần trung tâm/biển',
      icon: Icons.hotel,
      placeType: 'HOTEL',
    ),
    _HomeAction(
      title: 'Văn hóa/lịch sử',
      subtitle: 'Bảo tàng, di tích, kiến trúc',
      icon: Icons.account_balance,
      placeType: 'CULTURE_HISTORY',
    ),
    _HomeAction(
      title: 'Mua sắm',
      subtitle: 'Chợ, trung tâm thương mại',
      icon: Icons.shopping_bag,
      placeType: 'SHOPPING',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isOffline = false;
      _offlineMessage = null;
    });
    try {
      final allResult = await _repository.getAll();
      if (!mounted) return;

      final allPlaces = allResult.data;
      final isOffline = allResult.isFromCache;

      if (isOffline) {
        _applyHomeData(
          allPlaces: allPlaces,
          trending: _fallbackTrending(allPlaces),
          featuredFallback: allPlaces.isEmpty ? null : allPlaces.first,
          isOffline: true,
          message: allResult.message,
        );
        return;
      }

      final trendingResult = await _repository.getTrending();
      final featuredResult = await _repository.getFeatured();
      if (!mounted) return;

      final trending = trendingResult.data;
      final featuredFallback = featuredResult.data;

      if (allPlaces.isEmpty && trending.isEmpty && featuredFallback == null) {
        setState(() {
          _error =
              allResult.message ??
              'Chưa có dữ liệu offline. Hãy mở app 1 lần khi có mạng.';
          _isLoading = false;
          _isOffline = isOffline;
          _offlineMessage = allResult.message;
        });
        return;
      }

      _applyHomeData(
        allPlaces: allPlaces,
        trending: trending,
        featuredFallback: featuredFallback,
        isOffline:
            trendingResult.isFromCache ||
            featuredResult.isFromCache ||
            allResult.isFromCache,
        message:
            allResult.message ?? trendingResult.message ?? featuredResult.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu. Kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  void _applyHomeData({
    required List<DestinationModel> allPlaces,
    required List<DestinationModel> trending,
    required DestinationModel? featuredFallback,
    required bool isOffline,
    required String? message,
  }) {
    if (!mounted) return;
    if (allPlaces.isEmpty && trending.isEmpty && featuredFallback == null) {
      setState(() {
        _error =
            message ??
            'Chua co du lieu offline. Hay mo app khi co mang mot lan.';
        _isLoading = false;
        _isOffline = isOffline;
        _offlineMessage = message;
      });
      return;
    }

    setState(() {
      _trending = trending;
      _featured = featuredFallback == null
          ? (allPlaces.isEmpty ? null : allPlaces.first)
          : _selectFeatured(allPlaces, featuredFallback);
      _allPlaces = allPlaces;
      _isOffline = isOffline;
      _offlineMessage = message;
      _isLoading = false;
    });
  }

  List<DestinationModel> _fallbackTrending(List<DestinationModel> places) {
    final sorted = [...places]..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(6).toList();
  }

  DestinationModel _selectFeatured(
    List<DestinationModel> places,
    DestinationModel fallback,
  ) {
    for (final title in _featuredPriority) {
      for (final place in places) {
        if (place.title == title) return place;
      }
    }
    return fallback;
  }

  List<DestinationModel> get _recommendedPlaces {
    final usedIds = <int>{if (_featured != null) _featured!.id};
    final curatedTitles = [
      'Cafe Apartment Nguyễn Huệ',
      'Landmark 81',
      'Bảo tàng Chứng tích Chiến tranh',
      'Hải đăng Vũng Tàu',
      'Chợ đêm Hải sản Vũng Tàu',
      'Gành Hào Vũng Tàu',
      'Thảo Điền',
      'The Imperial Hotel Vũng Tàu',
    ];
    final result = <DestinationModel>[];

    for (final title in curatedTitles) {
      final place = _findByTitle(title);
      if (place != null && usedIds.add(place.id)) {
        result.add(place);
      }
    }

    for (final place in _allPlaces) {
      if (result.length >= 6) break;
      final isFocusedCity = place.city == 'TP.HCM' || place.city == 'Vũng Tàu';
      if (isFocusedCity && usedIds.add(place.id)) {
        result.add(place);
      }
    }

    return result.take(6).toList();
  }

  DestinationModel? _findByTitle(String title) {
    for (final place in _allPlaces) {
      if (place.title == title) return place;
    }
    return null;
  }

  void _openExplore(_HomeAction action) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchExploreScreen(
          showBackButton: true,
          initialCity: action.city,
          initialDistrict: action.district,
          initialPlaceType: action.placeType,
          initialKeyword: action.keyword,
          initialTitle: action.title,
        ),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SearchExploreScreen(showBackButton: true),
      ),
    );
  }

  Future<void> _openDetail(DestinationModel destination) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(destination: destination),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? buildErrorState()
          : Column(
              children: [
                buildHeader(context),
                if (_isOffline) buildOfflineBanner(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          if (_featured != null)
                            buildFeaturedCard(context, _featured!),
                          const SizedBox(height: 22),
                          buildSectionTitle('Khám phá theo khu vực'),
                          const SizedBox(height: 10),
                          buildAreaList(),
                          const SizedBox(height: 22),
                          buildSectionTitle('Bạn muốn làm gì?'),
                          const SizedBox(height: 10),
                          buildNeedGrid(),
                          const SizedBox(height: 22),
                          buildSectionTitle('Gợi ý nổi bật'),
                          const SizedBox(height: 12),
                          buildTrendingList(context),
                          const SizedBox(height: 22),
                          buildSectionTitle('Địa điểm nên thử'),
                          const SizedBox(height: 12),
                          buildRecommendedGrid(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
              _offlineMessage ?? 'Đang xem dữ liệu offline.',
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

  Widget buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                child: InkWell(
                  onTap: _openSearch,
                  borderRadius: BorderRadius.circular(18),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.textSecondary),
                        SizedBox(width: 12),
                        Text(
                          'Khám phá TP.HCM, Vũng Tàu...',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _headerActions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 18),
                  itemBuilder: (_, i) =>
                      _buildHeaderActionChip(_headerActions[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderActionChip(_HomeAction action) {
    return GestureDetector(
      onTap: () => _openExplore(action),
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: AppColors.primary, size: 27),
            ),
            const SizedBox(height: 6),
            Text(
              action.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeaturedCard(BuildContext context, DestinationModel dest) {
    return GestureDetector(
      onTap: () => _openDetail(dest),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              SizedBox(
                height: 210,
                width: double.infinity,
                child: Image.network(
                  dest.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(
                        Icons.landscape,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.62),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gợi ý hôm nay',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 15,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dest.shortLocationText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget buildAreaList() {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _areaActions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildAreaCard(_areaActions[i]),
      ),
    );
  }

  Widget _buildAreaCard(_HomeAction action) {
    return InkWell(
      onTap: () => _openExplore(action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(action.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
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

  Widget buildNeedGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: _needActions.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.28,
        ),
        itemBuilder: (_, i) => _buildNeedCard(_needActions[i]),
      ),
    );
  }

  Widget _buildNeedCard(_HomeAction action) {
    return InkWell(
      onTap: () => _openExplore(action),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(action.icon, color: AppColors.secondaryDark, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
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

  Widget buildTrendingList(BuildContext context) {
    final items = _trending.isNotEmpty
        ? _trending
        : _allPlaces.take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (_, i) => buildTrendingCard(context, items[i]),
      ),
    );
  }

  Widget buildTrendingCard(BuildContext context, DestinationModel dest) {
    return GestureDetector(
      onTap: () => _openDetail(dest),
      child: SizedBox(
        width: 154,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 132,
                width: 154,
                child: Image.network(
                  dest.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.image, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dest.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              dest.shortLocationText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              dest.placeTypeLabel.isNotEmpty
                  ? dest.placeTypeLabel
                  : dest.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecommendedGrid() {
    final items = _recommendedPlaces;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, i) => buildCompactPlaceCard(items[i]),
      ),
    );
  }

  Widget buildCompactPlaceCard(DestinationModel dest) {
    return GestureDetector(
      onTap: () => _openDetail(dest),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  dest.imageUrl,
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
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dest.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dest.shortLocationText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (dest.placeTypeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dest.placeTypeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? city;
  final String? district;
  final String? placeType;
  final String? keyword;

  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.city,
    this.district,
    this.placeType,
    this.keyword,
  });
}
