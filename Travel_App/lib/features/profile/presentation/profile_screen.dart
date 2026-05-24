import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/data/auth_service.dart';
import '../settings_screen.dart';
import '../edit_profile_screen.dart';
import '../../../core/data/api_service.dart';
import '../../../core/data/destination_model.dart';
import '../../../core/data/review_model.dart';
import '../../auth/login_screen.dart';
import '../../place_detail/place_detail_screen.dart';
import '../../place_detail/presentation/reviews_screen.dart';

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
  String? _currentUid;

  final ApiService _api = ApiService();
  List<DestinationModel> _savedPlaces = [];
  List<ReviewModel> _userReviews = [];
  bool _isCheckingAuth = true;
  bool _isLoadingSaved = true;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (mounted) {
      setState(() {
        _isCheckingAuth = true;
        _isLoadingSaved = true;
        _isLoadingReviews = true;
      });
    }
    String? currentUid;
    // Ưu tiên lấy từ Firebase Auth (luôn mới nhất)
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      currentUid = firebaseUser.uid;
      setState(() {
        _displayName = firebaseUser.displayName ?? '';
        _email = firebaseUser.email ?? '';
        _photoUrl = firebaseUser.photoURL;
      });
    } else {
      // Fallback: lấy từ local session
      final session = await _authService.getUserSession();
      if (session != null && mounted) {
        currentUid = session['uid'] as String?;
        setState(() {
          _displayName = (session['displayName'] as String?) ?? '';
          _email = (session['email'] as String?) ?? '';
          _photoUrl = (session['photoUrl'] as String?);
        });
      }
    }

    if (currentUid != null) {
      if (mounted) {
        setState(() {
          _currentUid = currentUid;
          _isCheckingAuth = false;
        });
      }
      // Lấy avatar từ Backend DB (đã được cập nhật sau khi edit profile)
      _fetchUserProfile(currentUid);
      _fetchSavedPlaces(currentUid);
      _fetchUserReviews(currentUid);
    } else {
      if (mounted) {
        setState(() {
          _currentUid = null;
          _displayName = '';
          _email = '';
          _photoUrl = null;
          _savedPlaces = [];
          _userReviews = [];
          _isCheckingAuth = false;
          _isLoadingSaved = false;
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final profile = await _api.getUserProfile(uid);
      if (profile.isNotEmpty && mounted) {
        String? avatarUrl;
        if (profile['avatarUrl'] != null &&
            profile['avatarUrl'].toString().isNotEmpty) {
          avatarUrl = profile['avatarUrl'];
          if (avatarUrl != null && avatarUrl.startsWith('/uploads')) {
            avatarUrl = 'http://10.0.2.2:8080$avatarUrl';
          }
        }
        setState(() {
          if (profile['fullName'] != null &&
              profile['fullName'].toString().isNotEmpty) {
            _displayName = profile['fullName'];
          }
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            _photoUrl = avatarUrl;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchSavedPlaces(String uid) async {
    try {
      final favIds = await _api.getFavoriteIds(uid);
      if (favIds.isEmpty && mounted) {
        setState(() {
          _savedPlaces = [];
          _isLoadingSaved = false;
        });
        return;
      }
      final allDests = await _api.getAll();
      final favorites = allDests.where((e) => favIds.contains(e.id)).toList();
      if (mounted) {
        setState(() {
          _savedPlaces = favorites;
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  Future<void> _fetchUserReviews(String uid) async {
    try {
      final reviews = await _api.getUserReviews(uid);
      if (mounted) {
        setState(() {
          _userReviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = _currentUid != null && _currentUid!.isNotEmpty;

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
          if (isSignedIn)
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
      body: _isCheckingAuth
          ? const Center(child: CircularProgressIndicator())
          : isSignedIn
          ? DefaultTabController(
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
                      children: [buildSavedPlacesTab(), buildMyReviewsTab()],
                    ),
                  ),
                ],
              ),
            )
          : buildGuestProfile(),
    );
  }

  Widget buildGuestProfile() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Khám phá không cần đăng nhập',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn vẫn có thể xem địa điểm, tìm kiếm và đọc thông tin du lịch. Đăng nhập khi muốn đánh giá, đồng bộ yêu thích hoặc chỉnh hồ sơ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (mounted) {
                      _loadUserInfo();
                    }
                  },
                  icon: const Icon(Icons.login, size: 20),
                  label: const Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    if (_isLoadingSaved) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_savedPlaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'Bạn chưa lưu địa điểm nào.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        itemCount: _savedPlaces.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.78,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final place = _savedPlaces[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceDetailScreen(destination: place),
                ),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      place.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  place.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Widget buildMyReviewsTab() {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_userReviews.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userReviews.length,
      itemBuilder: (context, index) {
        final review = _userReviews[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ReviewsScreen(destinationId: review.destinationId),
              ),
            );
            // Reload reviews after returning
            final uid = _authService.currentUser?.uid;
            if (uid != null) _fetchUserReviews(uid);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(
                              review.destinationImage ??
                                  'https://via.placeholder.com/150',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.destinationName ?? 'Địa điểm',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(review.createdAt),
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
                      (idx) => Icon(
                        idx < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
          ),
        );
      },
    );
  }
}
