import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/api_service.dart';
import 'admin_category_list_screen.dart';
import 'admin_destination_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();

  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _topRated = [];
  List<Map<String, dynamic>> _topFavorited = [];
  List<Map<String, dynamic>> _byCategory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final overview = await _api.getAdminOverview();
      final topRated = await _api.getAdminTopRated();
      final topFavorited = await _api.getAdminTopFavorited();
      final byCategory = await _api.getAdminByCategory();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _topRated = topRated;
        _topFavorited = topFavorited;
        _byCategory = byCategory;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu quản trị. Hãy kiểm tra quyền admin.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Quản trị'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 18),
                  _buildOverviewGrid(),
                  const SizedBox(height: 22),
                  _buildSection('Top đánh giá cao', _topRated, 'rating'),
                  const SizedBox(height: 22),
                  _buildSection(
                    'Top được yêu thích',
                    _topFavorited,
                    'favoriteCount',
                  ),
                  const SizedBox(height: 22),
                  _buildCategorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDestinationListScreen(),
                ),
              );
              _loadData();
            },
            icon: const Icon(Icons.place_outlined),
            label: const Text('Địa điểm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCategoryListScreen(),
                ),
              );
              _loadData();
            },
            icon: const Icon(Icons.category_outlined),
            label: const Text('Danh mục'),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid() {
    final cards = [
      _StatCard('Địa điểm', _overview['destinationCount'], Icons.place),
      _StatCard('Người dùng', _overview['userCount'], Icons.people),
      _StatCard('Đánh giá', _overview['reviewCount'], Icons.star),
      _StatCard('Yêu thích', _overview['favoriteCount'], Icons.bookmark),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Icon(card.icon, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${card.value ?? 0}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<Map<String, dynamic>> rows,
    String valueKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          _emptyBox('Chưa có dữ liệu.')
        else
          ...rows.map((row) => _destinationRow(row, valueKey)),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Số địa điểm theo danh mục'),
        const SizedBox(height: 10),
        if (_byCategory.isEmpty)
          _emptyBox('Chưa có dữ liệu.')
        else
          ..._byCategory.map(
            (row) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  const Icon(Icons.pie_chart_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row['category']?.toString() ?? 'Khác',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${row['count'] ?? 0}'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _destinationRow(Map<String, dynamic> row, String valueKey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title']?.toString() ?? 'Địa điểm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  [row['district'], row['city']]
                      .where(
                        (item) => item != null && item.toString().isNotEmpty,
                      )
                      .join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${row[valueKey] ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
    );
  }
}

class _StatCard {
  final String title;
  final Object? value;
  final IconData icon;

  const _StatCard(this.title, this.value, this.icon);
}
