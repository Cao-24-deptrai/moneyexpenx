import 'package:cloud_firestore/cloud_firestore.dart';

class SavingJarModel {
  final String jarID;
  final String uID;
  final String name;
  final double targetAmt;
  final double currentAmt;
  final DateTime targetDate;
  final String status; // 'active', 'completed'
  final List<String> members; // Shared member UIDs

  SavingJarModel({
    required this.jarID,
    required this.uID,
    required this.name,
    required this.targetAmt,
    required this.currentAmt,
    required this.targetDate,
    this.status = 'active',
    this.members = const [],
  });

  double get progressPercent {
    if (targetAmt <= 0) return 0.0;
    final percent = currentAmt / targetAmt;
    return percent > 1.0 ? 1.0 : percent;
  }

  Map<String, dynamic> toMap() {
    return {
      'jarID': jarID,
      'uID': uID,
      'name': name,
      'target_amt': targetAmt,
      'current_amt': currentAmt,
      'target_date': Timestamp.fromDate(targetDate),
      'status': status,
      'members': members,
    };
  }

  factory SavingJarModel.fromMap(Map<String, dynamic> map) {
    return SavingJarModel(
      jarID: map['jarID'] ?? '',
      uID: map['uID'] ?? '',
      name: map['name'] ?? '',
      targetAmt: (map['target_amt'] as num?)?.toDouble() ?? 0.0,
      currentAmt: (map['current_amt'] as num?)?.toDouble() ?? 0.0,
      targetDate: (map['target_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'active',
      members: map['members'] != null 
          ? List<String>.from(map['members']) 
          : [map['uID'] ?? ''],
    );
  }

  SavingJarModel copyWith({
    String? jarID,
    String? uID,
    String? name,
    double? targetAmt,
    double? currentAmt,
    DateTime? targetDate,
    String? status,
    List<String>? members,
  }) {
    return SavingJarModel(
      jarID: jarID ?? this.jarID,
      uID: uID ?? this.uID,
      name: name ?? this.name,
      targetAmt: targetAmt ?? this.targetAmt,
      currentAmt: currentAmt ?? this.currentAmt,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      members: members ?? this.members,
    );
  }
}
