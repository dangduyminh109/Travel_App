import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/auth_service.dart';
import '../../core/data/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  String? _userId;
  String? _photoUrl;
  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      _userId = user.uid;
      emailController.text = user.email ?? '';
    } else {
      final session = await _authService.getUserSession();
      if (session != null) {
        _userId = session['uid'] as String?;
        emailController.text = (session['email'] as String?) ?? '';
      }
    }

    if (_userId != null) {
      try {
        final profile = await _apiService.getUserProfile(_userId!);
        if (profile.isNotEmpty) {
          nameController.text = profile['fullName'] ?? profile['username'] ?? '';
          
          if (profile['avatarUrl'] != null && profile['avatarUrl'].toString().isNotEmpty) {
            String url = profile['avatarUrl'];
            if (url.startsWith('/uploads')) {
               url = 'http://10.0.2.2:8080$url'; 
            }
            _photoUrl = url;
          }
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> handleSave() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tên không được để trống'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Bạn chưa đăng nhập'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Đảm bảo user tồn tại trong DB trước khi update
      final firebaseUser = _authService.currentUser;
      final session = await _authService.getUserSession();
      await _apiService.syncUser(
        uid: _userId!,
        email: firebaseUser?.email ?? (session?['email'] as String?) ?? '',
        displayName: name,
        photoUrl: firebaseUser?.photoURL ?? (session?['photoUrl'] as String?),
      );

      final updatedProfile = await _apiService.updateUserProfile(
        username: _userId!,
        fullName: name,
        avatarPath: _selectedImage?.path,
      );

      // Cập nhật lại UI sau khi save thành công
      if (updatedProfile['avatarUrl'] != null) {
         String url = updatedProfile['avatarUrl'];
         if (url.startsWith('/uploads')) {
            url = 'http://10.0.2.2:8080$url'; 
         }
         _photoUrl = url;
      }
      _selectedImage = null; // reset local file
      
      // Update firebase profile display name if logged in via firebase
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thay đổi thành công!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thất bại. $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 8, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dobController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  buildAvatarSection(),
                  const SizedBox(height: 28),
                  buildProfileFields(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget buildAvatarSection() {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    final name = nameController.text;

    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (hasPhoto) {
      imageProvider = NetworkImage(_photoUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primaryLight.withOpacity(0.2),
            child: CircleAvatar(
              radius: 49,
              backgroundImage: imageProvider,
              onBackgroundImageError: hasPhoto
                  ? (exception, stackTrace) {}
                  : null,
              backgroundColor: AppColors.primaryLight.withOpacity(0.3),
              child: (_selectedImage == null && !hasPhoto)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileFields() {
    return Column(
      children: [
        buildField(label: 'Họ và tên', controller: nameController),
        const Divider(height: 1, color: AppColors.divider),
        buildField(
          label: 'Email',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // Email không thể sửa từ Firebase
        ),
        const Divider(height: 1, color: AppColors.divider),
        buildField(
          label: 'Ngày sinh',
          controller: dobController,
          icon: Icons.calendar_today,
          readOnly: true,
          onTap: pickDate,
        ),
        const Divider(height: 1, color: AppColors.divider),
        buildField(
          label: 'Địa chỉ',
          controller: addressController,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  onTap: onTap,
                  maxLines: maxLines,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: readOnly
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : handleSave,
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
          child: _isSaving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text('Lưu thay đổi'),
        ),
      ),
    );
  }
}
