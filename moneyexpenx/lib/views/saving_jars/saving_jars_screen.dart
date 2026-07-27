import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/data/models/saving_jar_model.dart';
import 'package:moneyexpenx/data/models/user_model.dart';
import 'package:moneyexpenx/data/services/firebase_service.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/core/utils/thousands_formatter.dart';

class SavingJarsScreen extends StatefulWidget {
  const SavingJarsScreen({Key? key}) : super(key: key);

  @override
  State<SavingJarsScreen> createState() => _SavingJarsScreenState();
}

class _SavingJarsScreenState extends State<SavingJarsScreen> {
  final _nameController = TextEditingController();
  final _targetAmtController = TextEditingController();
  final _depositController = TextEditingController();
  final _withdrawController = TextEditingController();
  DateTime _selectedTargetDate = DateTime.now().add(const Duration(days: 30));

  final formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmtController.dispose();
    _depositController.dispose();
    _withdrawController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ), // up to 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryYellow,
              onPrimary: Colors.black,
              surface: AppTheme.cardBg,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setModalState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  void _showAddJarSheet() {
    _selectedTargetDate = DateTime.now().add(const Duration(days: 30));
    _nameController.clear();
    _targetAmtController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassContainer(
                borderRadius: 24,
                color: Colors.black.withOpacity(0.85),
                borderColor: AppTheme.primaryYellow.withOpacity(0.3),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thêm Hũ Tiết Kiệm',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.beVietnamPro(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tên hũ mục tiêu',
                        labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetAmtController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.beVietnamPro(color: Colors.white),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Số tiền mục tiêu (đ)',
                        labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Target date picker
                    GestureDetector(
                      onTap: () => _selectTargetDate(context, setModalState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[800]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngày hoàn thành mục tiêu:',
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedTargetDate),
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primaryYellow,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassCardButton(
                      color: AppTheme.primaryYellow,
                      onTap: () async {
                        final name = _nameController.text.trim();
                        final cleanText = _targetAmtController.text.replaceAll(
                          RegExp(r'[^\d]'),
                          '',
                        );
                        final targetAmt = double.tryParse(cleanText) ?? 0.0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Vui lòng nhập tên hũ mục tiêu',
                                style: GoogleFonts.beVietnamPro(color: Colors.white),
                              ),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                          return;
                        }

                        if (targetAmt < 1000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Số tiền mục tiêu tối thiểu phải là 1.000 đ',
                                style: GoogleFonts.beVietnamPro(color: Colors.white),
                              ),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                          return;
                        }

                        final authVm = Provider.of<AuthViewModel>(
                          context,
                          listen: false,
                        );
                        final financeVm = Provider.of<FinanceViewModel>(
                          context,
                          listen: false,
                        );

                        final success = await financeVm.addSavingJar(
                          uID: authVm.currentUser!.uID,
                          name: name,
                          targetAmt: targetAmt,
                          targetDate: _selectedTargetDate,
                        );

                        if (success) {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'TẠO HŨ TIẾT KIỆM',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDepositDialog(SavingJarModel jar) {
    _depositController.clear();
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Nạp Tiền Vào Hũ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Số dư khả dụng: ${formatter.format(financeVm.mainBalance)} đ',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _depositController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.beVietnamPro(color: Colors.white),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Số tiền nạp (đ)',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryYellow),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'NẠP',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final cleanText = _depositController.text.replaceAll(
                  RegExp(r'[^\d]'),
                  '',
                );
                final amt = double.tryParse(cleanText) ?? 0.0;
                if (amt <= 0) return;

                if (amt > financeVm.mainBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Số dư chính không đủ để nạp!',
                        style: GoogleFonts.beVietnamPro(color: Colors.white),
                      ),
                      backgroundColor: AppTheme.alertRed,
                    ),
                  );
                  return;
                }

                final success = await financeVm.depositToJar(jar.jarID, amt);
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

  void _showWithdrawDialog(SavingJarModel jar) {
    _withdrawController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rút Tiền Khỏi Hũ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Đang có trong hũ: ${formatter.format(jar.currentAmt)} đ',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _withdrawController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.beVietnamPro(color: Colors.white),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Số tiền rút (đ)',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryYellow),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'RÚT',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final cleanText = _withdrawController.text.replaceAll(
                  RegExp(r'[^\d]'),
                  '',
                );
                final amt = double.tryParse(cleanText) ?? 0.0;
                if (amt <= 0) return;

                if (amt > jar.currentAmt) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Số tiền trong hũ không đủ!',
                        style: GoogleFonts.beVietnamPro(color: Colors.white),
                      ),
                      backgroundColor: AppTheme.alertRed,
                    ),
                  );
                  return;
                }

                final financeVm = Provider.of<FinanceViewModel>(
                  context,
                  listen: false,
                );
                final success = await financeVm.withdrawFromJar(jar.jarID, amt);
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

  void _confirmDeleteJar(SavingJarModel jar) {
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

    if (jar.currentAmt > 0) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.alertRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cảnh Báo Xóa Hũ',
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Hũ "${jar.name}" hiện đang tích lũy số tiền: ${formatter.format(jar.currentAmt)} đ.\n\nNếu xóa, toàn bộ số tiền này sẽ được HOÀN TRẢ lại vào Tài khoản chính của bạn.\n\nBạn có chắc chắn muốn xóa hũ tiết kiệm này?',
              style: GoogleFonts.beVietnamPro(fontSize: 14),
            ),
            actions: [
              TextButton(
                child: Text(
                  'HỦY',
                  style: GoogleFonts.beVietnamPro(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  'XÓA & HOÀN TIỀN',
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.alertRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  financeVm.deleteSavingJar(jar.jarID);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Xóa Hũ Tiết Kiệm',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
            ),
            content: Text('Bạn có chắc chắn muốn xóa hũ "${jar.name}" không?'),
            actions: [
              TextButton(
                child: Text(
                  'HỦY',
                  style: GoogleFonts.beVietnamPro(color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text(
                  'XÓA',
                  style: GoogleFonts.beVietnamPro(color: AppTheme.alertRed),
                ),
                onPressed: () {
                  financeVm.deleteSavingJar(jar.jarID);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showShareJarDialog(SavingJarModel jar) {
    final emailController = TextEditingController();
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Chia sẻ Hũ Tiết Kiệm',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nhập email của người bạn muốn chia sẻ hũ này cùng. Họ sẽ có quyền truy cập, nạp và rút tiền từ hũ.',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.beVietnamPro(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email người dùng',
                  hintText: 'vi_du@email.com',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryYellow),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'CHIA SẺ',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.primaryYellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;

                final error = await financeVm.addMemberToJarByEmail(
                  jar.jarID,
                  email,
                );
                if (error != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error,
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.alertRed,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã chia sẻ hũ tiết kiệm thành công!',
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                    Navigator.pop(context);
                  }
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
    final jars = financeVm.savingJars;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hũ Tiết Kiệm (Savings Jars)',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryYellow,
              size: 28,
            ),
            onPressed: _showAddJarSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Savings Summary Panel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              color: AppTheme.primaryYellow.withOpacity(0.05),
              borderColor: AppTheme.primaryYellow.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng tích lũy hiện tại:',
                        style: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatter.format(financeVm.jarsAllocated)} đ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.savings_outlined,
                    color: AppTheme.primaryYellow.withOpacity(0.8),
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: jars.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_outlined,
                          size: 64,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bạn chưa tạo hũ tiết kiệm nào.',
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showAddJarSheet,
                          child: Text(
                            'Tạo hũ tiết kiệm đầu tiên',
                            style: GoogleFonts.beVietnamPro(
                              color: AppTheme.primaryYellow,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: jars.length,
                    itemBuilder: (context, index) {
                      final jar = jars[index];
                      final progress = jar.progressPercent;
                      final percentText =
                          '${(progress * 100).toStringAsFixed(0)}%';
                      final isCompleted =
                          jar.status == 'completed' ||
                          jar.currentAmt >= jar.targetAmt;

                      return GestureDetector(
                        onTap: () => _showJarDetailsSheet(jar),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(18),
                            color: const Color(0x0CFFFFFF),
                            borderColor: Colors.white.withOpacity(0.05),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (jar.uID !=
                                              authVm.currentUser?.uID) ...[
                                            Container(
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.blue
                                                      .withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'Được chia sẻ',
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 10,
                                                  color: Colors.blue[300],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          Expanded(
                                            child: Text(
                                              jar.name,
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (jar.uID == authVm.currentUser?.uID) ...[
                                      IconButton(
                                        icon: const Icon(
                                          Icons.person_add_alt_1_outlined,
                                          color: AppTheme.primaryYellow,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _showShareJarDialog(jar),
                                        tooltip: 'Chia sẻ hũ',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () => _confirmDeleteJar(jar),
                                        tooltip: 'Xóa hũ',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Mục tiêu: ${formatter.format(jar.targetAmt)} đ',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Hạn: ${DateFormat('dd/MM/yyyy').format(jar.targetDate)}',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Amount values
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${formatter.format(jar.currentAmt)} đ',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? AppTheme.successGreen
                                            : AppTheme.primaryYellow,
                                      ),
                                    ),
                                    Text(
                                      percentText,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? AppTheme.successGreen
                                            : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Smooth Progress Bar Animation
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: progress,
                                  ),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, val, child) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: val,
                                        backgroundColor: Colors.grey[900],
                                        color: isCompleted
                                            ? AppTheme.successGreen
                                            : AppTheme.primaryYellow,
                                        minHeight: 8,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Action buttons (Glassmorphism layout)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    GlassCardButton(
                                      color: Colors.transparent,
                                      borderColor: Colors.white10,
                                      onTap: () => _showWithdrawDialog(jar),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'RÚT TIỀN',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GlassCardButton(
                                      color: AppTheme.primaryYellow.withOpacity(
                                        0.1,
                                      ),
                                      borderColor: AppTheme.primaryYellow
                                          .withOpacity(0.2),
                                      onTap: () => _showDepositDialog(jar),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'NẠP THÊM',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryYellow,
                                          ),
                                        ),
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
          ),
        ],
      ),
    );
  }

  void _showJarDetailsSheet(SavingJarModel jar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final financeVm = Provider.of<FinanceViewModel>(context);
            final authVm = Provider.of<AuthViewModel>(context);
            final currentJar = financeVm.savingJars.firstWhere(
              (j) => j.jarID == jar.jarID,
              orElse: () => jar,
            );
            final isOwner = currentJar.uID == authVm.currentUser?.uID;
            final otherMembers = currentJar.members
                .where((m) => m != currentJar.uID)
                .toList();
            final progress = currentJar.progressPercent;
            final isCompleted =
                currentJar.status == 'completed' ||
                currentJar.currentAmt >= currentJar.targetAmt;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassContainer(
                borderRadius: 24,
                color: Colors.black.withOpacity(0.9),
                borderColor: AppTheme.primaryYellow.withOpacity(0.3),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentJar.name,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryYellow,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tích lũy: ${formatter.format(currentJar.currentAmt)} đ / ${formatter.format(currentJar.targetAmt)} đ (${(progress * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[900],
                        color: isCompleted
                            ? AppTheme.successGreen
                            : AppTheme.primaryYellow,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hạn mục tiêu: ${DateFormat('dd/MM/yyyy').format(currentJar.targetDate)}',
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          currentJar.targetDate
                                      .difference(DateTime.now())
                                      .inDays >=
                                  0
                              ? 'Còn lại: ${currentJar.targetDate.difference(DateTime.now()).inDays} ngày'
                              : 'Đã quá hạn mục tiêu',
                          style: GoogleFonts.beVietnamPro(
                            color:
                                currentJar.targetDate
                                        .difference(DateTime.now())
                                        .inDays >=
                                    0
                                ? AppTheme.primaryYellow
                                : AppTheme.alertRed,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Text(
                      'Thành Viên Trong Hũ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    UserDisplayWidget(uID: currentJar.uID, role: 'Chủ sở hữu'),
                    if (otherMembers.isNotEmpty) ...[
                      ...otherMembers.map(
                        (mUid) => UserDisplayWidget(
                          uID: mUid,
                          role: 'Thành viên',
                          showRemoveButton: isOwner,
                          onRemove: () {
                            _confirmRemoveMember(
                              currentJar,
                              mUid,
                              setModalState,
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Chưa chia sẻ cho ai (Quỹ cá nhân)',
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (isOwner) ...[
                          Expanded(
                            child: GlassCardButton(
                              color: AppTheme.primaryYellow.withOpacity(0.1),
                              borderColor: AppTheme.primaryYellow.withOpacity(
                                0.3,
                              ),
                              onTap: () {
                                _showEditJarSheet(currentJar, setModalState);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      color: AppTheme.primaryYellow,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sửa hũ',
                                      style: GoogleFonts.beVietnamPro(
                                        color: AppTheme.primaryYellow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCardButton(
                              color: Colors.white.withOpacity(0.05),
                              borderColor: Colors.white.withOpacity(0.1),
                              onTap: () {
                                _showShareJarDialog(currentJar);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Chia sẻ',
                                      style: GoogleFonts.beVietnamPro(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: GlassCardButton(
                              color: AppTheme.alertRed.withOpacity(0.1),
                              borderColor: AppTheme.alertRed.withOpacity(0.3),
                              onTap: () {
                                _confirmLeaveJar(currentJar);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.exit_to_app,
                                      color: AppTheme.alertRed,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Rời khỏi hũ',
                                      style: GoogleFonts.beVietnamPro(
                                        color: AppTheme.alertRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditJarSheet(SavingJarModel jar, StateSetter parentSetState) {
    _nameController.text = jar.name;
    _targetAmtController.text = formatter.format(jar.targetAmt);
    _selectedTargetDate = jar.targetDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GlassContainer(
                borderRadius: 24,
                color: Colors.black.withOpacity(0.95),
                borderColor: AppTheme.primaryYellow.withOpacity(0.3),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sửa Hũ Tiết Kiệm',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryYellow,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.beVietnamPro(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tên hũ mục tiêu',
                        labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetAmtController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.beVietnamPro(color: Colors.white),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Số tiền mục tiêu (đ)',
                        labelStyle: GoogleFonts.beVietnamPro(
                          color: AppTheme.textSecondary,
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primaryYellow),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _selectTargetDate(context, setModalState),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[800]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngày hoàn thành mục tiêu:',
                              style: GoogleFonts.beVietnamPro(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_selectedTargetDate),
                                  style: GoogleFonts.beVietnamPro(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.primaryYellow,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    GlassCardButton(
                      color: AppTheme.primaryYellow,
                      onTap: () async {
                        final name = _nameController.text.trim();
                        final cleanText = _targetAmtController.text.replaceAll(
                          RegExp(r'[^\d]'),
                          '',
                        );
                        final targetAmt = double.tryParse(cleanText) ?? 0.0;

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Vui lòng nhập tên hũ mục tiêu',
                                style: GoogleFonts.beVietnamPro(color: Colors.white),
                              ),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                          return;
                        }

                        if (targetAmt < 1000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Số tiền mục tiêu tối thiểu phải là 1.000 đ',
                                style: GoogleFonts.beVietnamPro(color: Colors.white),
                              ),
                              backgroundColor: AppTheme.alertRed,
                            ),
                          );
                          return;
                        }

                        final financeVm = Provider.of<FinanceViewModel>(
                          context,
                          listen: false,
                        );
                        final success = await financeVm.updateSavingJar(
                          jarID: jar.jarID,
                          name: name,
                          targetAmt: targetAmt,
                          targetDate: _selectedTargetDate,
                        );

                        if (success && mounted) {
                          Navigator.pop(context);
                          parentSetState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cập nhật hũ tiết kiệm thành công!',
                                style: GoogleFonts.beVietnamPro(color: Colors.white),
                              ),
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'LƯU THAY ĐỔI',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRemoveMember(
    SavingJarModel jar,
    String memberUid,
    StateSetter parentSetState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Xóa Thành Viên',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa thành viên này khỏi hũ tiết kiệm?',
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'XÓA',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.alertRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final financeVm = Provider.of<FinanceViewModel>(
                  context,
                  listen: false,
                );
                final error = await financeVm.removeMemberFromJar(
                  jar.jarID,
                  memberUid,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error,
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.alertRed,
                      ),
                    );
                  } else {
                    parentSetState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã xóa thành viên khỏi hũ thành công!',
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveJar(SavingJarModel jar) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rời Khỏi Hũ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Bạn có chắc chắn muốn rời khỏi hũ tiết kiệm "${jar.name}" không?',
          ),
          actions: [
            TextButton(
              child: Text('HỦY', style: GoogleFonts.beVietnamPro(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'RỜI HŨ',
                style: GoogleFonts.beVietnamPro(
                  color: AppTheme.alertRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                final financeVm = Provider.of<FinanceViewModel>(
                  context,
                  listen: false,
                );
                final authVm = Provider.of<AuthViewModel>(
                  context,
                  listen: false,
                );
                final error = await financeVm.leaveJar(
                  jar.jarID,
                  authVm.currentUser!.uID,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error,
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.alertRed,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Bạn đã rời khỏi hũ tiết kiệm thành công!',
                          style: GoogleFonts.beVietnamPro(color: Colors.white),
                        ),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class UserDisplayWidget extends StatelessWidget {
  final String uID;
  final String role;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const UserDisplayWidget({
    Key? key,
    required this.uID,
    required this.role,
    this.showRemoveButton = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: FirebaseService.instance.getUserByID(uID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.05),
              child: const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryYellow,
                ),
              ),
            ),
            title: Text(
              'Đang tải...',
              style: GoogleFonts.beVietnamPro(color: Colors.white38, fontSize: 14),
            ),
          );
        }
        final user = snapshot.data;
        final String name = user?.username ?? 'Người dùng';
        final String email = user?.email ?? '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: role == 'Chủ sở hữu'
                ? AppTheme.primaryYellow.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            child: Icon(
              role == 'Chủ sở hữu' ? Icons.star : Icons.person,
              color: role == 'Chủ sở hữu'
                  ? AppTheme.primaryYellow
                  : Colors.white70,
              size: 20,
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: email.isNotEmpty
              ? Text(
                  email,
                  style: GoogleFonts.beVietnamPro(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: role == 'Chủ sở hữu'
                      ? AppTheme.primaryYellow.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: role == 'Chủ sở hữu'
                        ? AppTheme.primaryYellow
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showRemoveButton && onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.alertRed,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Xóa khỏi hũ',
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
