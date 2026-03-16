import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  director,
  officeTeam,
  admin,
}

class AppUser {
  final String uid;
  final String username; // DIN for directors/staff, 'admin' for admin
  final String? displayName; // Actual name of the user
  final String? directorId; // Linked director record ID
  final String? mobile;
  final UserRole role;
  final DateTime createdAt;
  final bool isBiometricEnabled;
  final String? password;

  AppUser({
    required this.uid,
    required this.username,
    this.displayName,
    this.directorId,
    this.mobile,
    required this.role,
    required this.createdAt,
    this.isBiometricEnabled = false,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'directorId': directorId,
      'mobile': mobile,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isBiometricEnabled': isBiometricEnabled,
      'password': password,
    };
  }

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      directorId: data['directorId'],
      mobile: data['mobile'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.director,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isBiometricEnabled: data['isBiometricEnabled'] ?? false,
      password: data['password'],
    );
  }
}
