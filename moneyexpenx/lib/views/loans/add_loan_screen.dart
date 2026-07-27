import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:moneyexpenx/core/theme/app_theme.dart';
import 'package:moneyexpenx/core/widgets/glass_container.dart';
import 'package:moneyexpenx/viewmodels/auth_viewmodel.dart';
import 'package:moneyexpenx/viewmodels/finance_viewmodel.dart';

class AddLoanScreen extends StatefulWidget {
  final String initialType; // 'loan' or 'debt'
  const AddLoanScreen({Key? key, this.initialType = 'loan'}) : super(key: key);

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  late String _type; // 'loan' (Cho vay) or 'debt' (Đi vay)
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _principalController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController(text: '0');
  final TextEditingController _monthsController = TextEditingController(text: '12');
  final TextEditingController _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  String _interestType = 'simple'; // 'simple', 'compound', 'reducing'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _personNameController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _monthsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final financeVm = Provider.of<FinanceViewModel>(context, listen: false);

    final personName = _personNameController.text.trim();
    final principal = double.tryParse(_principalController.text.replaceAll(',', '').replaceAll('.', '')) ?? 0.0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;
    final months = int.tryParse(_monthsController.text) ?? 1;

    if (personName.isEmpty) {
      _showError('Vui lòng nhập tên đối tác / người vay!');
      return;
    }
    if (principal <= 0) {
      _showError('Số tiền phải lớn hơn 0!');
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await financeVm.addLoan(
      uID: authVm.currentUser!.uID,
      type: _type,
      personName: personName,
      principal: principal,
      interestRate: interestRate,
      interestType: _interestType,
      months: months,
      startDate: _startDate,
      notes: _notesController.text,
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      _showError('Không thể lưu khoản vay. Vui lòng thử lại!');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _type == 'loan' ? 'Thêm Khoản Cho Vay (+)' : 'Thêm Khoản Đi Vay (-)',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector (Cho vay vs Đi vay)
              GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'loan'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == 'loan' ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tôi Cho Vay (+)',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'debt'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _type == 'debt' ? Colors.redAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tôi Đi Vay (-)',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Inputs Card
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _personNameController,
                      label: _type == 'loan' ? 'Tên người vay' : 'Tên chủ nợ / Ngân hàng',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _principalController,
                      label: 'Số tiền gốc (VND)',
                      icon: Icons.monetization_on_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _interestRateController,
                            label: 'Lãi suất (% / năm)',
                            icon: Icons.percent,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _monthsController,
                            label: 'Thời hạn (Tháng)',
                            icon: Icons.calendar_month,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Interest Type Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loại lãi suất',
                          style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildTypeChip('Lãi đơn', 'simple'),
                            const SizedBox(width: 8),
                            _buildTypeChip('Lãi kép', 'compound'),
                            const SizedBox(width: 8),
                            _buildTypeChip('Dư nợ giảm dần', 'reducing'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Date Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.date_range, color: AppTheme.primaryYellow, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Ngày bắt đầu:',
                                  style: GoogleFonts.beVietnamPro(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_startDate),
                              style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Ghi chú (không bắt buộc)',
                      icon: Icons.note_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'LƯU KHOẢN VAY',
                          style: GoogleFonts.beVietnamPro(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _interestType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _interestType = value),
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
