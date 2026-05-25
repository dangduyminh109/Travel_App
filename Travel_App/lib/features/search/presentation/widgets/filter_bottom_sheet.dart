import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? activeCity;
  final String? activeDistrict;
  final String? activePlaceType;
  final String? activePriceLevel;
  final double? activeMinRating;
  final String activeSortBy;

  const FilterBottomSheet({
    super.key,
    this.activeCity,
    this.activeDistrict,
    this.activePlaceType,
    this.activePriceLevel,
    this.activeMinRating,
    required this.activeSortBy,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? city;
  String? district;
  String? placeType;
  String? priceLevel;
  double? minRating;
  late String sortBy;

  static const _cities = [
    _FilterOption('TP.HCM', 'TP.HCM'),
    _FilterOption('Vũng Tàu', 'Vũng Tàu'),
  ];

  static const _districts = [
    _FilterOption('Quận 1', 'Quận 1'),
    _FilterOption('Quận 3', 'Quận 3'),
    _FilterOption('Bình Thạnh', 'Bình Thạnh'),
    _FilterOption('Thủ Đức', 'Thủ Đức'),
    _FilterOption('Bãi Sau', 'Bãi Sau'),
    _FilterOption('Bãi Trước', 'Bãi Trước'),
    _FilterOption('Núi Nhỏ', 'Núi Nhỏ'),
    _FilterOption('Núi Lớn', 'Núi Lớn'),
  ];

  static const _placeTypes = [
    _FilterOption('Ăn uống', 'FOOD'),
    _FilterOption('Vui chơi', 'ENTERTAINMENT'),
    _FilterOption('Nghỉ ngơi', 'HOTEL'),
    _FilterOption('Cafe/check-in', 'CAFE'),
    _FilterOption('Văn hóa/lịch sử', 'CULTURE_HISTORY'),
    _FilterOption('Mua sắm', 'SHOPPING'),
  ];

  static const _priceLevels = [
    _FilterOption('Miễn phí', 'FREE'),
    _FilterOption('Bình dân', 'BUDGET'),
    _FilterOption('Tầm trung', 'MODERATE'),
    _FilterOption('Cao cấp', 'PREMIUM'),
    _FilterOption('Sang trọng', 'LUXURY'),
  ];

  static const _sortOptions = [
    _FilterOption('Phù hợp nhất', 'relevance'),
    _FilterOption('Đánh giá cao', 'rating'),
    _FilterOption('Mới nhất', 'newest'),
    _FilterOption('Giá thấp', 'price_asc'),
    _FilterOption('Giá cao', 'price_desc'),
    _FilterOption('Gần nhất', 'distance'),
  ];

  @override
  void initState() {
    super.initState();
    city = widget.activeCity;
    district = widget.activeDistrict;
    placeType = widget.activePlaceType;
    priceLevel = widget.activePriceLevel;
    minRating = widget.activeMinRating;
    sortBy = widget.activeSortBy;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              _buildHeader(context),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Thành phố', _cities, city, (value) {
                        setState(() => city = _toggle(city, value));
                      }),
                      _buildSection('Quận/khu vực', _districts, district, (
                        value,
                      ) {
                        setState(() => district = _toggle(district, value));
                      }),
                      _buildSection('Loại địa điểm', _placeTypes, placeType, (
                        value,
                      ) {
                        setState(() => placeType = _toggle(placeType, value));
                      }),
                      _buildSection('Giá tham khảo', _priceLevels, priceLevel, (
                        value,
                      ) {
                        setState(() => priceLevel = _toggle(priceLevel, value));
                      }),
                      _buildRatingSection(),
                      _buildSection('Sắp xếp', _sortOptions, sortBy, (value) {
                        setState(() => sortBy = value);
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Bộ lọc tìm kiếm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
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

  Widget _buildSection(
    String title,
    List<_FilterOption> options,
    String? selectedValue,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: options.map((option) {
              final selected = selectedValue == option.value;
              return FilterChip(
                label: Text(option.label),
                selected: selected,
                onSelected: (_) => onSelected(option.value),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    final ratings = [
      _RatingOption('Từ 3+', 3),
      _RatingOption('Từ 4+', 4),
      _RatingOption('Từ 4.5+', 4.5),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Đánh giá'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: ratings.map((option) {
              final selected = minRating == option.value;
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(option.label),
                  ],
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    minRating = selected ? null : option.value;
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                city = null;
                district = null;
                placeType = null;
                priceLevel = null;
                minRating = null;
                sortBy = 'relevance';
              });
            },
            child: const Text('Xóa lọc'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'city': city,
              'district': district,
              'placeType': placeType,
              'priceLevel': priceLevel,
              'minRating': minRating,
              'sortBy': sortBy,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ),
      ],
    );
  }

  String? _toggle(String? current, String value) {
    return current == value ? null : value;
  }
}

class _FilterOption {
  final String label;
  final String value;

  const _FilterOption(this.label, this.value);
}

class _RatingOption {
  final String label;
  final double value;

  const _RatingOption(this.label, this.value);
}
