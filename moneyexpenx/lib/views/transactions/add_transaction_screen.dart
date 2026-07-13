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

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _amountStr = '0';
  CategoryModel? _selectedCategory;
  String _transactionType = 'Chi'; // 'Chi' or 'Thu'

  final formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _keypadPress(String value) {
    setState(() {
      if (value == 'C') {
        _amountStr = '0';
      } else if (value == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = value;
        } else {
          // Limit to max 12 digits (999 billions)
          if (_amountStr.length < 12) {
            _amountStr += value;
          }
        }
      }
    });
  }

  double get _amountDouble {
    return double.tryParse(_amountStr) ?? 0.0;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final double amt = _amountDouble;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn danh mục', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

    final success = await financeVm.addTransaction(
      uID: authVm.currentUser!.uID,
      ctgID: _selectedCategory!.ctgID,
      amt: amt,
      tsDate: _selectedDate,
      note: _noteController.text.trim(),
    );

    if (success && mounted) {
      // If adding a transaction causes budget overflow, check and notify.
      // The main screen will intercept budget warnings, but we also can show a temporary SnackBar warning
      if (_transactionType == 'Chi' && financeVm.isBudgetExceeded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cảnh báo: Bạn đã vượt quá hạn mức chi tiêu tháng này!',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.alertRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);
    final filteredCategories = _transactionType == 'Chi'
        ? financeVm.getExpenseCategories()
        : financeVm.getIncomeCategories();

    // Auto-select first category if not selected or mismatched type
    if (_selectedCategory == null || _selectedCategory!.type != _transactionType) {
      if (filteredCategories.isNotEmpty) {
        _selectedCategory = filteredCategories.first;
      } else {
        _selectedCategory = null;
      }
    }

    final formattedAmt = formatter.format(_amountDouble);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm Giao Dịch',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryYellow, size: 28),
            onPressed: _saveTransaction,
          )
        ],
      ),
      body: Column(
        children: [
          // Dynamic inputs area
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Segment type select
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTypeButton('Chi', 'Khoản Chi (Chi tiêu)'),
                      const SizedBox(width: 16),
                      _buildTypeButton('Thu', 'Khoản Thu (Thu nhập)'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Display Amount
                  Center(
                    child: Text(
                      '$formattedAmt đ',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryYellow,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Category Selector Title
                  Text(
                    'Chọn danh mục:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Categories Horizontal scroll
                  filteredCategories.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Không có danh mục ${_transactionType.toLowerCase()}.\nHãy tạo danh mục trước.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];
                              final isSelected = _selectedCategory?.ctgID == cat.ctgID;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? AppTheme.primaryYellow
                                              : AppTheme.cardBg,
                                          border: Border.all(
                                            color: isSelected ? AppTheme.primaryYellow : Colors.white10,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Icon(
                                          CategoryIcons.getIcon(cat.iconKey),
                                          color: isSelected ? Colors.black : Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cat.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isSelected ? AppTheme.primaryYellow : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 24),
                  // Date and Notes fields
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            borderRadius: 12,
                            color: const Color(0x0AFFFFFF),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primaryYellow, size: 18),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.note_alt_outlined, color: AppTheme.primaryYellow),
                      labelText: 'Ghi chú',
                      labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                      ),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Custom Big Keypad
          _buildNumericKeypad(),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label) {
    bool isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryYellow : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return GlassContainer(
      borderRadius: 0,
      width: double.infinity,
      color: Colors.black.withOpacity(0.4),
      borderColor: Colors.white.withOpacity(0.05),
      borderWidth: 1.5,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                final isSpecial = key == 'C' || key == '⌫';
                return SizedBox(
                  width: (screenWidth - 48) / 3,
                  height: 60,
                  child: GlassCardButton(
                    onTap: () => _keypadPress(key),
                    color: isSpecial ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.08),
                    borderColor: Colors.white.withOpacity(0.02),
                    borderRadius: 12,
                    child: Center(
                      child: Text(
                        key,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSpecial ? AppTheme.primaryYellow : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
