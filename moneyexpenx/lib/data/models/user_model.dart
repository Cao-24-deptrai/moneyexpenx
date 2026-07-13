import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uID;
  final String username;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uID,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uID': uID,
      'username': username,
      'email': email,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uID: map['uID'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
