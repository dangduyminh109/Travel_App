import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/favorite_local_service.dart';
import '../../core/data/travel_repository.dart';
import '../place_detail/place_detail_screen.dart';
import 'presentation/widgets/filter_bottom_sheet.dart';

class SearchExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialCity;
  final String? initialDistrict;
  final String? initialPlaceType;
  final String? initialKeyword;
  final String? initialTitle;
  final bool showBackButton;

  const SearchExploreScreen({
    super.key,
    this.initialCategory,
    this.initialCity,
    this.initialDistrict,
    this.initialPlaceType,
    this.initialKeyword,
    this.initialTitle,
    this.showBackButton = false,
  });

  @override
  State<SearchExploreScreen> createState() => SearchExploreScreenState();
}

class SearchExploreScreenState extends State<SearchExploreScreen> {
  final _api = ApiService();
  final _repository = TravelRepository();
  final _favLocal = FavoriteLocalService();
  final _userId = AppConfig.demoUserId;
  final searchController = TextEditingController();

  List<DestinationModel> _places = [];
  Set<int> _localFavoriteIds = {};
  bool _isLoading = true;
  bool _isOffline = false;
  String? _offlineMessage;
  String? _error;
  Timer? _searchDebounce;

  String? _activeCategory;
  String? _activeCity;
  String? _activeDistrict;
  String? _activePlaceType;
  String? _activePriceLevel;
  double? _activeMinRating;
  int? _activeNearId;
  double? _activeRadiusKm;
  String _sortBy = 'relevance';

  static const _quickFilters = [
    _SearchQuickFilter(label: 'Tất cả'),
    _SearchQuickFilter(label: 'TP.HCM', city: 'TP.HCM'),
    _SearchQuickFilter(label: 'Vũng Tàu', city: 'Vũng Tàu'),
    _SearchQuickFilter(label: 'Ăn uống', placeType: 'FOOD'),
    _SearchQuickFilter(label: 'Vui chơi', placeType: 'ENTERTAINMENT'),
    _SearchQuickFilter(label: 'Nghỉ ngơi', placeType: 'HOTEL'),
    _SearchQuickFilter(label: 'Cafe/check-in', placeType: 'CAFE'),
    _SearchQuickFilter(label: 'Văn hóa/lịch sử', placeType: 'CULTURE_HISTORY'),
    _SearchQuickFilter(label: 'Mua sắm', placeType: 'SHOPPING'),
  ];

  static const _suggestions = [
    _SearchSuggestion(
      title: 'Khách sạn gần trung tâm',
      subtitle: 'Quận 1, ưu tiên đánh giá cao',
      icon: Icons.hotel,
      city: 'TP.HCM',
      district: 'Quận 1',
      placeType: 'HOTEL',
      sortBy: 'rating',
    ),
    _SearchSuggestion(
      title: 'Ăn uống gần chỗ vui chơi',
      subtitle: 'Quán ăn quanh phố đi bộ',
      icon: Icons.restaurant,
      placeType: 'FOOD',
      nearAnchorTitle: 'Phố đi bộ Nguyễn Huệ',
      radiusKm: 4,
      sortBy: 'distance',
    ),
    _SearchSuggestion(
      title: 'Địa điểm buổi tối',
      subtitle: 'Đi dạo, chợ đêm, phố vui chơi',
      icon: Icons.nights_stay,
      keyword: 'buổi tối',
      sortBy: 'rating',
    ),
    _SearchSuggestion(
      title: 'Quán ăn đặc sản',
      subtitle: 'Món địa phương dễ thử',
      icon: Icons.local_dining,
      keyword: 'đặc sản',
      placeType: 'FOOD',
      sortBy: 'rating',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activeCity = widget.initialCity;
    _activeDistrict = widget.initialDistrict;
    _activePlaceType = widget.initialPlaceType?.toUpperCase();
    _applyInitialCategory(widget.initialCategory);
    if (widget.initialKeyword != null && widget.initialKeyword!.isNotEmpty) {
      searchController.text = widget.initialKeyword!;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _syncFavorites();
      final ids = await _favLocal.getAllFavoriteIds();
      if (!mounted) return;
      setState(() {
        _localFavoriteIds = ids.toSet();
      });
      await _runSearch(showLoading: false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu. Kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  Future<void> _runSearch({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
        _isOffline = false;
        _offlineMessage = null;
      });
    }

    try {
      final result = await _repository.searchDestinations(
        q: searchController.text.trim(),
        city: _activeCity,
        district: _activeDistrict,
        placeType: _activePlaceType,
        priceLevel: _activePriceLevel,
        category: _activeCategory,
        minRating: _activeMinRating,
        nearId: _activeNearId,
        radiusKm: _activeRadiusKm,
        sortBy: _sortBy,
      );
      final places = result.data;
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
        _error = null;
        _isOffline = result.isFromCache;
        _offlineMessage = result.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tìm kiếm. Kiểm tra bộ lọc hoặc kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch();
    });
  }

  void _applyInitialCategory(String? categoryName) {
    final filter = _quickFilterForLegacyCategory(categoryName);
    if (filter != null) {
      _activeCategory = null;
      _activeCity ??= filter.city;
      _activePlaceType ??= filter.placeType;
      return;
    }

    final category = categoryName?.trim();
    if (category?.toLowerCase() == 'thành phố') {
      return;
    }
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'tất cả') {
      _activeCategory = category;
    }
  }

