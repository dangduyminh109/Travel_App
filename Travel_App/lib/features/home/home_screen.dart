import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import '../../core/data/category_model.dart';
import '../../core/data/destination_model.dart';
import '../place_detail/place_detail_screen.dart';
import '../search/search_explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();

  List<DestinationModel> _trending = [];
  DestinationModel? _featured;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getTrending(),
        _api.getFeatured(),
        _api.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _trending = results[0] as List<DestinationModel>;
        _featured = results[1] as DestinationModel;
        _categories = results[2] as List<CategoryModel>;
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          if (_featured != null)
                            buildFeaturedCard(context, _featured!),
                          const SizedBox(height: 24),
                          buildSectionTitle('Xu hướng'),
                          const SizedBox(height: 12),
                          buildTrendingList(context),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Khám phá Việt Nam...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
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
              const SizedBox(height: 20),
              SizedBox(
                height: 90,
                child: _categories.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 20),
                        itemBuilder: (_, i) =>
                            buildCategoryChip(_categories[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryChip(CategoryModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchExploreScreen(
              initialCategory: item.name,
              showBackButton: true,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForCategory(item.icon),
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String iconName) {
    switch (iconName) {
      case 'beach_access':
        return Icons.beach_access;
      case 'terrain':
        return Icons.terrain;
      case 'restaurant':
        return Icons.restaurant;
      case 'location_city':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }

  Widget buildFeaturedCard(BuildContext context, DestinationModel dest) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(destination: dest),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              SizedBox(
                height: 200,
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
                        Colors.black.withValues(alpha: 0.55),
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
                    Text(
                      'Nổi bật: ${dest.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dest.region,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
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

  Widget buildTrendingList(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _trending.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (_, i) => buildTrendingCard(context, _trending[i]),
      ),
    );
  }

  Widget buildTrendingCard(BuildContext context, DestinationModel dest) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(destination: dest),
          ),
        );
      },
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 140,
                width: 150,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              dest.subtitle,
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
}
