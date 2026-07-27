import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/views/loans/loans_screen.dart';
import 'package:moneyexpenx/views/loans/interest_calculator_view.dart';
import 'package:moneyexpenx/views/export/export_report_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text(
            'Đổi tên hiển thị',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập tên mới...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryYellow),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên hiển thị không được để trống';
                }
                if (value.trim().length < 3) {
                  return 'Tên phải dài hơn 2 ký tự';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newName = _nameController.text.trim();
                  final authVm = Provider.of<AuthViewModel>(context, listen: false);
                  
                  Navigator.pop(context); // Close dialog

                  bool success = await authVm.updateUsername(newName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Cập nhật tên thành công!'
                              : (authVm.errorMessage ?? 'Đã xảy ra lỗi khi cập nhật tên.'),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: success ? AppTheme.primaryYellow : AppTheme.alertRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _sendPasswordReset(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Không tìm thấy email của tài khoản.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    bool success = await authVm.sendPasswordReset(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã gửi email đặt lại mật khẩu thành công!'
                : (authVm.errorMessage ?? 'Gửi yêu cầu thất bại.'),
            style: TextStyle(
              color: success ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: success ? AppTheme.primaryYellow : AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authVm = Provider.of<AuthViewModel>(context);
    final financeVm = Provider.of<FinanceViewModel>(context);
    final user = authVm.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryYellow),
          ),
        ),
      );
    }

    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    final String joinDate = formatter.format(user.createdAt);

    return Scaffold(
      body: Stack(
        children: [
          // Background subtle lights
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellow.withOpacity(0.02),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Page Header
                  Text(
                    'Tài khoản cá nhân',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Avatar & Basic Info Card
                  Center(
                    child: Column(
                      children: [
                        // Avatar Ring Gradient
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryYellow, Colors.orangeAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryYellow.withOpacity(0.15),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppTheme.cardBg,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : 'U',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryYellow,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        // Username + Edit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                user.username,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context, user.username),
                              child: const Icon(
                                Icons.edit_note_outlined,
                                color: AppTheme.primaryYellow,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Email display
                        Text(
                          user.email.isNotEmpty ? user.email : 'Chưa cấu hình Email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Financial Statistics Section Title
                  Text(
                    'Tổng quan của bạn',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3 Stats columns inside a GlassContainer
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          value: '${financeVm.transactions.length}',
                          label: 'Giao dịch',
                          icon: Icons.receipt_long,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          value: '${financeVm.savingJars.length}',
                          label: 'Hũ tiết kiệm',
                          icon: Icons.savings_outlined,
                        ),
                        _buildDivider(),
                        _buildStatItem(
                          context,
                          value: '${financeVm.categories.length}',
                          label: 'Danh mục',
                          icon: Icons.grid_view_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Features / Advanced Management Section
                  Text(
                    'Công cụ tài chính nâng cao',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Column(
                    children: [
                      _buildMenuCard(
                        context,
                        title: 'Khoản Vay & Nợ',
                        subtitle: 'Quản lý danh sách cho vay (+) và đi vay (-)',
                        icon: Icons.account_balance_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoansScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        title: 'Máy Tính Lãi Suất Ngân Hàng',
                        subtitle: 'Tính lãi đơn, lãi kép & dư nợ giảm dần',
                        icon: Icons.calculate_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InterestCalculatorView()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        title: 'Xuất Báo Cáo Excel / PDF',
                        subtitle: 'Xuất lịch sử thu chi & dư nợ ra file Excel/CSV/PDF',
                        icon: Icons.file_download_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ExportReportScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Settings / Account Management
                  Text(
                    'Quản lý tài khoản',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Menu Action Cards
                  Column(
                    children: [
                      _buildMenuCard(
                        context,
                        title: 'Đổi tên hiển thị',
                        subtitle: 'Cập nhật tên tài khoản của bạn',
                        icon: Icons.person_outline_outlined,
                        onTap: () => _showEditNameDialog(context, user.username),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        title: 'Đặt lại mật khẩu',
                        subtitle: 'Gửi link khôi phục mật khẩu vào Email',
                        icon: Icons.lock_reset_outlined,
                        onTap: () => _sendPasswordReset(context, user.email),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        context,
                        title: 'Thông tin hệ thống',
                        subtitle: 'Tham gia: $joinDate',
                        icon: Icons.info_outline,
                        onTap: () {
                          // Visual feedback only
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Ứng dụng Quản lý chi tiêu thông minh v1.0.0',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: AppTheme.primaryYellow,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Logout button with gradient border
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppTheme.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            title: const Text('Đăng xuất'),
                            content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Hủy',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.alertRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Đăng xuất'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await authVm.logout();
                        }
                      },
                      child: GlassContainer(
                        height: 56,
                        color: Colors.red.withOpacity(0.08),
                        borderColor: Colors.red.withOpacity(0.2),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Đăng xuất tài khoản',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.08),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryYellow,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GlassCardButton(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryYellow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
