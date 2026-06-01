import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import '../../core/data/destination_model.dart';
import 'admin_destination_form_screen.dart';

class AdminDestinationListScreen extends StatefulWidget {
  const AdminDestinationListScreen({super.key});

  @override
  State<AdminDestinationListScreen> createState() =>
      _AdminDestinationListScreenState();
}

class _AdminDestinationListScreenState
    extends State<AdminDestinationListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<DestinationModel> _all = [];
  List<DestinationModel> _visible = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAll();
      if (!mounted) return;
      setState(() {
        _all = data;
        _visible = data;
        _isLoading = false;
      });
      _applyFilter();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Không thể tải danh sách địa điểm.');
    }
  }

  void _applyFilter() {
    final keyword = _searchController.text.trim().toLowerCase();
    setState(() {
      _visible = keyword.isEmpty
          ? _all
          : _all.where((item) {
              return item.title.toLowerCase().contains(keyword) ||
                  item.city.toLowerCase().contains(keyword) ||
                  item.district.toLowerCase().contains(keyword);
            }).toList();
    });
  }

  Future<void> _openForm({DestinationModel? destination}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDestinationFormScreen(destination: destination),
      ),
    );
    if (changed == true) {
      _loadData();
    }
  }

  Future<void> _delete(DestinationModel destination) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa điểm'),
        content: Text('Bạn chắc chắn muốn xóa "${destination.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deleteAdminDestination(destination.id);
      _showMessage('Đã xóa địa điểm.');
      _loadData();
    } catch (e) {
      _showMessage(_cleanError(e));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Quản lý địa điểm'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm địa điểm quản trị...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      itemCount: _visible.length,
                      itemBuilder: (context, index) {
                        final destination = _visible[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: destination.imageUrl.isEmpty
                                  ? _imageFallback()
                                  : Image.network(
                                      destination.imageUrl,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _imageFallback(),
                                    ),
                            ),
                            title: Text(
                              destination.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              [
                                destination.shortLocationText,
                                destination.placeTypeLabel,
                              ].where((item) => item.isNotEmpty).join(' • '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Sửa',
                                  onPressed: () =>
                                      _openForm(destination: destination),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Xóa',
                                  onPressed: () => _delete(destination),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.primaryLight.withValues(alpha: 0.2),
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    final text = error.toString();
    if (text.contains('409')) {
      return 'Không thể xóa địa điểm đã có đánh giá hoặc yêu thích.';
    }
    if (text.contains('403')) {
      return 'Bạn không có quyền quản trị.';
    }
    return 'Thao tác không thành công.';
  }
}