  Future<void> _syncFavorites() async {
    final addIds = await _favLocal.getUnsyncedAddIds();
    for (final id in addIds) {
      try {
        await _api.addFavorite(_userId, id);
        await _favLocal.markSyncedAdd(id);
      } catch (_) {}
    }
    final removeIds = await _favLocal.getUnsyncedRemoveIds();
    for (final id in removeIds) {
      try {
        await _api.removeFavorite(_userId, id);
        await _favLocal.markSyncedRemove(id);
      } catch (_) {}
    }
    try {
      final remoteIds = await _api.getFavoriteIds(_userId);
      await _favLocal.applyRemoteFavorites(remoteIds);
    } catch (_) {}
  }

  Future<void> _toggleFavorite(DestinationModel dest) async {
    final isFav = _localFavoriteIds.contains(dest.id);
    if (isFav) {
      await _favLocal.removeFavorite(dest.id);
      setState(() => _localFavoriteIds.remove(dest.id));
      _syncRemove(dest.id);
    } else {
      await _favLocal.addFavorite(dest.id);
      setState(() => _localFavoriteIds.add(dest.id));
      _syncAdd(dest.id);
    }
  }

  Future<void> _syncAdd(int destinationId) async {
    try {
      await _api.addFavorite(_userId, destinationId);
      await _favLocal.markSyncedAdd(destinationId);
    } catch (_) {}
  }

  Future<void> _syncRemove(int destinationId) async {
    try {
      await _api.removeFavorite(_userId, destinationId);
      await _favLocal.markSyncedRemove(destinationId);
    } catch (_) {}
  }

  Future<void> _applySuggestion(_SearchSuggestion suggestion) async {
    int? nearId;
    if (suggestion.nearAnchorTitle != null) {
      nearId = await _resolveNearId(suggestion.nearAnchorTitle!);
    }
    if (!mounted) return;

    setState(() {
      searchController.text = suggestion.keyword ?? '';
      _activeCategory = null;
      _activeCity = suggestion.city;
      _activeDistrict = suggestion.district;
      _activePlaceType = suggestion.placeType;
      _activePriceLevel = null;
      _activeMinRating = null;
      _activeNearId = nearId;
      _activeRadiusKm = nearId == null ? null : suggestion.radiusKm;
      _sortBy = nearId == null && suggestion.sortBy == 'distance'
          ? 'relevance'
          : suggestion.sortBy;
    });
    _runSearch();
  }

  Future<int?> _resolveNearId(String title) async {
    try {
      final result = await _repository.searchDestinations(
        q: title,
        sortBy: 'newest',
      );
      final results = result.data;
      for (final place in results) {
        if (place.title == title) return place.id;
      }
      return results.isEmpty ? null : results.first.id;
    } catch (_) {
      return null;
    }
  }

