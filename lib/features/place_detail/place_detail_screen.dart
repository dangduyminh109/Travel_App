import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'presentation/reviews_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key});

  @override
  State<PlaceDetailScreen> createState() => PlaceDetailScreenState();
}

class PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool isFavorited = false;

  static const List<String> tags = [
    'Di sản UNESCO',
    'Du thuyền',
    'Hang động',
    'Tự nhiên',
  ];

  static const String description =
      'Khám phá vẻ đẹp kỳ vĩ của Vịnh Hạ Long, một trong Bảy Kỳ quan '
      'Thiên nhiên Mới của thế giới. Với hơn 1.600 hòn đảo đá vôi lớn nhỏ '
      'nổi trên mặt nước xanh ngọc bích, nơi đây mang đến những trải nghiệm '
      'du thuyền không thể nào quên, khám phá các hang động huyền bí và '
      'thưởng ngoạn cảnh sắc thiên nhiên hùng vĩ.';

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
        'https://images.unsplash.com/photo-1528127269322-539801943592?w=900',
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
              onTap: () => setState(() => isFavorited = !isFavorited),
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
              const Text(
                'VỊNH HẠ LONG',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: tags.map(buildTag).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                description,
                style: TextStyle(
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
                    MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Text(
                        '4.7',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '(12,453 đánh giá)',
                        style: TextStyle(
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
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
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
}

