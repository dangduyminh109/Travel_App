import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/auth_service.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import '../../core/data/favorite_local_service.dart';
import '../place_detail/place_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _favLocal = FavoriteLocalService();
  final _authService = AuthService();
  String? _userId;
  late final TabController tabController;

  List<DestinationModel> _places = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> tabs = [
    'Điểm đến',
    'Khách sạn',
    'Trải nghiệm',
    'Ẩm thực',
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    _initUserAndLoad();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndLoad() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _userId = firebaseUser.uid;
    } else {
      final session = await _authService.getUserSession();
      _userId = session?['uid'] as String?;
    }
    if (!mounted) return;
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Vui lòng đăng nhập để xem danh sách yêu thích.';
      });
      return;
    }
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_userId == null || _userId!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Vui lòng đăng nhập để xem danh sách yêu thích.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _syncFavorites();
      final ids = await _favLocal.getAllFavoriteIds();
      if (ids.isEmpty) {
        if (!mounted) return;
        setState(() {
          _places = [];
          _isLoading = false;
        });
        return;
      }
      final all = await _api.getAll();
      final favorites = all.where((d) => ids.contains(d.id)).toList();
      if (!mounted) return;
      setState(() {
        _places = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu. Kiểm tra kết nối mạng.';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFavorites() async {
    if (_userId == null || _userId!.isEmpty) {
      return;
    }
    final addIds = await _favLocal.getUnsyncedAddIds();
    for (final id in addIds) {
      try {
        await _api.addFavorite(_userId!, id);
        await _favLocal.markSyncedAdd(id);
      } catch (_) {}
    }
    final removeIds = await _favLocal.getUnsyncedRemoveIds();
    for (final id in removeIds) {
      try {
        await _api.removeFavorite(_userId!, id);
        await _favLocal.markSyncedRemove(id);
      } catch (_) {}
    }
    try {
      final remoteIds = await _api.getFavoriteIds(_userId!);
      await _favLocal.applyRemoteFavorites(remoteIds);
    } catch (_) {}
  }

  Future<void> _removeFavorite(DestinationModel dest) async {
    await _favLocal.removeFavorite(dest.id);
    _syncRemove(dest.id);
    _loadFavorites();
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                buildDestinationsTab(),
                buildEmptyTab('Khách sạn'),
                buildEmptyTab('Trải nghiệm'),
                buildEmptyTab('Ẩm thực'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget buildDestinationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
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
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_places.isEmpty) {
      return buildEmptyTab('Điểm đến');
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _places.length,
        itemBuilder: (context, index) => buildPlaceCard(_places[index]),
      ),
    );
  }

  Widget buildPlaceCard(DestinationModel place) {
    return Dismissible(
      key: Key('fav_${place.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _removeFavorite(place),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailScreen(destination: place),
            ),
          );
          _loadFavorites();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.network(
                        place.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _removeFavorite(place),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.region,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PlaceDetailScreen(destination: place),
                                ),
                              );
                              _loadFavorites();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget buildEmptyTab(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có $category yêu thích',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy khám phá và lưu những địa điểm bạn thích!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }


}
