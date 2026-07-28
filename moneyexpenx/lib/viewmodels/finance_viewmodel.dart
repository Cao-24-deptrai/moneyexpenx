import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneyexpenx/data/models/category_model.dart';
import 'package:moneyexpenx/data/models/transaction_model.dart';
import 'package:moneyexpenx/data/models/saving_jar_model.dart';
import 'package:moneyexpenx/data/models/budget_model.dart';
import 'package:moneyexpenx/data/models/loan_model.dart';
import 'package:moneyexpenx/data/services/firebase_service.dart';
import 'package:moneyexpenx/data/services/export_service.dart';

class FinanceViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  List<SavingJarModel> _savingJars = [];
  List<LoanModel> _loans = [];
  BudgetModel? _monthlyBudget;
  bool _isLoading = false;

  // Warning thresholds
  bool _hasBudgetAlertBeenShownThisSession = false;

  List<CategoryModel> get categories => _categories;
  List<TransactionModel> get transactions => _transactions;
  List<SavingJarModel> get savingJars => _savingJars;
  List<LoanModel> get loans => _loans;
  List<LoanModel> get activeLoans => _loans.where((l) => l.type == 'loan' && l.status == 'active').toList();
  List<LoanModel> get activeDebts => _loans.where((l) => l.type == 'debt' && l.status == 'active').toList();

  double get totalLoanedAmount => activeLoans.fold(0.0, (sum, l) => sum + l.remainingPayable);
  double get totalBorrowedAmount => activeDebts.fold(0.0, (sum, l) => sum + l.remainingPayable);

  BudgetModel? get monthlyBudget => _monthlyBudget;
  bool get isLoading => _isLoading;

  // Get current active categories by type
  List<CategoryModel> getIncomeCategories() => _categories.where((c) => c.type == 'Thu').toList();
  List<CategoryModel> getExpenseCategories() => _categories.where((c) => c.type == 'Chi').toList();

  // Financial calculations
  double get totalIncome {
    return _transactions
        .where((t) {
          final cat = _findCategory(t.ctgID);
          return cat != null && cat.type == 'Thu';
        })
        .fold(0.0, (sum, t) => sum + t.amt);
  }

  double get totalExpense {
    return _transactions
        .where((t) {
          final cat = _findCategory(t.ctgID);
          return cat != null && cat.type == 'Chi';
        })
        .fold(0.0, (sum, t) => sum + t.amt);
  }

  double get jarsAllocated {
    return _savingJars.fold(0.0, (sum, jar) => sum + jar.currentAmt);
  }

  // Total Net Borrowed Cash (Đi vay - nhận tiền về làm TĂNG số dư)
  double get netBorrowedCash {
    return _loans
        .where((l) => l.type == 'debt')
        .fold(0.0, (sum, l) => sum + (l.principal - l.totalPaid));
  }

  // Total Net Loaned Out Cash (Cho vay - bỏ tiền ra làm GIẢM số dư)
  double get netLoanedOutCash {
    return _loans
        .where((l) => l.type == 'loan')
        .fold(0.0, (sum, l) => sum + (l.principal - l.totalPaid));
  }

  // Main balance = Incomes - Expenses - Money in Jars + Net Borrowed Cash - Net Loaned Out Cash
  double get mainBalance {
    return totalIncome - totalExpense - jarsAllocated + netBorrowedCash - netLoanedOutCash;
  }

  // Monthly expense (for current month budget tracking)
  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          final cat = _findCategory(t.ctgID);
          return cat != null &&
              cat.type == 'Chi' &&
              t.tsDate.year == now.year &&
              t.tsDate.month == now.month;
        })
        .fold(0.0, (sum, t) => sum + t.amt);
  }

  // Budget status
  bool get isBudgetExceeded {
    if (_monthlyBudget == null || _monthlyBudget!.limitAmt <= 0) return false;
    return currentMonthExpense > _monthlyBudget!.limitAmt;
  }

  bool get isBudgetApproaching {
    if (_monthlyBudget == null || _monthlyBudget!.limitAmt <= 0) return false;
    final ratio = currentMonthExpense / _monthlyBudget!.limitAmt;
    return ratio >= 0.9 && ratio <= 1.0;
  }

  double get budgetProgress {
    if (_monthlyBudget == null || _monthlyBudget!.limitAmt <= 0) return 0.0;
    final ratio = currentMonthExpense / _monthlyBudget!.limitAmt;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  // Alert check
  bool get shouldShowBudgetAlert {
    if (isBudgetExceeded && !_hasBudgetAlertBeenShownThisSession) {
      return true;
    }
    return false;
  }

  void dismissBudgetAlert() {
    _hasBudgetAlertBeenShownThisSession = true;
    notifyListeners();
  }

  CategoryModel? _findCategory(String ctgID) {
    try {
      return _categories.firstWhere((c) => c.ctgID == ctgID);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // CORE LOADER
  // ==========================================

  Future<void> loadData(String uID) async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _firebaseService.getCategories(uID);
      _transactions = await _firebaseService.getTransactions(uID);
      _savingJars = await _firebaseService.getSavingJars(uID);
      _loans = await _firebaseService.getLoans(uID);
      _monthlyBudget = await _firebaseService.getBudget(uID, DateTime.now());
    } catch (e) {
      debugPrint("Error loading finance data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==========================================
  // CATEGORIES CRUD
  // ==========================================

  Future<String?> addCategory({
    required String name,
    required String type,
    required String iconKey,
    required String uID,
  }) async {
    // 1. Check duplicate category name within the same type
    final isDuplicate = _categories.any(
      (c) => c.type == type && c.name.trim().toLowerCase() == name.trim().toLowerCase(),
    );

    if (isDuplicate) {
      return "Tên danh mục '$name' đã tồn tại trong nhóm này!";
    }

    try {
      final newCat = CategoryModel(
        ctgID: '',
        uID: uID,
        name: name.trim(),
        type: type,
        iconKey: iconKey,
      );

      final savedCat = await _firebaseService.addCategory(newCat);
      _categories.add(savedCat);
      notifyListeners();
      return null; // Success
    } catch (e) {
      return "Lỗi thêm danh mục: ${e.toString()}";
    }
  }

  Future<void> deleteCategory(String ctgID) async {
    try {
      await _firebaseService.deleteCategory(ctgID);
      _categories.removeWhere((c) => c.ctgID == ctgID);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting category: $e");
    }
  }

  // ==========================================
  // TRANSACTIONS CRUD
  // ==========================================

  Future<bool> addTransaction({
    required String uID,
    required String ctgID,
    required double amt,
    required DateTime tsDate,
    required String note,
  }) async {
    try {
      final newTx = TransactionModel(
        tsID: '',
        uID: uID,
        ctgID: ctgID,
        amt: amt,
        tsDate: tsDate,
        note: note,
      );

      final savedTx = await _firebaseService.addTransaction(newTx);
      _transactions.insert(0, savedTx); // Show latest at top
      
      // If budget has just been exceeded, reset the session alert trigger so the popup can show
      if (isBudgetExceeded) {
        // Reset so user gets warned on dashboard
        _hasBudgetAlertBeenShownThisSession = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error adding transaction: $e");
      return false;
    }
  }

  Future<void> deleteTransaction(String tsID) async {
    try {
      await _firebaseService.deleteTransaction(tsID);
      _transactions.removeWhere((t) => t.tsID == tsID);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  // ==========================================
  // SAVING JARS CRUD & OPERATIONS
  // ==========================================

  Future<bool> addSavingJar({
    required String uID,
    required String name,
    required double targetAmt,
    required DateTime targetDate,
  }) async {
    try {
      final newJar = SavingJarModel(
        jarID: '',
        uID: uID,
        name: name.trim(),
        targetAmt: targetAmt,
        currentAmt: 0,
        targetDate: targetDate,
        status: 'active',
        members: [uID],
      );

      final savedJar = await _firebaseService.addSavingJar(newJar);
      _savingJars.add(savedJar);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error adding saving jar: $e");
      return false;
    }
  }

  Future<String?> addMemberToJarByEmail(String jarID, String email) async {
    try {
      // 1. Look up user by email
      final user = await _firebaseService.getUserByEmail(email);
      if (user == null) {
        return "Tài khoản với email này không tồn tại trên hệ thống.";
      }

      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex == -1) {
        return "Hũ tiết kiệm không tồn tại.";
      }

      final jar = _savingJars[jarIndex];

      // 2. Check if the user is already a member
      if (jar.members.contains(user.uID)) {
        return "Người dùng này đã tham gia hũ tiết kiệm này rồi.";
      }

      // 3. Add user to members list and update
      final updatedMembers = List<String>.from(jar.members)..add(user.uID);
      final updatedJar = jar.copyWith(members: updatedMembers);

      await _firebaseService.updateSavingJar(updatedJar);
      _savingJars[jarIndex] = updatedJar;
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint("Error sharing jar: $e");
      return "Đã xảy ra lỗi khi thêm thành viên: ${e.toString()}";
    }
  }

  Future<bool> updateSavingJar({
    required String jarID,
    required String name,
    required double targetAmt,
    required DateTime targetDate,
  }) async {
    try {
      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex != -1) {
        final jar = _savingJars[jarIndex];
        final isCompleted = jar.currentAmt >= targetAmt;
        final updatedJar = jar.copyWith(
          name: name.trim(),
          targetAmt: targetAmt,
          targetDate: targetDate,
          status: isCompleted ? 'completed' : 'active',
        );

        await _firebaseService.updateSavingJar(updatedJar);
        _savingJars[jarIndex] = updatedJar;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error updating saving jar: $e");
    }
    return false;
  }

  Future<String?> removeMemberFromJar(String jarID, String memberUID) async {
    try {
      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex == -1) {
        return "Hũ tiết kiệm không tồn tại.";
      }

      final jar = _savingJars[jarIndex];
      if (!jar.members.contains(memberUID)) {
        return "Thành viên này không có trong hũ.";
      }

      final updatedMembers = List<String>.from(jar.members)..remove(memberUID);
      final updatedJar = jar.copyWith(members: updatedMembers);

      await _firebaseService.updateSavingJar(updatedJar);
      _savingJars[jarIndex] = updatedJar;
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint("Error removing member from jar: $e");
      return "Lỗi khi xóa thành viên: ${e.toString()}";
    }
  }

  Future<String?> leaveJar(String jarID, String userUID) async {
    try {
      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex == -1) {
        return "Hũ tiết kiệm không tồn tại.";
      }

      final jar = _savingJars[jarIndex];
      if (jar.uID == userUID) {
        return "Chủ sở hữu không thể tự rời khỏi hũ (chỉ có thể xóa hũ).";
      }

      if (!jar.members.contains(userUID)) {
        return "Bạn không tham gia hũ này.";
      }

      final updatedMembers = List<String>.from(jar.members)..remove(userUID);
      final updatedJar = jar.copyWith(members: updatedMembers);

      await _firebaseService.updateSavingJar(updatedJar);
      _savingJars.removeAt(jarIndex);
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint("Error leaving jar: $e");
      return "Lỗi khi rời khỏi hũ: ${e.toString()}";
    }
  }

  Future<bool> depositToJar(String jarID, double amount) async {
    if (amount <= 0 || amount > mainBalance) return false;

    try {
      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex != -1) {
        final jar = _savingJars[jarIndex];
        final updatedJar = jar.copyWith(
          currentAmt: jar.currentAmt + amount,
          status: (jar.currentAmt + amount >= jar.targetAmt) ? 'completed' : 'active',
        );

        await _firebaseService.updateSavingJar(updatedJar);
        _savingJars[jarIndex] = updatedJar;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error depositing to jar: $e");
    }
    return false;
  }

  Future<bool> withdrawFromJar(String jarID, double amount) async {
    try {
      final jarIndex = _savingJars.indexWhere((j) => j.jarID == jarID);
      if (jarIndex != -1) {
        final jar = _savingJars[jarIndex];
        if (amount <= 0 || amount > jar.currentAmt) return false;

        final updatedJar = jar.copyWith(
          currentAmt: jar.currentAmt - amount,
          status: 'active', // Set back to active if we withdraw
        );

        await _firebaseService.updateSavingJar(updatedJar);
        _savingJars[jarIndex] = updatedJar;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error withdrawing from jar: $e");
    }
    return false;
  }

  Future<void> deleteSavingJar(String jarID) async {
    try {
      // Deleting the jar refunds any stored currentAmt back to mainBalance 
      // (This happens naturally because jarsAllocated decreases, releasing mainBalance)
      await _firebaseService.deleteSavingJar(jarID);
      _savingJars.removeWhere((j) => j.jarID == jarID);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting saving jar: $e");
    }
  }

  // ==========================================
  // BUDGET MANAGEMENT
  // ==========================================

  Future<bool> setMonthlyBudget(double limitAmt, String uID) async {
    try {
      final now = DateTime.now();
      final targetDate = DateTime(now.year, now.month, 1);

      final existingBudget = _monthlyBudget;
      final BudgetModel newBudget = BudgetModel(
        bgID: existingBudget?.bgID ?? '',
        uID: uID,
        limitAmt: limitAmt,
        date: targetDate,
      );

      final savedBudget = await _firebaseService.setBudget(newBudget);
      _monthlyBudget = savedBudget;
      
      // Reset the session alert
      _hasBudgetAlertBeenShownThisSession = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error setting budget: $e");
      return false;
    }
  }

  // ==========================================
  // LOANS AND DEBTS CRUD
  // ==========================================

  Future<bool> addLoan({
    required String uID,
    required String type, // 'loan' (cho vay) or 'debt' (đi vay)
    required String personName,
    required double principal,
    required double interestRate,
    required String interestType, // 'simple', 'compound', 'reducing'
    required int months,
    required DateTime startDate,
    String? notes,
  }) async {
    try {
      final dueDate = DateTime(
        startDate.year + ((startDate.month + months - 1) ~/ 12),
        ((startDate.month + months - 1) % 12) + 1,
        startDate.day,
      );

      final newLoan = LoanModel(
        loanID: '',
        uID: uID,
        type: type,
        personName: personName.trim(),
        principal: principal,
        interestRate: interestRate,
        interestType: interestType,
        months: months,
        startDate: startDate,
        dueDate: dueDate,
        payments: [],
        status: 'active',
        notes: notes?.trim(),
        createdAt: DateTime.now(),
      );

      final savedLoan = await _firebaseService.addLoan(newLoan);
      _loans.insert(0, savedLoan);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error adding loan: $e");
      return false;
    }
  }

  Future<String?> addRepaymentToLoan(String loanID, double amount, {String? note}) async {
    try {
      final loanIndex = _loans.indexWhere((l) => l.loanID == loanID);
      if (loanIndex == -1) {
        return "Không tìm thấy khoản vay/nợ!";
      }

      final loan = _loans[loanIndex];
      final remPayable = loan.remainingPayable;

      if (remPayable <= 0) {
        return "Khoản này đã được thanh toán hoàn tất!";
      }

      if (amount <= 0) {
        return "Số tiền trả phải lớn hơn 0!";
      }

      if (amount > remPayable) {
        final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        return "Số tiền trả (${fmt.format(amount)}) không được vượt quá số tiền còn lại (${fmt.format(remPayable)})!";
      }

      final repayment = RepaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        date: DateTime.now(),
        note: note,
      );

      final updatedPayments = List<RepaymentModel>.from(loan.payments)..add(repayment);
      final totalPaid = updatedPayments.fold(0.0, (sum, p) => sum + p.amount);
      final isPaid = totalPaid >= loan.totalPayable;

      final updatedLoan = loan.copyWith(
        payments: updatedPayments,
        status: isPaid ? 'paid' : 'active',
      );

      await _firebaseService.updateLoan(updatedLoan);
      _loans[loanIndex] = updatedLoan;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Error adding repayment: $e");
      return "Đã xảy ra lỗi khi lưu trả tiền: ${e.toString()}";
    }
  }

  Future<bool> toggleLoanStatus(String loanID) async {
    try {
      final loanIndex = _loans.indexWhere((l) => l.loanID == loanID);
      if (loanIndex != -1) {
        final loan = _loans[loanIndex];
        final newStatus = loan.status == 'active' ? 'paid' : 'active';
        final updatedLoan = loan.copyWith(status: newStatus);

        await _firebaseService.updateLoan(updatedLoan);
        _loans[loanIndex] = updatedLoan;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error toggling loan status: $e");
    }
    return false;
  }

  Future<void> deleteLoan(String loanID) async {
    try {
      await _firebaseService.deleteLoan(loanID);
      _loans.removeWhere((l) => l.loanID == loanID);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting loan: $e");
    }
  }

  // ==========================================
  // EXPORT HELPERS
  // ==========================================

  String exportExcelCsvContent() {
    return ExportService.generateExcelCsv(
      transactions: _transactions,
      categories: _categories,
      jars: _savingJars,
      loans: _loans,
      budget: _monthlyBudget,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: mainBalance,
    );
  }

  String exportPrintableReportContent() {
    return ExportService.generatePrintableSummaryReport(
      transactions: _transactions,
      categories: _categories,
      jars: _savingJars,
      loans: _loans,
      budget: _monthlyBudget,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: mainBalance,
    );
  }
}
