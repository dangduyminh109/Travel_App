import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../place_detail/place_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {

  static const List<CategoryItem> categories = [
    CategoryItem(icon: Icons.beach_access, label: 'Biển'),
    CategoryItem(icon: Icons.terrain, label: 'Núi'),
    CategoryItem(icon: Icons.restaurant, label: 'Ẩm thực'),
    CategoryItem(icon: Icons.location_city, label: 'Thành phố'),
  ];

  static const List<DestinationItem> trending = [
    DestinationItem(
      title: 'Hội An',
      subtitle: 'Phố cổ lung linh',
      imageUrl:
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=400',
    ),
    DestinationItem(
      title: 'Hạ Long',
      subtitle: 'Vịnh di sản',
      imageUrl:
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=400',
    ),
    DestinationItem(
      title: 'Phú Quốc',
      subtitle: 'Bãi Sao tuyệt đẹp',
      imageUrl:
          'https://images.unsplash.com/photo-1540611025311-01df3cee54b5?w=400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  buildFeaturedCard(context),
                  const SizedBox(height: 24),
                  buildSectionTitle('Xu hướng'),
                  const SizedBox(height: 12),
                  buildTrendingList(context),
                ],
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
                    prefixIcon:
                        Icon(Icons.search, color: AppColors.textSecondary),
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
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 20),
                  itemBuilder: (_, i) => buildCategoryChip(categories[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCategoryChip(CategoryItem item) {
    return SizedBox(
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
            child: Icon(item.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
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
                  'https://images.unsplash.com/photo-1570366583862-f91883984fde?w=800',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.primaryLight,
                    child: const Center(
                      child: Icon(Icons.landscape, size: 60, color: Colors.white54),
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
                    const Text(
                      'Sapa: Ruộng bậc thang hùng vĩ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14,
                            color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        const Text(
                          'Miền Bắc',
                          style: TextStyle(
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
        itemCount: trending.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (_, i) => buildTrendingCard(context, trending[i]),
      ),
    );
  }

  Widget buildTrendingCard(BuildContext context, DestinationItem item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
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
                  item.imageUrl,
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
              item.title,
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
              item.subtitle,
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

class CategoryItem {
  final IconData icon;
  final String label;

  const CategoryItem({required this.icon, required this.label});
}

class DestinationItem {
  final String title;
  final String subtitle;
  final String imageUrl;

  const DestinationItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
