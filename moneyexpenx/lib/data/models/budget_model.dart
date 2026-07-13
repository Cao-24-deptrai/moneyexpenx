import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String bgID;
  final String uID;
  final double limitAmt;
  final DateTime date; // Used to represent the month/year of this budget (e.g. 2026-07-01)
  final String currency;

  BudgetModel({
    required this.bgID,
    required this.uID,
    required this.limitAmt,
    required this.date,
    this.currency = 'VND',
  });

  Map<String, dynamic> toMap() {
    return {
      'bgID': bgID,
      'uID': uID,
      'limit_amt': limitAmt,
      'date': Timestamp.fromDate(date),
      'currency': currency,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      bgID: map['bgID'] ?? '',
      uID: map['uID'] ?? '',
      limitAmt: (map['limit_amt'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: map['currency'] ?? 'VND',
    );
  }

  BudgetModel copyWith({
    String? bgID,
    String? uID,
    double? limitAmt,
    DateTime? date,
    String? currency,
  }) {
    return BudgetModel(
      bgID: bgID ?? this.bgID,
      uID: uID ?? this.uID,
      limitAmt: limitAmt ?? this.limitAmt,
      date: date ?? this.date,
      currency: currency ?? this.currency,
    );
  }
}
