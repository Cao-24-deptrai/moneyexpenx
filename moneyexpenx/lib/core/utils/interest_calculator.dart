import 'dart:math';

class SimpleInterestResult {
  final double totalPayable;
  final double interestAmount;
  final double monthlyPayment;

  SimpleInterestResult({
    required this.totalPayable,
    required this.interestAmount,
    required this.monthlyPayment,
  });
}

class CompoundInterestResult {
  final double totalPayable;
  final double interestAmount;
  final double monthlyPayment;

  CompoundInterestResult({
    required this.totalPayable,
    required this.interestAmount,
    required this.monthlyPayment,
  });
}

class ScheduleEntry {
  final int month;
  final double openingBalance;
  final double payment;
  final double interestPaid;
  final double principalPaid;
  final double closingBalance;

  ScheduleEntry({
    required this.month,
    required this.openingBalance,
    required this.payment,
    required this.interestPaid,
    required this.principalPaid,
    required this.closingBalance,
  });
}

class ReducingBalanceResult {
  final double totalPayable;
  final double interestAmount;
  final double monthlyPayment;
  final List<ScheduleEntry> schedule;

  ReducingBalanceResult({
    required this.totalPayable,
    required this.interestAmount,
    required this.monthlyPayment,
    required this.schedule,
  });
}

class InterestCalculator {
  /// Lãi đơn (Simple Interest)
  /// Principal: Số tiền vay gốc
  /// RateAnnual: Lãi suất %/năm
  /// Months: Số tháng vay
  static SimpleInterestResult calculateSimpleInterest({
    required double principal,
    required double rateAnnual,
    required int months,
  }) {
    if (months <= 0) {
      return SimpleInterestResult(totalPayable: principal, interestAmount: 0, monthlyPayment: principal);
    }
    final rateFraction = rateAnnual / 100;
    final timeYears = months / 12;
    final interestAmount = principal * rateFraction * timeYears;
    final totalPayable = principal + interestAmount;
    final monthlyPayment = totalPayable / months;

    return SimpleInterestResult(
      totalPayable: totalPayable,
      interestAmount: interestAmount,
      monthlyPayment: monthlyPayment,
    );
  }

  /// Lãi kép (Compound Interest)
  /// Frequency: Số lần nhập gốc/năm (mặc định 12 = hàng tháng)
  static CompoundInterestResult calculateCompoundInterest({
    required double principal,
    required double rateAnnual,
    required int months,
    int frequency = 12,
  }) {
    if (months <= 0) {
      return CompoundInterestResult(totalPayable: principal, interestAmount: 0, monthlyPayment: principal);
    }
    final rateFraction = rateAnnual / 100;
    final timeYears = months / 12;

    // A = P * (1 + r/n)^(n*t)
    final totalPayable = principal * pow(1 + rateFraction / frequency, frequency * timeYears);
    final interestAmount = totalPayable - principal;
    final monthlyPayment = totalPayable / months;

    return CompoundInterestResult(
      totalPayable: totalPayable,
      interestAmount: interestAmount,
      monthlyPayment: monthlyPayment,
    );
  }

  /// Dư nợ giảm dần (Reducing Balance Interest / Trả góp đều)
  static ReducingBalanceResult calculateReducingBalance({
    required double principal,
    required double rateAnnual,
    required int months,
  }) {
    if (months <= 0) {
      return ReducingBalanceResult(
        totalPayable: principal,
        interestAmount: 0,
        monthlyPayment: principal,
        schedule: [],
      );
    }

    final rateMonthly = rateAnnual / 100 / 12;
    double monthlyPayment = 0;

    if (rateMonthly == 0) {
      monthlyPayment = principal / months;
    } else {
      // PMT = P * [r(1+r)^n] / [(1+r)^n - 1]
      final factor = pow(1 + rateMonthly, months);
      monthlyPayment = (principal * (rateMonthly * factor)) / (factor - 1);
    }

    final List<ScheduleEntry> schedule = [];
    double remainingPrincipal = principal;
    double totalInterest = 0;

    for (int i = 1; i <= months; i++) {
      final openingBalance = remainingPrincipal;
      final interestPaid = remainingPrincipal * rateMonthly;
      final principalPaid = monthlyPayment - interestPaid;

      remainingPrincipal = max(0.0, remainingPrincipal - principalPaid);
      totalInterest += interestPaid;

      schedule.add(
        ScheduleEntry(
          month: i,
          openingBalance: openingBalance,
          payment: monthlyPayment,
          interestPaid: interestPaid,
          principalPaid: principalPaid,
          closingBalance: remainingPrincipal,
        ),
      );
    }

    return ReducingBalanceResult(
      totalPayable: principal + totalInterest,
      interestAmount: totalInterest,
      monthlyPayment: monthlyPayment,
      schedule: schedule,
    );
  }
}
