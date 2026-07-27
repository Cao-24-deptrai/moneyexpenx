import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/core/constants/icons.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/core/utils/thousands_formatter.dart';
import 'package:moneyexpenx/views/loans/loans_screen.dart';
import 'package:moneyexpenx/views/loans/interest_calculator_view.dart';
import 'package:moneyexpenx/views/export/export_report_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final formatter = NumberFormat.decimalPattern('vi_VN');
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBudgetAlert();
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _checkBudgetAlert() {
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
    if (financeVm.shouldShowBudgetAlert) {
      _showBudgetExceededDialog(financeVm);
    }
  }

  void _showBudgetExceededDialog(FinanceViewModel financeVm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.alertRed, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: AppTheme.alertRed,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Vượt Ngân Sách!',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.alertRed,
                ),
              ),
            ],
          ),
          content: Text(
            'Cảnh báo: Tổng chi tiêu của bạn trong tháng này (${formatter.format(financeVm.currentMonthExpense)} đ) đã VƯỢT QUÁ hạn mức ngân sách đặt ra (${formatter.format(financeVm.monthlyBudget!.limitAmt)} đ).\n\nHãy kiểm tra lại các khoản chi tiêu của mình nhé!',
            style: GoogleFonts.beVietnamPro(),
          ),
          actions: [
            TextButton(
              child: Text(
                'ĐÃ HIỂU',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                financeVm.dismissBudgetAlert();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showSetBudgetDialog() {
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
    final authVm = Provider.of<AuthViewModel>(context, listen: false);

    if (financeVm.monthlyBudget != null) {
      _budgetController.text = formatter.format(
        financeVm.monthlyBudget!.limitAmt,
      );
    } else {
      _budgetController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Thiết Lập Ngân Sách',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.beVietnamPro(color: Colors.white),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Hạn mức chi tiêu tháng (đ)',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryYellow),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'CẬP NHẬT',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final cleanText = _budgetController.text.replaceAll(
                  RegExp(r'[^\d]'),
                  '',
                );
                final limit = double.tryParse(cleanText) ?? 0.0;
                if (limit <= 0) return;

                final success = await financeVm.setMonthlyBudget(
                  limit,
                  authVm.currentUser!.uID,
                );
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);
    final authVm = Provider.of<AuthViewModel>(context);

    // If budget alert triggered dynamically while on dashboard, show it
    if (financeVm.shouldShowBudgetAlert) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBudgetAlert();
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Welcome Panel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        authVm.currentUser?.username ?? 'Khách',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Hero(
                  tag: 'app_logo_header',
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 36,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: () {
                        authVm.logout();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Balance Card (Glassmorphism layout)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              color: Colors.white.withOpacity(0.04),
              borderColor: Colors.white.withOpacity(0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SỐ DƯ TÀI KHOẢN CHÍNH',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatter.format(financeVm.mainBalance)} đ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryYellow,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceSummary(
                          label: 'THU NHẬP',
                          amount: financeVm.totalIncome,
                          icon: Icons.arrow_downward,
                          iconColor: AppTheme.successGreen,
                        ),
                      ),
                      Container(height: 35, width: 1, color: Colors.white10),
                      Expanded(
                        child: _buildBalanceSummary(
                          label: 'CHI TIÊU',
                          amount: financeVm.totalExpense,
                          icon: Icons.arrow_upward,
                          iconColor: AppTheme.alertRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick Action Shortcut Buttons (Loans, Interest Calculator, Export Report)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoansScreen()),
                      );
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      borderRadius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_outlined, color: AppTheme.primaryYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Vay & Nợ',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InterestCalculatorView()),
                      );
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      borderRadius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calculate_outlined, color: AppTheme.primaryYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Tính Lãi',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExportReportScreen()),
                      );
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      borderRadius: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download_outlined, color: AppTheme.primaryYellow, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Xuất File',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Monthly Budget Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: _buildBudgetCard(financeVm),
          ),

          // Recent Transactions Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Giao Dịch Gần Đây',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Kéo để xóa',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Transactions ListView
          financeVm.transactions.isEmpty
              ? Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có giao dịch nào được tạo.',
                        style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: financeVm.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = financeVm.transactions[index];

                    // Match category
                    final cat = financeVm.categories.firstWhere(
                      (c) => c.ctgID == tx.ctgID,
                      orElse: () => CategoryModel(
                        ctgID: '',
                        uID: '',
                        name: 'Không rõ',
                        type: 'Chi',
                        iconKey: 'payment',
                      ),
                    );

                    final isIncome = cat.type == 'Thu';

                    return Dismissible(
                      key: Key(tx.tsID),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.alertRed.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        financeVm.deleteTransaction(tx.tsID);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          color: const Color(0x08FFFFFF),
                          borderColor: Colors.white.withOpacity(0.04),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isIncome
                                    ? AppTheme.successGreen.withOpacity(0.1)
                                    : AppTheme.alertRed.withOpacity(0.1),
                                child: Icon(
                                  CategoryIcons.getIcon(cat.iconKey),
                                  color: isIncome
                                      ? AppTheme.successGreen
                                      : AppTheme.alertRed,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tx.note.isNotEmpty
                                          ? tx.note
                                          : 'Giao dịch',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'}${formatter.format(tx.amt)} đ',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isIncome
                                          ? AppTheme.successGreen
                                          : AppTheme.alertRed,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM').format(tx.tsDate),
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 16), // Bottom padding spacing
        ],
      ),
    );
  }

  Widget _buildBalanceSummary({
    required String label,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${formatter.format(amount)} đ',
              style: GoogleFonts.beVietnamPro(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetCard(FinanceViewModel financeVm) {
    final budget = financeVm.monthlyBudget;

    if (budget == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        color: const Color(0x06FFFFFF),
        borderColor: Colors.white.withOpacity(0.04),
        child: Column(
          children: [
            Text(
              'Bạn chưa thiết lập ngân sách tháng này.',
              style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            GlassCardButton(
              color: AppTheme.primaryYellow.withOpacity(0.1),
              borderColor: AppTheme.primaryYellow.withOpacity(0.2),
              onTap: _showSetBudgetDialog,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  'ĐẶT NGÂN SÁCH NGAY',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final expense = financeVm.currentMonthExpense;
    final limit = budget.limitAmt;
    final progress = financeVm.budgetProgress;
    final ratioStr =
        '${formatter.format(expense)} / ${formatter.format(limit)} đ';

    Color cardBorderColor = Colors.white.withOpacity(0.04);
    Color progressColor = AppTheme.primaryYellow;
    Widget? alertBadge;

    if (financeVm.isBudgetExceeded) {
      cardBorderColor = AppTheme.alertRed.withOpacity(0.4);
      progressColor = AppTheme.alertRed;
      alertBadge = _buildWarningBadge('QUÁ GIỚI HẠN', AppTheme.alertRed);
    } else if (financeVm.isBudgetApproaching) {
      cardBorderColor = Colors.amber.withOpacity(0.4);
      progressColor = Colors.amber;
      alertBadge = _buildWarningBadge('GẦN CHẠM NGƯỠNG (>=90%)', Colors.amber);
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: financeVm.isBudgetExceeded
          ? AppTheme.alertRed.withOpacity(0.02)
          : const Color(0x06FFFFFF),
      borderColor: cardBorderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NGÂN SÁCH THÁNG NÀY',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: _showSetBudgetDialog,
                child: const Icon(
                  Icons.edit,
                  color: AppTheme.primaryYellow,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ratioStr,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (alertBadge != null) alertBadge,
            ],
          ),
          const SizedBox(height: 12),
          // Animated Progress indicator
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, val, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val,
                  color: progressColor,
                  backgroundColor: Colors.grey[900],
                  minHeight: 6,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
