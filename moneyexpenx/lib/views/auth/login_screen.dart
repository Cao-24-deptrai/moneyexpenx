import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/views/dashboard/dashboard_screen.dart';
import 'package:moneyexpenx/core/utils/route_transitions.dart';

enum AuthMode { login, signUp, forgotPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  AuthMode _authMode = AuthMode.login;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _changeMode(AuthMode mode) {
    _animationController.forward().then((_) {
      setState(() {
        _authMode = mode;
        _formKey.currentState?.reset();
      });
      _animationController.reverse();
    });
  }

  Future<void> _submit() async {
    if (_authMode == AuthMode.forgotPassword) {
      await _submitForgotPassword();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Vui lòng điền đúng và đầy đủ thông tin yêu cầu.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
    bool success = false;

    if (_authMode == AuthMode.signUp) {
      success = await authVm.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authVm.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }

    if (success && mounted) {
      // Load user finance data
      final uid = authVm.currentUser!.uID;
      await financeVm.loadData(uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _authMode == AuthMode.signUp ? "Đăng ký tài khoản thành công!" : "Đăng nhập thành công!",
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          FadePageRoute(page: const DashboardScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authVm.errorMessage ?? "Lỗi xác thực. Vui lòng kiểm tra lại thông tin.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Vui lòng điền địa chỉ email.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Email không đúng định dạng.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    bool success = await authVm.sendPasswordReset(email);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Đã gửi liên kết khôi phục mật khẩu đến email của bạn.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      _changeMode(AuthMode.login);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authVm.errorMessage ?? "Có lỗi xảy ra. Vui lòng thử lại sau.",
            style: GoogleFonts.beVietnamPro(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authVm = Provider.of<AuthViewModel>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background design details
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.14),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.7,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.06),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Scrollable content
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Hero(
                    tag: 'app_logo',
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 80,
                      color: AppTheme.primaryYellow,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'MoneyExpenx',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppTheme.primaryYellow,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quản lý chi tiêu thông minh',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          letterSpacing: 0.5,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 36),
                  
                  // Glassmorphism card for inputs
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1.0 - _fadeAnimation.value,
                        child: child,
                      );
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(28.0),
                      width: double.infinity,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_authMode != AuthMode.forgotPassword) ...[
                              _buildSlidingToggle(),
                              const SizedBox(height: 28),
                            ] else ...[
                              Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                                    onPressed: () => _changeMode(AuthMode.login),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quên Mật Khẩu',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Nhập địa chỉ email của bạn, chúng tôi sẽ gửi liên kết khôi phục mật khẩu.',
                                style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            if (_authMode == AuthMode.signUp) ...[
                              _buildTextField(
                                controller: _usernameController,
                                label: 'Tên người dùng',
                                icon: Icons.person_outline,
                                validator: (val) => val == null || val.trim().isEmpty
                                    ? 'Vui lòng nhập tên người dùng'
                                    : val.trim().length < 3
                                        ? 'Tên người dùng tối thiểu 3 ký tự'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Vui lòng nhập email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                            ),
                            
                            if (_authMode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Mật khẩu',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                isPassword: true,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                validator: (val) => val == null || val.length < 6
                                    ? 'Mật khẩu cần ít nhất 6 ký tự'
                                    : null,
                              ),
                            ],

                            if (_authMode == AuthMode.signUp) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Xác nhận mật khẩu',
                                icon: Icons.lock_clock_outlined,
                                obscureText: _obscureConfirmPassword,
                                isPassword: true,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                                  if (val != _passwordController.text) {
                                    return 'Mật khẩu xác nhận không trùng khớp';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            if (_authMode == AuthMode.login) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => _changeMode(AuthMode.forgotPassword),
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.primaryYellow,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 28),
                            authVm.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      height: 52,
                                      width: 52,
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation(AppTheme.primaryYellow),
                                        ),
                                      ),
                                    ),
                                  )
                                : GlassCardButton(
                                    color: AppTheme.primaryYellow,
                                    borderColor: AppTheme.secondaryYellow.withOpacity(0.3),
                                    onTap: _submit,
                                    child: Container(
                                      height: 52,
                                      alignment: Alignment.center,
                                      child: Text(
                                        _authMode == AuthMode.signUp
                                            ? 'ĐĂNG KÝ NGAY'
                                            : _authMode == AuthMode.login
                                                ? 'ĐĂNG NHẬP'
                                                : 'GỬI LIÊN KẾT',
                                        style: GoogleFonts.beVietnamPro(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                            
                            if (_authMode != AuthMode.forgotPassword) ...[
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  _changeMode(_authMode == AuthMode.login ? AuthMode.signUp : AuthMode.login);
                                },
                                child: Text(
                                  _authMode == AuthMode.signUp
                                      ? 'Đã có tài khoản? Đăng nhập ngay'
                                      : 'Chưa có tài khoản? Đăng ký ngay',
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.primaryYellow,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => _changeMode(AuthMode.login),
                                child: Text(
                                  'Quay lại đăng nhập',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidingToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: _authMode == AuthMode.login
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryYellow, AppTheme.secondaryYellow],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeMode(AuthMode.login),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Đăng Nhập',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _authMode == AuthMode.login ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _changeMode(AuthMode.signUp),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Đăng Ký',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _authMode == AuthMode.signUp ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.beVietnamPro(color: AppTheme.primaryYellow),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.textSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.alertRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.alertRed, width: 2),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
