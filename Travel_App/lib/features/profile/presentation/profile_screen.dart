import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/data/auth_service.dart';
import '../settings_screen.dart';
import '../edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  final AuthService _authService = AuthService();

  String _displayName = '';
  String _email = '';
  String? _photoUrl;

  final List<Map<String, String>> savedPlaces = const [
    {
      'name': 'Hạ Long Bay',
      'image':
          'https://images.unsplash.com/photo-1528127269322-539801943592?w=400',
    },
    {
      'name': 'Hội An',
      'image':
          'https://images.unsplash.com/photo-1442850473887-0fb77cd0b337?w=400',
    },
    {
      'name': 'Sapa',
      'image':
          'https://images.unsplash.com/photo-1570366583862-f91883984fde?w=400',
    },
    {
      'name': 'Điện Biên',
      'image':
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400',
    },
    {
      'name': 'Cao Bằng',
      'image':
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=400',
    },
    {
      'name': 'Đà Lạt',
      'image':
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=400',
    },
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    // Ưu tiên lấy từ Firebase Auth (luôn mới nhất)
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      setState(() {
        _displayName = firebaseUser.displayName ?? '';
        _email = firebaseUser.email ?? '';
        _photoUrl = firebaseUser.photoURL;
      });
      return;
    }
    // Fallback: lấy từ local session
    final session = await _authService.getUserSession();
    if (session != null && mounted) {
      setState(() {
        _displayName = (session['displayName'] as String?) ?? '';
        _email = (session['email'] as String?) ?? '';
        _photoUrl = (session['photoUrl'] as String?);
      });
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Hồ sơ người dùng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              // Reload user info in case it changed (e.g. logged out)
              _loadUserInfo();
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 16),
            buildProfileHeader(context),
            const SizedBox(height: 20),
            buildTabs(),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [buildSavedPlacesTab(), buildMyReviewsPlaceholder()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader(BuildContext context) {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    final displayName = _displayName.isNotEmpty ? _displayName : 'Người dùng';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
          backgroundImage: hasPhoto ? NetworkImage(_photoUrl!) : null,
          onBackgroundImageError: hasPhoto ? (exception, stackTrace) {} : null,
          child: hasPhoto
              ? null
              : Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          displayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (_email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _email,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
            // Reload after editing profile
            _loadUserInfo();
          },
          icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
          label: const Text(
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Địa điểm đã lưu'),
          Tab(text: 'Đánh giá của tôi'),
        ],
      ),
    );
  }

  Widget buildSavedPlacesTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: savedPlaces.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final place = savedPlaces[index];
          return Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    place['image']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                place['name']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildMyReviewsPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.reviews_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'Bạn chưa có đánh giá nào.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