  void _clearAllFilters() {
    setState(() {
      searchController.clear();
      _activeCategory = null;
      _activeCity = null;
      _activeDistrict = null;
      _activePlaceType = null;
      _activePriceLevel = null;
      _activeMinRating = null;
      _activeNearId = null;
      _activeRadiusKm = null;
      _sortBy = 'relevance';
    });
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            buildSearchBar(),
            buildSuggestionList(),
            buildCategoryChips(),
            buildActiveFilterChips(),
            if (_isOffline) buildOfflineBanner(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? buildErrorState()
                  : _places.isEmpty
                  ? buildEmptyState()
                  : buildPlaceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          if (widget.showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                color: AppColors.textPrimary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          Expanded(
            child: Text(
              widget.initialTitle ?? 'Tìm kiếm và Khám phá',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
            child: const Icon(Icons.person, color: AppColors.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.6),
                ),
              ),
              child: TextField(
                controller: searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Tìm khách sạn, quán ăn, điểm vui chơi...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => FilterBottomSheet(
                  activeCity: _activeCity,
                  activeDistrict: _activeDistrict,
                  activePlaceType: _activePlaceType,
                  activePriceLevel: _activePriceLevel,
                  activeMinRating: _activeMinRating,
                  activeSortBy: _sortBy,
                ),
              );
              if (result != null && result is Map) {
                setState(() {
                  _activeCategory = null;
                  _activeNearId = null;
                  _activeRadiusKm = null;
                  _activeCity = result['city'] as String?;
                  _activeDistrict = result['district'] as String?;
                  _activePlaceType = result['placeType'] as String?;
                  _activePriceLevel = result['priceLevel'] as String?;
                  _activeMinRating = result['minRating'] as double?;
                  _sortBy = result['sortBy'] as String? ?? 'relevance';
                  if (_sortBy == 'distance') {
                    _sortBy = 'relevance';
                  }
                });
                _runSearch();
              }
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestionList() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildSuggestionCard(_suggestions[i]),
      ),
    );
  }

