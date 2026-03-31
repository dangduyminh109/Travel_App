import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../place_detail/place_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  static const List<String> tabs = ['Điểm đến', 'Khách sạn', 'Trải nghiệm', 'Ẩm thực'];

  static final List<FavoritePlace> places = [
    FavoritePlace(
      name: 'Phố cổ Hội An',
      location: 'Quảng Nam, Việt Nam',
      price: '500.000đ',
      priceUnit: '/người',
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600',
      isFree: false,
    ),
    FavoritePlace(
      name: 'Vịnh Hạ Long',
      location: 'Quảng Ninh, Việt Nam',
      price: '1.200.000đ',
      priceUnit: '/tour',
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=600',
      isFree: false,
    ),
    FavoritePlace(
      name: 'Sapa',
      location: 'Lào Cai, Việt Nam',
      price: 'Miễn phí',
      priceUnit: '(Tham quan)',
      rating: 4.7,
      imageUrl: 'https://images.unsplash.com/photo-1570366583862-f91883984fde?w=600',
      isFree: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
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
                buildPlacesList(),
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
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
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

  Widget buildPlacesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) => buildPlaceCard(places[index]),
    );
  }

  Widget buildPlaceCard(FavoritePlace place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
        );
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(
                      place.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryLight.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.image, size: 48, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
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
                      color: AppColors.primary,
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
                          place.name,
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
                        place.rating.toString(),
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
                        place.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: place.price,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: place.isFree ? AppColors.primary : AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: place.priceUnit,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritePlace {
  final String name;
  final String location;
  final String price;
  final String priceUnit;
  final double rating;
  final String imageUrl;
  final bool isFree;

  const FavoritePlace({
    required this.name,
    required this.location,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.imageUrl,
    required this.isFree,
  });
}
