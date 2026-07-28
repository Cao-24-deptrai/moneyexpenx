import 'package:intl/intl.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/data/models/transaction_model.dart';
import 'package:moneyexpenx/data/models/saving_jar_model.dart';
import 'package:moneyexpenx/data/models/budget_model.dart';
import 'package:moneyexpenx/data/models/loan_model.dart';

class ExportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dayFormat = DateFormat('dd/MM/yyyy');

  /// Export financial report as a UTF-8 BOM CSV / Excel content string
  static String generateExcelCsv({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<SavingJarModel> jars,
    required List<LoanModel> loans,
    required BudgetModel? budget,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) {
    final StringBuffer csv = StringBuffer();

    // UTF-8 BOM header for Excel compatibility
    csv.write('\uFEFF');

    // Title
    csv.writeln('BÁO CÁO TÀI CHÍNH TỔNG QUAN MONEYEXPENX');
    csv.writeln('Ngày xuất báo cáo:;${_dateFormat.format(DateTime.now())}');
    csv.writeln();

    // 1. TỔNG QUAN TÀI CHÍNH
    csv.writeln('=== TỔNG QUAN TÀI CHÍNH ===');
    csv.writeln('Chỉ số;Số tiền (VND)');
    csv.writeln('Tổng Thu nhập;${totalIncome.toStringAsFixed(0)}');
    csv.writeln('Tổng Chi tiêu;${totalExpense.toStringAsFixed(0)}');
    csv.writeln('Số dư khả dụng;${netBalance.toStringAsFixed(0)}');
    if (budget != null) {
      csv.writeln('Hạn mức ngân sách tháng;${budget.limitAmt.toStringAsFixed(0)}');
    }
    csv.writeln();

    // 2. DANH SÁCH GIAO DỊCH
    csv.writeln('=== LỊCH SỬ GIAO DỊCH CHI TIẾT ===');
    csv.writeln('Mã Giao Dịch;Ngày;Loại;Danh Mục;Số Tiền (VND);Ghi Chú');

    for (var tx in transactions) {
      final category = categories.firstWhere(
        (c) => c.ctgID == tx.ctgID,
        orElse: () => CategoryModel(ctgID: '', uID: '', name: 'Khác', type: 'Chi', iconKey: 'help'),
      );
      final noteEscaped = '"${tx.note.replaceAll('"', '""')}"';
      csv.writeln('${tx.tsID};${_dateFormat.format(tx.tsDate)};${category.type};${category.name};${tx.amt.toStringAsFixed(0)};$noteEscaped');
    }
    csv.writeln();

    // 3. HŨ TIẾT KIỆM
    if (jars.isNotEmpty) {
      csv.writeln('=== HŨ TIẾT KIỆM ===');
      csv.writeln('Tên Hũ;Đã Tích Lũy (VND);Mục Tiêu (VND);Tiến Độ (%);Hạn Hoàn Thành;Trạng Thái');
      for (var jar in jars) {
        final progress = (jar.progressPercent * 100).toStringAsFixed(1);
        final statusText = jar.status == 'completed' ? 'Đã hoàn thành' : 'Đang tích lũy';
        csv.writeln('${jar.name};${jar.currentAmt.toStringAsFixed(0)};${jar.targetAmt.toStringAsFixed(0)};$progress%;${_dayFormat.format(jar.targetDate)};$statusText');
      }
      csv.writeln();
    }

    // 4. KHOẢN VAY VÀ NỢ
    if (loans.isNotEmpty) {
      csv.writeln('=== KHOẢN VAY VÀ NỢ ===');
      csv.writeln('Loại;Đối Tác;Số Tiền Gốc (VND);Đã Trả/Thu (VND);Còn Lại (VND);Lãi Suất (%/năm);Loại Lãi;Trạng Thái');
      for (var loan in loans) {
        final typeText = loan.type == 'loan' ? 'Cho vay' : 'Đi vay';
        final statusText = loan.status == 'paid' ? 'Đã hoàn tất' : 'Đang hoạt động';
        String interestTypeText = 'Lãi đơn';
        if (loan.interestType == 'compound') interestTypeText = 'Lãi kép';
        if (loan.interestType == 'reducing') interestTypeText = 'Dư nợ giảm dần';

        csv.writeln('$typeText;${loan.personName};${loan.principal.toStringAsFixed(0)};${loan.totalPaid.toStringAsFixed(0)};${loan.remainingPrincipal.toStringAsFixed(0)};${loan.interestRate}%;$interestTypeText;$statusText');
      }
    }

    return csv.toString();
  }

  /// Generate a nicely formatted printable text / PDF summary document string
  static String generatePrintableSummaryReport({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<SavingJarModel> jars,
    required List<LoanModel> loans,
    required BudgetModel? budget,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
  }) {
    final StringBuffer doc = StringBuffer();

    doc.writeln('====================================================');
    doc.writeln('        BÁO CÁO TÀI CHÍNH CÁ NHÂN MONEYEXPENX       ');
    doc.writeln('====================================================');
    doc.writeln('Thời gian xuất báo cáo: ${_dateFormat.format(DateTime.now())}');
    doc.writeln('Tổng số giao dịch: ${transactions.length}');
    doc.writeln('----------------------------------------------------');
    doc.writeln();

    doc.writeln('📌 1. TỔNG QUAN DÒNG TIỀN');
    doc.writeln('  • Tổng Thu nhập:   +${_currencyFormat.format(totalIncome)}');
    doc.writeln('  • Tổng Chi tiêu:   -${_currencyFormat.format(totalExpense)}');
    doc.writeln('  • Số dư dòng tiền:  ${_currencyFormat.format(netBalance)}');
    if (budget != null) {
      doc.writeln('  • Ngân sách tháng: ${_currencyFormat.format(budget.limitAmt)}');
    }
    doc.writeln();

    // Category breakdown
    doc.writeln('📌 2. THỐNG KÊ THEO DANH MỤC CHI TIÊU');
    final Map<String, double> categoryTotals = {};
    for (var tx in transactions) {
      final category = categories.firstWhere(
        (c) => c.ctgID == tx.ctgID,
        orElse: () => CategoryModel(ctgID: '', uID: '', name: 'Khác', type: 'Chi', iconKey: 'help'),
      );
      if (category.type == 'Chi') {
        categoryTotals[category.name] = (categoryTotals[category.name] ?? 0.0) + tx.amt;
      }
    }

    if (categoryTotals.isEmpty) {
      doc.writeln('  (Chưa có dữ liệu chi tiêu)');
    } else {
      categoryTotals.forEach((name, amount) {
        final percentage = totalExpense > 0 ? (amount / totalExpense * 100).toStringAsFixed(1) : '0';
        doc.writeln('  • $name: ${_currencyFormat.format(amount)} ($percentage%)');
      });
    }
    doc.writeln();

    // Jars summary
    if (jars.isNotEmpty) {
      doc.writeln('📌 3. HŨ TIẾT KIỆM TÍCH LŨY');
      for (var jar in jars) {
        final pct = (jar.progressPercent * 100).toStringAsFixed(1);
        doc.writeln('  • ${jar.name}: ${_currencyFormat.format(jar.currentAmt)} / ${_currencyFormat.format(jar.targetAmt)} ($pct%)');
      }
      doc.writeln();
    }

    // Loans summary
    if (loans.isNotEmpty) {
      doc.writeln('📌 4. KHOẢN VAY VÀ NỢ');
      for (var loan in loans) {
        final label = loan.type == 'loan' ? 'Cho vay' : 'Đi vay';
        doc.writeln('  • [$label] ${loan.personName}: Gốc ${_currencyFormat.format(loan.principal)} - Còn lại ${_currencyFormat.format(loan.remainingPrincipal)}');
      }
      doc.writeln();
    }

    doc.writeln('====================================================');
    doc.writeln('     Được xuất tự động bởi MoneyExpenx App          ');
    doc.writeln('====================================================');

    return doc.toString();
  }
}
