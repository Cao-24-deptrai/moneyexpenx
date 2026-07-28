import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/core/widgets/custom_numeric_keypad.dart';
import 'package:moneyexpenx/core/utils/interest_calculator.dart';

class InterestCalculatorView extends StatefulWidget {
  const InterestCalculatorView({Key? key}) : super(key: key);

  @override
  State<InterestCalculatorView> createState() => _InterestCalculatorViewState();
}

class _InterestCalculatorViewState extends State<InterestCalculatorView> {
  String _principalStr = '100000000'; // 100,000,000đ default
  final TextEditingController _rateController = TextEditingController(text: '10'); // 10% / year default
  final TextEditingController _monthsController = TextEditingController(text: '12'); // 12 months default

  String _selectedFormula = 'reducing'; // 'simple', 'compound', 'reducing'
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final NumberFormat _formatter = NumberFormat.decimalPattern('vi_VN');

  @override
  void dispose() {
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double principal = double.tryParse(_principalStr) ?? 0.0;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final int months = int.tryParse(_monthsController.text) ?? 1;
    final formattedPrincipal = _formatter.format(principal);

    double totalPayable = 0.0;
    double interestAmount = 0.0;
    double monthlyPayment = 0.0;
    List<ScheduleEntry> schedule = [];

    if (_selectedFormula == 'simple') {
      final res = InterestCalculator.calculateSimpleInterest(principal: principal, rateAnnual: rate, months: months);
      totalPayable = res.totalPayable;
      interestAmount = res.interestAmount;
      monthlyPayment = res.monthlyPayment;
    } else if (_selectedFormula == 'compound') {
      final res = InterestCalculator.calculateCompoundInterest(principal: principal, rateAnnual: rate, months: months);
      totalPayable = res.totalPayable;
      interestAmount = res.interestAmount;
      monthlyPayment = res.monthlyPayment;
    } else {
      final res = InterestCalculator.calculateReducingBalance(principal: principal, rateAnnual: rate, months: months);
      totalPayable = res.totalPayable;
      interestAmount = res.interestAmount;
      monthlyPayment = res.monthlyPayment;
      schedule = res.schedule;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Máy Tính Lãi Suất Ngân Hàng',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        '$formattedPrincipal đ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryYellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Inputs card
                    GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông số khoản vay',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 14),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _rateController,
                            label: 'Lãi suất (% / năm)',
                            icon: Icons.percent,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _monthsController,
                            label: 'Kỳ hạn (Số tháng)',
                            icon: Icons.calendar_month_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Formula Selector
                    Text(
                      'Phương thức tính lãi',
                      style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildFormulaChip('Dư nợ giảm dần', 'reducing'),
                        const SizedBox(width: 8),
                        _buildFormulaChip('Lãi đơn', 'simple'),
                        const SizedBox(width: 8),
                        _buildFormulaChip('Lãi kép', 'compound'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Results Cards
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                color: AppTheme.primaryYellow.withOpacity(0.08),
                borderColor: AppTheme.primaryYellow.withOpacity(0.3),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền phải trả (Gốc + Lãi)',
                          style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          _currencyFormat.format(totalPayable),
                          style: GoogleFonts.beVietnamPro(
                            color: AppTheme.primaryYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiền lãi phát sinh',
                          style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          _currencyFormat.format(interestAmount),
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trả trung bình/tháng',
                          style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          _currencyFormat.format(monthlyPayment),
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Monthly Schedule Table (for Reducing balance or general)
              if (schedule.isNotEmpty) ...[
                Text(
                  'Lịch trả nợ giảm dần từng tháng',
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: schedule.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final item = schedule[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                'T${item.month}',
                                style: GoogleFonts.beVietnamPro(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trả: ${_currencyFormat.format(item.payment)}',
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Gốc: ${_currencyFormat.format(item.principalPaid)} | Lãi: ${_currencyFormat.format(item.interestPaid)}',
                                    style: GoogleFonts.beVietnamPro(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Dư: ${_currencyFormat.format(item.closingBalance)}',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
          CustomNumericKeypad(
            buttonHeight: 46,
            fontSize: 20,
            onKeyPress: (key) {
              setState(() {
                _principalStr = handleNumericKeypadInput(key, _principalStr);
              });
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: AppTheme.primaryYellow, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 1),
        ),
      ),
    );
  }

  Widget _buildFormulaChip(String label, String value) {
    final isSelected = _selectedFormula == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFormula = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryYellow : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.beVietnamPro(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
