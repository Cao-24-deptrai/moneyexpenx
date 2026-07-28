import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/data/models/loan_model.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';
import 'package:moneyexpenx/views/loans/add_loan_screen.dart';
import 'package:moneyexpenx/views/loans/interest_calculator_view.dart';
import 'package:moneyexpenx/core/utils/thousands_formatter.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  int _filterIndex = 0; // 0 = All, 1 = Loans (Cho vay), 2 = Debts (Đi vay)
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  void _showAddRepaymentDialog(LoanModel loan) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loan.type == 'loan' ? 'Thu Tiền Vay từ ${loan.personName}' : 'Trả Tiền Nợ cho ${loan.personName}',
          style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              style: GoogleFonts.beVietnamPro(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Số tiền trả (VND)',
                labelStyle: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: GoogleFonts.beVietnamPro(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                labelStyle: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0.0;
              if (amount > 0) {
                final financeVm = Provider.of<FinanceViewModel>(context, listen: false);
                await financeVm.addRepaymentToLoan(loan.loanID, amount, note: noteController.text);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryYellow),
            child: Text('XÁC NHẬN', style: GoogleFonts.beVietnamPro(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeVm = Provider.of<FinanceViewModel>(context);

    List<LoanModel> filteredLoans = financeVm.loans;
    if (_filterIndex == 1) {
      filteredLoans = financeVm.loans.where((l) => l.type == 'loan').toList();
    } else if (_filterIndex == 2) {
      filteredLoans = financeVm.loans.where((l) => l.type == 'debt').toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản Lý Khoản Vay & Nợ',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined, color: AppTheme.primaryYellow),
            tooltip: 'Máy tính lãi suất',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InterestCalculatorView()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Summary Stats Card
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Tôi Cho Vay',
                                style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(financeVm.totalLoanedAmount),
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 36, width: 1, color: Colors.white10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.arrow_downward, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Tôi Đi Vay',
                                  style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(financeVm.totalBorrowedAmount),
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Filter Chips + Calculator Quick Button
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tất cả (${financeVm.loans.length})', 0),
                          const SizedBox(width: 8),
                          _buildFilterChip('Cho vay (${financeVm.activeLoans.length})', 1),
                          const SizedBox(width: 8),
                          _buildFilterChip('Đi vay (${financeVm.activeDebts.length})', 2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // List of loans
              Expanded(
                child: filteredLoans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có khoản vay hoặc nợ nào',
                              style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLoans.length,
                        itemBuilder: (context, index) {
                          final loan = filteredLoans[index];
                          final isLoan = loan.type == 'loan';
                          final isPaid = loan.status == 'paid';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(16),
                              borderColor: isPaid
                                  ? Colors.grey.withOpacity(0.2)
                                  : (isLoan ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isLoan ? Colors.green.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isLoan ? 'CHO VAY' : 'ĐI VAY',
                                              style: GoogleFonts.beVietnamPro(
                                                color: isLoan ? Colors.green : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            loan.personName,
                                            style: GoogleFonts.beVietnamPro(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                                        color: const Color(0xFF2B2B3D),
                                        onSelected: (val) async {
                                          if (val == 'toggle') {
                                            await financeVm.toggleLoanStatus(loan.loanID);
                                          } else if (val == 'delete') {
                                            await financeVm.deleteLoan(loan.loanID);
                                          }
                                        },
                                        itemBuilder: (ctx) => [
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(
                                              isPaid ? 'Đánh dấu Chưa Hoàn Tất' : 'Đánh dấu Đã Hoàn Tất',
                                              style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(
                                              'Xóa Khoản Vay',
                                              style: GoogleFonts.beVietnamPro(color: Colors.redAccent, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Gốc: ${_currencyFormat.format(loan.principal)}',
                                            style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 12),
                                          ),
                                          if (loan.interestRate > 0)
                                            Text(
                                              'Lãi: +${_currencyFormat.format(loan.interestAmount)}',
                                              style: GoogleFonts.beVietnamPro(color: Colors.redAccent.withOpacity(0.9), fontSize: 11),
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Còn lại phải trả',
                                            style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 10),
                                          ),
                                          Text(
                                            _currencyFormat.format(loan.remainingPayable),
                                            style: GoogleFonts.beVietnamPro(
                                              color: isPaid ? Colors.white60 : AppTheme.primaryYellow,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: loan.progressRatio,
                                      minHeight: 6,
                                      backgroundColor: Colors.white10,
                                      valueColor: AlwaysStoppedAnimation(isLoan ? Colors.green : Colors.redAccent),
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Start Date & Due Date Row
                                  Builder(builder: (context) {
                                    final dueDate = loan.dueDate ??
                                        DateTime(
                                          loan.startDate.year + ((loan.startDate.month + loan.months - 1) ~/ 12),
                                          ((loan.startDate.month + loan.months - 1) % 12) + 1,
                                          loan.startDate.day,
                                        );
                                    final isOverdue = !isPaid && DateTime.now().isAfter(dueDate);

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.event_outlined, size: 14, color: AppTheme.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Vay: ${_dateFormat.format(loan.startDate)}',
                                              style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.alarm,
                                              size: 14,
                                              color: isOverdue ? Colors.redAccent : AppTheme.primaryYellow,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Hạn trả: ${_dateFormat.format(dueDate)}',
                                              style: GoogleFonts.beVietnamPro(
                                                color: isOverdue ? Colors.redAccent : AppTheme.primaryYellow,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (isOverdue) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'QUÁ HẠN',
                                                  style: GoogleFonts.beVietnamPro(
                                                    color: Colors.redAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    );
                                  }),

                                  const SizedBox(height: 8),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Lãi: ${loan.interestRate}% (${loan.interestType}) | ${loan.months} tháng',
                                        style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                      if (!isPaid)
                                        GestureDetector(
                                          onTap: () => _showAddRepaymentDialog(loan),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryYellow.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.4)),
                                            ),
                                            child: Text(
                                              '+ Trả tiền bớt',
                                              style: GoogleFonts.beVietnamPro(
                                                color: AppTheme.primaryYellow,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddLoanScreen(initialType: 'loan')),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18, color: Colors.black),
                      label: Text(
                        'Cho Vay (+)',
                        style: GoogleFonts.beVietnamPro(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddLoanScreen(initialType: 'debt')),
                        );
                      },
                      icon: const Icon(Icons.remove, size: 18, color: Colors.white),
                      label: Text(
                        'Đi Vay (-)',
                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryYellow : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
