import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uID;
  final String username;
  final String email;
  final DateTime createdAt;
  final String role; // 'admin' or 'user'

  UserModel({
    required this.uID,
    required this.username,
    required this.email,
    required this.createdAt,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uID': uID,
      'username': username,
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
      'role': role,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final email = map['email'] ?? '';
    final isDefaultAdmin =
        email.toString().trim().toLowerCase() == 'rocon@gmail.com';
    return UserModel(
      uID: map['uID'] ?? '',
      username: map['username'] ?? '',
      email: email,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'] ?? (isDefaultAdmin ? 'admin' : 'user'),
    );
  }

  UserModel copyWith({
    String? uID,
    String? username,
    String? email,
    DateTime? createdAt,
    String? role,
  }) {
    return UserModel(
      uID: uID ?? this.uID,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}
