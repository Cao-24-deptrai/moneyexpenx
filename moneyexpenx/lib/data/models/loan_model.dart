import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moneyexpenx/core/utils/interest_calculator.dart';

class RepaymentModel {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  RepaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }

  factory RepaymentModel.fromMap(Map<String, dynamic> map) {
    return RepaymentModel(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : (map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now()),
      note: map['note'],
    );
  }
}

class LoanModel {
  final String loanID;
  final String uID;
  final String type; // 'loan' (Cho vay) or 'debt' (Đi vay)
  final String personName;
  final double principal;
  final double interestRate; // % / năm
  final String interestType; // 'simple', 'compound', 'reducing'
  final int months;
  final DateTime startDate;
  final DateTime? dueDate;
  final List<RepaymentModel> payments;
  final String status; // 'active', 'paid'
  final String? notes;
  final DateTime createdAt;

  LoanModel({
    required this.loanID,
    required this.uID,
    required this.type,
    required this.personName,
    required this.principal,
    required this.interestRate,
    required this.interestType,
    required this.months,
    required this.startDate,
    this.dueDate,
    required this.payments,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  double get totalPaid {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }

  double get interestAmount {
    if (interestRate <= 0 || months <= 0) return 0.0;
    if (interestType == 'compound') {
      return InterestCalculator.calculateCompoundInterest(
        principal: principal,
        rateAnnual: interestRate,
        months: months,
      ).interestAmount;
    } else if (interestType == 'reducing') {
      return InterestCalculator.calculateReducingBalance(
        principal: principal,
        rateAnnual: interestRate,
        months: months,
      ).interestAmount;
    } else {
      return InterestCalculator.calculateSimpleInterest(
        principal: principal,
        rateAnnual: interestRate,
        months: months,
      ).interestAmount;
    }
  }

  /// Tổng tiền phải trả cả gốc lẫn lãi
  double get totalPayable => principal + interestAmount;

  /// Số tiền còn lại phải trả cả gốc lẫn lãi
  double get remainingPayable {
    final rem = totalPayable - totalPaid;
    return rem < 0 ? 0.0 : rem;
  }

  /// Dư nợ gốc còn lại
  double get remainingPrincipal {
    final rem = principal - totalPaid;
    return rem < 0 ? 0.0 : rem;
  }

  /// Tiến độ trả tiền (%)
  double get progressRatio {
    if (totalPayable <= 0) return 0.0;
    final ratio = totalPaid / totalPayable;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  Map<String, dynamic> toMap() {
    return {
      'loanID': loanID,
      'uID': uID,
      'type': type,
      'personName': personName,
      'principal': principal,
      'interestRate': interestRate,
      'interestType': interestType,
      'months': months,
      'startDate': Timestamp.fromDate(startDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'payments': payments.map((p) => p.toMap()).toList(),
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      loanID: map['loanID'] ?? '',
      uID: map['uID'] ?? '',
      type: map['type'] ?? 'loan',
      personName: map['personName'] ?? '',
      principal: (map['principal'] as num?)?.toDouble() ?? 0.0,
      interestRate: (map['interestRate'] as num?)?.toDouble() ?? 0.0,
      interestType: map['interestType'] ?? 'simple',
      months: (map['months'] as num?)?.toInt() ?? 1,
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : (map['startDate'] != null ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now() : DateTime.now()),
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : (map['dueDate'] != null ? DateTime.tryParse(map['dueDate'].toString()) : null),
      payments: (map['payments'] as List<dynamic>?)
              ?.map((p) => RepaymentModel.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      status: map['status'] ?? 'active',
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now() : DateTime.now()),
    );
  }

  LoanModel copyWith({
    String? loanID,
    String? uID,
    String? type,
    String? personName,
    double? principal,
    double? interestRate,
    String? interestType,
    int? months,
    DateTime? startDate,
    DateTime? dueDate,
    List<RepaymentModel>? payments,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return LoanModel(
      loanID: loanID ?? this.loanID,
      uID: uID ?? this.uID,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      months: months ?? this.months,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