  Widget _buildSuggestionCard(_SearchSuggestion suggestion) {
    return InkWell(
      onTap: () => _applySuggestion(suggestion),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(suggestion.icon, color: AppColors.secondaryDark, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    suggestion.title,
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
                    suggestion.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
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

  Widget buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _quickFilters.map((filter) {
            final isSelected = _isQuickFilterSelected(filter);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) => _applyQuickFilter(filter),
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isQuickFilterSelected(_SearchQuickFilter filter) {
    return _activeCategory == null &&
        _activeCity == filter.city &&
        _activePlaceType == filter.placeType &&
        (filter.city != null || _activeDistrict == null) &&
        (filter.city != null ||
            filter.placeType != null ||
            (_activeCity == null &&
                _activeDistrict == null &&
                _activePlaceType == null &&
                _activeNearId == null));
  }

  void _applyQuickFilter(_SearchQuickFilter filter) {
    setState(() {
      _activeCategory = null;
      _activeNearId = null;
      _activeRadiusKm = null;
      _activeCity = filter.city;
      _activeDistrict = null;
      _activePlaceType = filter.placeType;
      if (_sortBy == 'distance') {
        _sortBy = 'relevance';
      }
    });
    _runSearch();
  }

  _SearchQuickFilter? _quickFilterForLegacyCategory(String? categoryName) {
    final normalized = categoryName?.trim().toLowerCase();
    return switch (normalized) {
      'ẩm thực' || 'ăn uống' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'FOOD',
      ),
      'giải trí' || 'vui chơi' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'ENTERTAINMENT',
      ),
      'nghỉ ngơi' || 'khách sạn' || 'nghỉ dưỡng' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'HOTEL',
      ),
      'cafe' || 'cafe/check-in' || 'cà phê' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'CAFE',
      ),
      'văn hóa' || 'lịch sử' || 'văn hóa/lịch sử' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'CULTURE_HISTORY',
      ),
      'mua sắm' => _quickFilters.firstWhere(
        (filter) => filter.placeType == 'SHOPPING',
      ),
      'tp.hcm' || 'tphcm' || 'hồ chí minh' => _quickFilters.firstWhere(
        (filter) => filter.city == 'TP.HCM',
      ),
      'vũng tàu' => _quickFilters.firstWhere(
        (filter) => filter.city == 'Vũng Tàu',
      ),
      'thành phố' => null,
      _ => null,
    };
  }

  Widget buildActiveFilterChips() {
    final chips = <_ActiveChip>[
      if (_activeCity != null) _ActiveChip('TP: $_activeCity', _clearCity),
      if (_activeDistrict != null)
        _ActiveChip('Khu vực: $_activeDistrict', _clearDistrict),
      if (_activePlaceType != null)
        _ActiveChip(_placeTypeLabel(_activePlaceType!), _clearPlaceType),
      if (_activePriceLevel != null)
        _ActiveChip(_priceLevelLabel(_activePriceLevel!), _clearPriceLevel),
      if (_activeMinRating != null)
        _ActiveChip(
          'Từ ${_activeMinRating!.toStringAsFixed(1)} sao',
          _clearRating,
        ),
      if (_activeNearId != null)
        _ActiveChip('Gần địa điểm đã chọn', _clearNearby),
      if (_sortBy != 'relevance') _ActiveChip(_sortLabel(_sortBy), _clearSort),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ...chips.map((chip) {
            return InputChip(
              label: Text(chip.label),
              onDeleted: chip.onDeleted,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.12),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              deleteIconColor: AppColors.primaryDark,
              side: BorderSide.none,
            );
          }),
          TextButton(
            onPressed: _clearAllFilters,
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              _offlineMessage ??
                  '\u0110ang t\u00ecm trong d\u1eef li\u1ec7u \u0111\u00e3 l\u01b0u.',
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

  void _clearCity() {
    setState(() => _activeCity = null);
    _runSearch();
  }

  void _clearDistrict() {
    setState(() => _activeDistrict = null);
    _runSearch();
  }

  void _clearPlaceType() {
    setState(() => _activePlaceType = null);
    _runSearch();
  }

  void _clearPriceLevel() {
    setState(() => _activePriceLevel = null);
    _runSearch();
  }

  void _clearRating() {
    setState(() => _activeMinRating = null);
    _runSearch();
  }

  void _clearNearby() {
    setState(() {
      _activeNearId = null;
      _activeRadiusKm = null;
      if (_sortBy == 'distance') _sortBy = 'relevance';
    });
    _runSearch();
  }

  void _clearSort() {
    setState(() => _sortBy = _activeNearId == null ? 'relevance' : 'distance');
    _runSearch();
  }

  Widget buildPlaceList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: _places.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (_, i) => buildPlaceCard(_places[i]),
    );
  }

  Widget buildPlaceCard(DestinationModel dest) {
    final isFav = _localFavoriteIds.contains(dest.id);
    final infoTags = [
      dest.shortLocationText,
      dest.placeTypeLabel.isNotEmpty ? dest.placeTypeLabel : dest.categoryName,
      if (dest.priceRangeText.isNotEmpty) dest.priceRangeText,
      if (dest.distanceText.isNotEmpty) 'Cách ${dest.distanceText}',
    ].where((tag) => tag.isNotEmpty).toList();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(destination: dest),
          ),
        );
        final ids = await _favLocal.getAllFavoriteIds();
        if (!mounted) return;
        setState(() => _localFavoriteIds = ids.toSet());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Image.network(
                    dest.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(dest),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dest.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        dest.hasReviews
                            ? Icons.star
                            : Icons.rate_review_outlined,
                        size: 16,
                        color: dest.hasReviews
                            ? Colors.amber
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dest.hasReviews ? dest.ratingText : 'Chưa có',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: infoTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Chưa tìm thấy địa điểm phù hợp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _placeTypeLabel(String value) {
    return switch (value) {
      'FOOD' => 'Ăn uống',
      'ENTERTAINMENT' => 'Vui chơi',
      'HOTEL' => 'Nghỉ ngơi',
      'CAFE' => 'Cafe/check-in',
      'CULTURE_HISTORY' => 'Văn hóa/lịch sử',
      'SHOPPING' => 'Mua sắm',
      _ => value,
    };
  }

  String _priceLevelLabel(String value) {
    return switch (value) {
      'FREE' => 'Miễn phí',
      'BUDGET' => 'Bình dân',
      'MODERATE' => 'Tầm trung',
      'PREMIUM' => 'Cao cấp',
      'LUXURY' => 'Sang trọng',
      _ => value,
    };
  }

  String _sortLabel(String value) {
    return switch (value) {
      'rating' => 'Đánh giá cao',
      'newest' => 'Mới nhất',
      'price_asc' => 'Giá thấp',
      'price_desc' => 'Giá cao',
      'distance' => 'Gần nhất',
      _ => 'Phù hợp nhất',
    };
  }
}

class _SearchSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? keyword;
  final String? city;
  final String? district;
  final String? placeType;
  final String? nearAnchorTitle;
  final double? radiusKm;
  final String sortBy;

  const _SearchSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.keyword,
    this.city,
    this.district,
    this.placeType,
    this.nearAnchorTitle,
    this.radiusKm,
    required this.sortBy,
  });
}

class _SearchQuickFilter {
  final String label;
  final String? city;
  final String? placeType;

  const _SearchQuickFilter({required this.label, this.city, this.placeType});
}

class _ActiveChip {
  final String label;
  final VoidCallback onDeleted;

  const _ActiveChip(this.label, this.onDeleted);
}
