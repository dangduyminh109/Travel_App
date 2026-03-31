import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../place_detail/place_detail_screen.dart';
import 'presentation/widgets/filter_bottom_sheet.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => SearchExploreScreenState();
}

class SearchExploreScreenState extends State<SearchExploreScreen> {
  int selectedChipIndex = 0;
  final searchController = TextEditingController();

  static const List<String> filters = [
    'Tất cả',
    'Biển',
    'Núi',
    'Di sản',
    'Ẩm thực',
  ];

  static final List<PlaceCardData> places = [
    PlaceCardData(
      title: 'Phố cổ Hội An',
      imageUrl:
          'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?w=600',
      rating: 4.8,
      reviews: 12453,
      tags: ['Quảng Nam', 'Di sản văn hóa'],
    ),
    PlaceCardData(
      title: 'Đảo Ngọc Phú Quốc',
      imageUrl:
          'https://images.unsplash.com/photo-1540611025311-01df3cee54b5?w=600',
      rating: 4.9,
      reviews: 8300,
      tags: ['Kiên Giang', 'Bãi biển đẹp'],
    ),
    PlaceCardData(
      title: 'Thị xã Sa Pa',
      imageUrl:
          'https://images.unsplash.com/photo-1570366583862-f91883984fde?w=600',
      rating: 4.7,
      reviews: 6120,
      tags: ['Lào Cai', 'Núi đồi'],
    ),
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            Expanded(child: buildPlaceList()),
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
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm điểm đến, khách sạn...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                  suffixIcon: Icon(Icons.mic_none, color: AppColors.textSecondary, size: 22),
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
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const FilterBottomSheet(),
              );
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
          children: List.generate(filters.length, (i) {
            final isSelected = i == selectedChipIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(filters[i]),
                selected: isSelected,
                onSelected: (_) => setState(() => selectedChipIndex = i),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
      itemCount: places.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => buildPlaceCard(places[index]),
    );
  }

  Widget buildPlaceCard(PlaceCardData place) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaceDetailScreen()),
        );
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
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
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
                    child: const Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.redAccent,
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
                          place.title,
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
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${formatReviews(place.reviews)} đánh giá)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: place.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  String formatReviews(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
    }
    return count.toString();
  }
}

class PlaceCardData {
  final String title;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> tags;

  const PlaceCardData({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.tags,
  });
}
