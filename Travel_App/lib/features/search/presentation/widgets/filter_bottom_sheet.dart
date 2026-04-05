import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<int> activeRatings;
  final List<String> activeRegions;

  const FilterBottomSheet({
    super.key,
    required this.activeRatings,
    required this.activeRegions,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late bool star1;
  late bool star2;
  late bool star3;
  late bool star4;
  late bool star5;

  late Map<String, bool> regions;

  @override
  void initState() {
    super.initState();
    star1 = widget.activeRatings.contains(1);
    star2 = widget.activeRatings.contains(2);
    star3 = widget.activeRatings.contains(3);
    star4 = widget.activeRatings.contains(4);
    star5 = widget.activeRatings.contains(5);

    regions = {
      'Miền Bắc': widget.activeRegions.contains('Miền Bắc'),
      'Miền Trung': widget.activeRegions.contains('Miền Trung'),
      'Miền Nam': widget.activeRegions.contains('Miền Nam'),
      'Miền Núi': widget.activeRegions.contains('Miền Núi'),
    };
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
            buildSectionTitle('Khu vực'),
            buildRegionSection(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'ratings': [
                    if (star1) 1,
                    if (star2) 2,
                    if (star3) 3,
                    if (star4) 4,
                    if (star5) 5,
                  ],
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
          label: '1 sao',
          value: star1,
          stars: 1,
          onChanged: (v) => setState(() => star1 = v ?? false),
        ),
        ratingTile(
          label: '2 sao',
          value: star2,
          stars: 2,
          onChanged: (v) => setState(() => star2 = v ?? false),
        ),
        ratingTile(
          label: '3 sao',
          value: star3,
          stars: 3,
          onChanged: (v) => setState(() => star3 = v ?? false),
        ),
        ratingTile(
          label: '4 sao',
          value: star4,
          stars: 4,
          onChanged: (v) => setState(() => star4 = v ?? false),
        ),
        ratingTile(
          label: '5 sao',
          value: star5,
          stars: 5,
          onChanged: (v) => setState(() => star5 = v ?? false),
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

