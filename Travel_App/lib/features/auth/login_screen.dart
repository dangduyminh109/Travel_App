import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/data/auth_service.dart';
import '../main_screen.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool obscurePassword = true;
  bool isLoading = false;
  bool isGoogleLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      if (user == null) {
        showError('Không thể đăng nhập');
      } else {
        navigateToMain();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'user-not-found':
          showError('Email chưa được đăng ký');
          break;
        case 'wrong-password':
        case 'invalid-credential':
          showError('Sai email hoặc mật khẩu');
          break;
        case 'user-disabled':
          showError('Tài khoản đã bị vô hiệu hoá');
          break;
        case 'too-many-requests':
          showError('Quá nhiều lần thử. Vui lòng thử lại sau');
          break;
        case 'invalid-email':
          showError('Email không hợp lệ');
          break;
        case 'network-request-failed':
          showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
          break;
        default:
          showError('Đăng nhập thất bại: ${e.message ?? e.code}');
      }
    } on SocketException {
      if (!mounted) return;
      showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('network')) {
        showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
      } else {
        showError('Đăng nhập thất bại. Vui lòng thử lại');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  Future<void> handleGoogleSignIn() async {
    setState(() => isGoogleLoading = true);
    try {
      final user = await authService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) {
        showError('Đăng nhập Google đã hủy');
      } else {
        navigateToMain();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          showError('Email này đã liên kết với phương thức đăng nhập khác');
          break;
        case 'network-request-failed':
          showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
          break;
        default:
          showError('Đăng nhập Google thất bại: ${e.message ?? e.code}');
      }
    } on SocketException {
      if (!mounted) return;
      showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('network')) {
        showError('Không có kết nối mạng. Vui lòng kiểm tra Internet');
      } else {
        showError('Đăng nhập Google thất bại. Vui lòng thử lại');
      }
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }


  void navigateToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isBusy = isLoading || isGoogleLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildHeroImage(size),
            Transform.translate(
              offset: const Offset(0, -30),
              child: buildBodyContainer(context, isBusy),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeroImage(Size size) {
    return SizedBox(
      height: size.height * 0.35,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1528127269322-539801943592?w=800',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: const Center(
                child: Icon(Icons.landscape, size: 80, color: Colors.white54),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBodyContainer(BuildContext context, bool isBusy) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chào mừng quay trở lại!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Khám phá vẻ đẹp Việt Nam cùng chúng tôi.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline, color: AppColors.primary),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                  return 'Email không hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : handleLogin,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Đăng nhập', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            buildDividerWithText('Hoặc đăng nhập bằng'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: buildSocialButton(
                    label: 'Google',
                    iconPath: 'G',
                    onTap: isGoogleLoading ? null : handleGoogleSignIn,
                    isLoading: isGoogleLoading,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: buildSocialButton(
                    label: 'Facebook',
                    iconPath: 'f',
                    onTap: null,
                    isLoading: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có tài khoản? ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                GestureDetector(
                  onTap: isBusy
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDividerWithText(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget buildSocialButton({
    required String label,
    required String iconPath,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    final Color iconColor = label == 'Google'
        ? Colors.red.shade600
        : Colors.blue.shade700;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Text(
              iconPath,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
