import 'package:flutter/material.dart';
import 'package:travel_app/features/main_screen.dart';
import '../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool agreeToTerms = false;
  bool otpSent = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async{
    if (formKey.currentState!.validate()) {
      if (!agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đồng ý với Điều khoản & Chính sách bảo mật'),
          ),
        );
        return;
      }
      loading(context);

      //Dang ky voi Firebase
      try{
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());

        // Tùy chọn cập nhật display name vào profile
        await userCredential.user?.updateDisplayName(nameController.text.trim());

        // Tắt Loading
        if(!mounted) return;
        Navigator.pop(context);

        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => MainScreen(),)
        );

      } on FirebaseAuthException catch(e){
        //Tắt loading khi bị lỗi
        if (!mounted) return;
        Navigator.of(context).pop();

        String message ;
        if (e.code == 'weak-password') {
          message = "Mật khẩu quá yếu.";
        } else if (e.code == 'email-already-in-use') {
          message = "Email này đã được đăng ký tài khoản khác.";
        } else if (e.code == 'invalid-email') {
          message = "Định dạng email không hợp lệ.";
        }else{
          message = "Đã xảy ra lỗi";
        }

        ScaffoldMessenger.of(context).showSnackBar(thongBao('Lỗi', message));
      }
      catch(e){
        if(!mounted) return;
        Navigator.of(context).pop();
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            buildHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tạo tài khoản mới',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      label('Họ và tên'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: inputDeco(
                          hint: 'Nhập họ và tên của bạn',
                          icon: Icons.person_outline,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                          if (v.trim().length < 2) return 'Tên phải có ít nhất 2 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      label('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDeco(
                          hint: 'name@example.com',
                          icon: Icons.mail_outline,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      label('Mật khẩu'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: inputDeco(
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                          if (v.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: agreeToTerms,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (v) =>
                                  setState(() => agreeToTerms = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => agreeToTerms = !agreeToTerms),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Tôi đồng ý với ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Điều khoản',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' & '),
                                    TextSpan(
                                      text: 'Chính sách bảo mật',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            // onTap: () => Navigator.of(context).push(
                            //   MaterialPageRoute(builder: (context) => const LoginScreen())
                            // ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004D56), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.travel_explore,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'VietNam Travel Member',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Khám phá mọi\nmiền Tổ quốc 🇻🇳',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lên kế hoạch, lưu hành trình và nhận\nthông báo ưu đãi nhanh chóng.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void sendOtp() {
    final email = emailController.text.trim();
    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập email hợp lệ trước')),
      );
      return;
    }
    setState(() => otpSent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã gửi mã xác nhận tới $email')),
    );
  }

  Widget label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration inputDeco({
    required String hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: AppColors.textSecondary, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      prefixIcon: icon != null
          ? Icon(icon, color: AppColors.primary, size: 20)
          : null,
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
    );
  }
}

 SnackBar thongBao(String tieuDe, String noiDung){
    return SnackBar(
      content: Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tieuDe,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              noiDung,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: tieuDe.compareTo('Thành công') == 0 ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating, // Làm SnackBar nổi lên
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Bo góc xịn xò
      ),
      margin: const EdgeInsets.all(20), // Cách các cạnh màn hình
      duration: const Duration(seconds: 3),
      elevation: 6, // Tạo bóng đổ
    );
  }

  Future<dynamic> loading(BuildContext context){
    return showDialog(
      context: context,
      barrierDismissible: false, // Ngăn người dùng nhấn ra ngoài để tắt
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const CircularProgressIndicator(
            color: Colors.blue, // Hoặc AppColors.primary của bạn
          ),
        ),
      ),
    );
  }


// end of file
