import 'package:flutter/material.dart';
import '../../core/constants/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/favorite_local_service.dart';
import '../place_detail/place_detail_screen.dart';
import 'presentation/widgets/filter_bottom_sheet.dart';

class SearchExploreScreen extends StatefulWidget {
  final String? initialCategory;
  final bool showBackButton;

  const SearchExploreScreen({
    super.key, 
    this.initialCategory, 
    this.showBackButton = false,
  });

  @override
  State<SearchExploreScreen> createState() => SearchExploreScreenState();
}

class SearchExploreScreenState extends State<SearchExploreScreen> {
  final _api = ApiService();
  final _favLocal = FavoriteLocalService();
  final _userId = AppConfig.demoUserId;
  final searchController = TextEditingController();

  int selectedChipIndex = 0;
  List<DestinationModel> _allPlaces = [];
  List<DestinationModel> _places = [];
  Set<int> _localFavoriteIds = {};
  bool _isLoading = true;
  String? _error;
  List<String> _filters = ['Tất cả'];
  bool _isFirstLoad = true;
  List<int> _activeRatingFilters = [];
  List<String> _activeRegionFilters = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _syncFavorites();
      final ids = await _favLocal.getAllFavoriteIds();
      final categories = await _api.getCategories();
      final filters = ['Tất cả', ...categories.map((c) => c.name)];
      
      int nextIndex = selectedChipIndex >= filters.length ? 0 : selectedChipIndex;
      if (_isFirstLoad && widget.initialCategory != null) {
        final foundStr = filters.indexOf(widget.initialCategory!);
        if (foundStr != -1) {
          nextIndex = foundStr;
        }
        _isFirstLoad = false;
      }
      
      final allPlaces = await _api.getAll();
      if (!mounted) return;
      
      setState(() {
        _localFavoriteIds = ids.toSet();
        _allPlaces = allPlaces;
        _filters = filters;
        selectedChipIndex = nextIndex;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu. Kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<DestinationModel> temp = List.from(_allPlaces);
    // Filter by Category
    if (selectedChipIndex > 0 && selectedChipIndex < _filters.length) {
      final selectedCat = _filters[selectedChipIndex];
      temp = temp.where((p) => p.categoryName == selectedCat).toList();
    }
    // Filter by Ratings
    if (_activeRatingFilters.isNotEmpty) {
      temp = temp.where((p) {
        if (_activeRatingFilters.contains(5) && p.rating == 5.0) return true;
        if (_activeRatingFilters.contains(4) && p.rating >= 4.0 && p.rating < 5.0) return true;
        if (_activeRatingFilters.contains(3) && p.rating >= 3.0 && p.rating < 4.0) return true;
        if (_activeRatingFilters.contains(2) && p.rating >= 2.0 && p.rating < 3.0) return true;
        if (_activeRatingFilters.contains(1) && p.rating >= 1.0 && p.rating < 2.0) return true;
        return false;
      }).toList();
    }
    // Filter by Regions
    if (_activeRegionFilters.isNotEmpty) {
      temp = temp.where((p) => _activeRegionFilters.contains(p.region)).toList();
    }
    // Search keyword
    final kw = searchController.text.trim().toLowerCase();
    if (kw.isNotEmpty) {
      temp = temp.where((p) => 
        p.title.toLowerCase().contains(kw) || 
        p.region.toLowerCase().contains(kw)
      ).toList();
    }

    setState(() {
      _places = temp;
    });
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

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) {
      _loadAll();
      return;
    }
    setState(() {
      _isLoading = true;
      selectedChipIndex = 0; // Tự động về "Tất cả" khi tìm kiếm từ khóa
    });
    try {
      final places = await _api.search(keyword);
      if (!mounted) return;
      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi tìm kiếm.';
        _isLoading = false;
      });
    }
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
            buildFilterChips(),
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
          const Expanded(
            child: Text(
              'Tìm kiếm và Khám phá',
              style: TextStyle(
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
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm điểm đến...',
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
                  activeRatings: _activeRatingFilters,
                  activeRegions: _activeRegionFilters,
                ),
              );
              if (result != null && result is Map) {
                setState(() {
                  _activeRatingFilters = List<int>.from(result['ratings'] ?? []);
                  final regMap = Map<String, bool>.from(result['regions'] ?? {});
                  _activeRegionFilters = regMap.entries.where((e) => e.value).map((e) => e.key).toList();
                });
                _applyFilters();
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

  Widget buildFilterChips() {
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(_filters.length, (i) {
            final isSelected = i == selectedChipIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(_filters[i]),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => selectedChipIndex = i);
                  searchController.clear();
                  _applyFilters();
                },
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
          }),
        ),
      ),
    );
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
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        dest.rating.toStringAsFixed(1),
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
                    children: [dest.region, dest.categoryName].map((tag) {
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

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử tìm kiếm với từ khóa khác',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget buildErrorState() {
    return Center(
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
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
