import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => FilterBottomSheetState();
}

class FilterBottomSheetState extends State<FilterBottomSheet> {
  bool fourStars = true;
  bool fiveStars = false;
  bool topRated = false;

  RangeValues priceRange = const RangeValues(0.5, 3.0);

  final Map<String, bool> regions = {
    'Miền Bắc': true,
    'Miền Trung': false,
    'Miền Nam': false,
    'Tây Nguyên': false,
  };

  String get rangeLabel {
    final start = (priceRange.start * 1000000).round();
    final end = (priceRange.end * 1000000).round();
    return 'Phạm vi: ${formatCurrency(start)} - ${formatCurrency(end)}';
  }

  String formatCurrency(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}.000.000đ'.replaceAll('.0', '');
    }
    return '${value ~/ 1000}0.000đ';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(context),
            const SizedBox(height: 16),
            buildSectionTitle('Đánh giá'),
            buildRatingOptions(),
            const SizedBox(height: 20),
            buildSectionTitle('Giá'),
            buildPriceSection(),
            const SizedBox(height: 20),
            buildSectionTitle('Khu vực'),
            buildRegionSection(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'ratings': {
                    '4plus': fourStars,
                    '5stars': fiveStars,
                    'topRated': topRated,
                  },
                  'priceRange': priceRange,
                  'regions': Map<String, bool>.from(regions),
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Áp dụng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Bộ lọc tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget buildRatingOptions() {
    return Column(
      children: [
        ratingTile(
          label: '4 sao trở lên',
          value: fourStars,
          stars: 4,
          onChanged: (v) => setState(() => fourStars = v ?? false),
        ),
        ratingTile(
          label: '5 sao',
          value: fiveStars,
          stars: 5,
          onChanged: (v) => setState(() => fiveStars = v ?? false),
        ),
        ratingTile(
          label: 'Đánh giá cao nhất',
          value: topRated,
          stars: null,
          onChanged: (v) => setState(() => topRated = v ?? false),
        ),
      ],
    );
  }

  Widget ratingTile({
    required String label,
    required bool value,
    int? stars,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (stars != null) ...[
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                stars,
                (_) => const Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('0đ', style: TextStyle(color: AppColors.textSecondary)),
              Text('5.000.000đ+', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 5,
          divisions: 10,
          labels: RangeLabels(
            '${(priceRange.start * 1000000).round().toStringAsFixed(0)}đ',
            '${(priceRange.end * 1000000).round().toStringAsFixed(0)}đ',
          ),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.divider,
          onChanged: (values) => setState(() => priceRange = values),
        ),
        Text(
          rangeLabel,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget buildRegionSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: regions.entries.map((entry) {
        return FilterChip(
          label: Text(entry.key),
          selected: entry.value,
          onSelected: (selected) => setState(() => regions[entry.key] = selected),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: entry.value ? AppColors.primaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: AppColors.divider.withValues(alpha: 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
}

