import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController(text: 'Nguyễn Văn A');
  final emailController = TextEditingController(text: 'nguyen.a@example.com');
  final dobController = TextEditingController(text: '15/08/1990');
  final addressController = TextEditingController(
    text: 'Số 123, Đường Lê Lợi, Quận 1, TP. Hồ Chí Minh,\nViệt Nam',
  );

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thay đổi thành công!')),
    );
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
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
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: CircleAvatar(
              radius: 49,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
              ),
              onBackgroundImageError: (exception, stackTrace) {},
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: const Icon(Icons.person, size: 48, color: Colors.white70),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 17, color: Colors.white),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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
          onPressed: handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Text('Lưu thay đổi'),
        ),
      ),
    );
  }
}

