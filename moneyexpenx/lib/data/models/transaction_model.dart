import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String tsID;
  final String uID;
  final String ctgID;
  final double amt;
  final DateTime tsDate;
  final String note;

  TransactionModel({
    required this.tsID,
    required this.uID,
    required this.ctgID,
    required this.amt,
    required this.tsDate,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'tsID': tsID,
      'uID': uID,
      'ctgID': ctgID,
      'amt': amt,
      'ts_date': Timestamp.fromDate(tsDate),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      tsID: map['tsID'] ?? '',
      uID: map['uID'] ?? '',
      ctgID: map['ctgID'] ?? '',
      amt: (map['amt'] as num?)?.toDouble() ?? 0.0,
      tsDate: (map['ts_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] ?? '',
    );
  }

  TransactionModel copyWith({
    String? tsID,
    String? uID,
    String? ctgID,
    double? amt,
    DateTime? tsDate,
    String? note,
  }) {
    return TransactionModel(
      tsID: tsID ?? this.tsID,
      uID: uID ?? this.uID,
      ctgID: ctgID ?? this.ctgID,
      amt: amt ?? this.amt,
      tsDate: tsDate ?? this.tsDate,
      note: note ?? this.note,
    );
  }
}
