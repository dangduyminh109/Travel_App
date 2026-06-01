import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import '../../core/data/category_model.dart';
import '../../core/data/destination_model.dart';

class AdminDestinationFormScreen extends StatefulWidget {
  final DestinationModel? destination;

  const AdminDestinationFormScreen({super.key, this.destination});

  @override
  State<AdminDestinationFormScreen> createState() =>
      _AdminDestinationFormScreenState();
}

class _AdminDestinationFormScreenState
    extends State<AdminDestinationFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  final _openingHours = TextEditingController();
  final _highlights = TextEditingController();
  final _suitableFor = TextEditingController();
  final _tags = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  List<CategoryModel> _categories = [];
  int? _categoryId;
  String _placeType = 'FOOD';
  String _priceLevel = 'BUDGET';
  bool _isLoading = true;
  bool _isSaving = false;

  static const _placeTypes = {
    'FOOD': 'Ăn uống',
    'ENTERTAINMENT': 'Vui chơi',
    'HOTEL': 'Nghỉ ngơi',
    'CAFE': 'Cafe/check-in',
    'CULTURE_HISTORY': 'Văn hóa/lịch sử',
    'SHOPPING': 'Mua sắm',
  };

  static const _priceLevels = {
    'FREE': 'Miễn phí',
    'BUDGET': 'Bình dân',
    'MODERATE': 'Tầm trung',
    'PREMIUM': 'Cao cấp',
    'LUXURY': 'Sang trọng',
  };

  @override
  void initState() {
    super.initState();
    _fillForm();
    _loadCategories();
  }

  void _fillForm() {
    final item = widget.destination;
    if (item == null) return;
    _title.text = item.title;
    _subtitle.text = item.subtitle;
    _description.text = item.description;
    _imageUrl.text = item.imageUrl;
    _city.text = item.city;
    _district.text = item.district;
    _address.text = item.address;
    _minPrice.text = item.minPrice?.toString() ?? '';
    _maxPrice.text = item.maxPrice?.toString() ?? '';
    _openingHours.text = item.openingHours;
    _highlights.text = item.highlights;
    _suitableFor.text = item.suitableFor;
    _tags.text = item.tags;
    _latitude.text = item.latitude?.toString() ?? '';
    _longitude.text = item.longitude?.toString() ?? '';
    _categoryId = item.categoryId;
    if (_placeTypes.containsKey(item.placeType)) _placeType = item.placeType;
    if (_priceLevels.containsKey(item.priceLevel)) {
      _priceLevel = item.priceLevel;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _api.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = data;
        _categoryId ??= data.isNotEmpty ? data.first.id : null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      _showMessage('Vui lòng tạo danh mục trước.');
      return;
    }
    setState(() => _isSaving = true);
    final payload = {
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'description': _description.text.trim(),
      'imageUrl': _imageUrl.text.trim(),
      'region': _city.text.trim(),
      'city': _city.text.trim(),
      'district': _district.text.trim(),
      'address': _address.text.trim(),
      'placeType': _placeType,
      'priceLevel': _priceLevel,
      'minPrice': _parseInt(_minPrice.text),
      'maxPrice': _parseInt(_maxPrice.text),
      'openingHours': _openingHours.text.trim(),
      'highlights': _highlights.text.trim(),
      'suitableFor': _suitableFor.text.trim(),
      'categoryId': _categoryId,
      'tags': _tags.text.trim(),
      'latitude': _parseDouble(_latitude.text),
      'longitude': _parseDouble(_longitude.text),
    };
    try {
      if (widget.destination == null) {
        await _api.createAdminDestination(payload);
      } else {
        await _api.updateAdminDestination(widget.destination!.id, payload);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(_cleanError(e));
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _description,
      _imageUrl,
      _city,
      _district,
      _address,
      _minPrice,
      _maxPrice,
      _openingHours,
      _highlights,
      _suitableFor,
      _tags,
      _latitude,
      _longitude,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          widget.destination == null ? 'Thêm địa điểm' : 'Sửa địa điểm',
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(_title, 'Tên địa điểm', isRequired: true),
                  _field(_subtitle, 'Mô tả ngắn'),
                  _field(
                    _description,
                    'Mô tả chi tiết',
                    isRequired: true,
                    maxLines: 4,
                  ),
                  _field(_imageUrl, 'URL ảnh'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(_city, 'Thành phố', isRequired: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_district, 'Quận/khu vực')),
                    ],
                  ),
                  _field(_address, 'Địa chỉ'),
                  _dropdown<int>(
                    label: 'Danh mục',
                    value: _categoryId,
                    items: _categories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  _dropdown<String>(
                    label: 'Loại địa điểm',
                    value: _placeType,
                    items: _placeTypes.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _placeType = value ?? _placeType),
                  ),
                  _dropdown<String>(
                    label: 'Mức giá',
                    value: _priceLevel,
                    items: _priceLevels.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _priceLevel = value ?? _priceLevel),
                  ),
                  Row(
                    children: [
                      Expanded(child: _field(_minPrice, 'Giá thấp nhất')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_maxPrice, 'Giá cao nhất')),
                    ],
                  ),
                  _field(_openingHours, 'Giờ mở cửa'),
                  _field(_highlights, 'Điểm nổi bật, cách nhau bằng dấu phẩy'),
                  _field(_suitableFor, 'Phù hợp với ai'),
                  _field(_tags, 'Tag tìm kiếm'),
                  Row(
                    children: [
                      Expanded(child: _field(_latitude, 'Vĩ độ')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_longitude, 'Kinh độ')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Lưu địa điểm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: isRequired
            ? (value) =>
                  value == null || value.trim().isEmpty ? 'Bắt buộc nhập' : null
            : null,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  int? _parseInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  double? _parseDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    final text = error.toString();
    if (text.contains('400')) return 'Dữ liệu chưa hợp lệ.';
    if (text.contains('403')) return 'Bạn không có quyền quản trị.';
    return 'Không thể lưu địa điểm.';
  }
}
