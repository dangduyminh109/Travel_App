import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => ReviewsScreenState();
}

class ReviewsScreenState extends State<ReviewsScreen> {
  final List<Review> reviews = const [
    Review(
      name: 'An Nhiên',
      date: 'Tháng 5, 2024',
      rating: 5,
      avatarUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200',
      comment:
          'Chuyến đi tuyệt vời! Vị trí rất thuận lợi, gần các điểm tham quan chính. Dịch vụ chuyên nghiệp và nhân viên thân thiện, sẽ quay lại.',
    ),
    Review(
      name: 'Minh Khang',
      date: 'Tháng 5, 2024',
      rating: 4,
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      comment:
          'Trải nghiệm thú vị nhưng cần cải thiện một chút về tốc độ phục vụ. Vị trí tuyệt hảo.',
    ),
    Review(
      name: 'Linh Đan',
      date: 'Tháng 4, 2024',
      rating: 5,
      avatarUrl:
          'https://images.unsplash.com/photo-1544723795-432537f0b7c7?w=200',
      comment:
          'Không gian đẹp, tiện nghi sạch sẽ. Rất thích khu vực hồ bơi và nhà hàng.',
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
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                itemCount: reviews.length,
                itemBuilder: (context, index) => buildReviewCard(reviews[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.3,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF005B7F), Color(0xFF007F8C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Đánh giá & Xếp hạng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    '4.7',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 18, left: 4),
                    child: Text('/ 5', style: TextStyle(color: Colors.white70, fontSize: 20)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildCriteriaRow('Vị trí', 0.96, 4.8),
                      const SizedBox(height: 10),
                      buildCriteriaRow('Dịch vụ', 0.9, 4.5),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(review.avatarUrl),
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCriteriaRow(String label, double progress, double score) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    score.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class Review {
  final String name;
  final String date;
  final int rating;
  final String comment;
  final String avatarUrl;

  const Review({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.avatarUrl,
  });
}
