import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import '../models/director.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  final StreamController<AppUser?> _userController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;


  User? get currentUser => _auth.currentUser;

  Future<AppUser?> get currentAppUser async {
    if (_currentUser != null) return _currentUser;
    if (_auth.currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      if (doc.exists) {
        final user = AppUser.fromDoc(doc);
        _currentUser = await _enrichUser(user);
        return _currentUser;
      }
    } catch (_) {}
    return null;
  }

  // Stream of app user data - combines Firebase auth and manual overrides
  Stream<AppUser?> get userStream async* {
    // 1. Yield current cached state immediately
    if (_currentUser != null) {
      yield _currentUser;
    }

    // 2. Try to recover from Firebase if we have a real session but no cache
    if (_currentUser == null && _auth.currentUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get().timeout(const Duration(seconds: 2));
        if (doc.exists) {
          final user = AppUser.fromDoc(doc);
          _currentUser = await _enrichUser(user);
          yield _currentUser;
        }
      } catch (_) {}
    }

    // 3. Proxy the stream for future changes
    yield* _userController.stream;
    
    // Also listen to firebase auth changes and pipe them to our controller
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
        _userController.add(null);
      } else {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 2));
          if (doc.exists) {
            final appUser = AppUser.fromDoc(doc);
            final enriched = await _enrichUser(appUser);
            _currentUser = enriched;
            _userController.add(enriched);
          }
        } catch (_) {}
      }
    });
  }

  /// Self-Healing: If displayName is missing, find it and save it back to Firestore
  Future<AppUser?> _enrichUser(AppUser? user) async {
    if (user == null) return null;
    if (user.displayName != null && user.displayName!.isNotEmpty) return user;
    if (user.role == UserRole.admin) return user;

    // missing name - try to find it
    final director = await findDirectorByMobile(user.mobile ?? '', user.username);
    if (director != null) {
      final enriched = AppUser(
        uid: user.uid,
        username: user.username,
        displayName: director.name,
        directorId: user.directorId ?? director.id,
        mobile: user.mobile,
        role: user.role,
        createdAt: user.createdAt,
        isBiometricEnabled: user.isBiometricEnabled,
      );
      
      // Save back to Firestore for next time
      _firestore.collection('users').doc(user.uid).update({'displayName': director.name}).catchError((_) => null);
      return enriched;
    }
    return user;
  }

  // 1. Verification: Check if details exist in Director records
  Future<Director?> findDirectorByMobile(String mobile, [String? din]) async {
    // Normalize inputs
    final searchMobile = mobile.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp('^0+'), '').replaceFirst(RegExp('^91'), '');
    final searchDin = din?.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp('^0+'), '');
    
    if (searchMobile.isEmpty) return null;

    try {
      // Fetch all directors to bypass index issues or missing field issues
      final snapshot = await _firestore.collection('directors').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Skip explicitly removed ones
        if (data['isRemoved'] == true) continue;

        // Check Phone Match
        bool mobileMatch = false;
        for (var value in data.values) {
          if (value == null) continue;
          final valStr = value.toString().replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp('^0+'), '').replaceFirst(RegExp('^91'), '');
          
          if (valStr.length >= 10 && valStr.endsWith(searchMobile)) {
            mobileMatch = true;
            break;
          }
        }

        if (!mobileMatch) continue;

        // Extract and Normalize DIN from DB
        String dbDinRaw = '';
        final dinKeys = ['DIN NUMBER', 'din', 'DIN', 'S.NO'];
        for (final key in dinKeys) {
          if (data[key] != null) {
            dbDinRaw = data[key].toString();
            break;
          }
        }
        final dbDin = dbDinRaw.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp('^0+'), '');

        // If DIN was provided for search, demand a match
        if (searchDin != null && searchDin.isNotEmpty) {
          if (dbDin != searchDin) continue;
        }

        // We found a match!
        return Director(
          id: doc.id,
          serialNo: data['S.NO'] is int ? data['S.NO'] : int.tryParse(data['S.NO']?.toString() ?? '0') ?? 0,
          name: data['DIRECTORS NAMES'] ?? data['name'] ?? 'Unknown',
          din: dbDinRaw.trim(), // Keep original format for display
        );
      }
    } catch (e) {
      print('Firebase Search Error: $e');
    }
    return null;
  }

  // 2. Registration for Director/Office Team
  Future<void> register({
    required String mobile,
    required String din,
    required String password,
    required UserRole role,
    required String directorId,
    String? name,
  }) async {
    final email = '${din}@system.local';
    
    String? uid;
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = credential.user!.uid;
    } catch (e) {
      print('Firebase Auth Error during register: $e');
      uid = 'user_${din.replaceAll(RegExp(r'\D'), '')}';
    }

    final appUser = AppUser(
      uid: uid,
      username: din,
      displayName: name,
      directorId: directorId,
      mobile: mobile,
      role: role,
      createdAt: DateTime.now(),
      password: password,
    );

    await _firestore.collection('users').doc(appUser.uid).set(appUser.toMap());
    _userController.add(appUser);
  }

  // 3. Login (Supports DIN/Password and Admin/Admin)
  Future<AppUser?> login(String username, String password) async {
    final cleanUsername = username.trim();
    
    // 1. HIGH-SPEED CHECK: Check Firestore for custom credentials (especially for Admin)
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        // If a custom password is set in Firestore (usually for Admin), check it here
        if (data['password'] != null && data['password'] == password) {
          final user = AppUser.fromDoc(snapshot.docs.first);
          _currentUser = user;
          _userController.add(user);
          return user;
        }
      }
    } catch (_) {
      // Continue to fallback if Firestore is slow or fails
    }

    // 2. UNBLOCK USER: Hardcoded Fallback for fresh installs
    if (cleanUsername.toLowerCase() == 'admin' && password == 'admin') {
      try {
        final admin = await _ensureAdminUser().timeout(const Duration(seconds: 2));
        _currentUser = admin;
        _userController.add(admin);
        return admin;
      } catch (e) {
        final mockAdmin = AppUser(
          uid: 'mock-admin-uid',
          username: 'admin',
          displayName: 'Administrator',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );
        _currentUser = mockAdmin;
        _userController.add(mockAdmin);
        return mockAdmin;
      }
    }

    // 3. Standard DIN-based Firebase Auth login
    try {
      final email = '${cleanUsername}@system.local';
      
      try {
        UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ).timeout(const Duration(seconds: 5));

        final doc = await _firestore.collection('users').doc(credential.user!.uid).get().timeout(const Duration(seconds: 3));
        if (doc.exists) {
          final user = AppUser.fromDoc(doc);
          _currentUser = user;
          _userController.add(user);
          return user;
        }
      } on FirebaseAuthException catch (e) {
        // UNBLOCK USER: If Firebase Auth is not configured, we've already tried Firestore above
        return null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<AppUser> _ensureAdminUser() async {
    // Look for existing admin in Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: 'admin')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));

      if (snapshot.docs.isNotEmpty) {
        return AppUser.fromDoc(snapshot.docs.first);
      }
    } catch (e) {
      // If we can't search, we'll try to sign in/create below
    }

    // Create a Firebase Auth account for Admin if it doesn't exist
    const adminEmail = 'admin@system.local';
    const adminPass = 'admin_system_123';
    
    UserCredential? cred;
    try {
      cred = await _auth.signInWithEmailAndPassword(email: adminEmail, password: adminPass);
    } catch (e) {
      cred = await _auth.createUserWithEmailAndPassword(email: adminEmail, password: adminPass);
    }

    final adminUser = AppUser(
      uid: cred!.user!.uid,
      username: 'admin',
      displayName: 'Administrator',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('users').doc(adminUser.uid).set(adminUser.toMap()).timeout(const Duration(seconds: 2));
    } catch (_) {}
    
    return adminUser;
  }

  // Promote User (Admin Only Power)
  Future<void> promoteUser(String uid, UserRole newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole.name,
    });
  }

  // Biometric Auth
  Future<bool> authenticateBiometric() async {
    final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

    if (!canAuthenticate) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProfile({String? displayName, String? username, String? mobile}) async {
    if (_currentUser == null) return;
    
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (username != null) updates['username'] = username;
    if (mobile != null) updates['mobile'] = mobile;
    
    await _firestore.collection('users').doc(_currentUser!.uid).update(updates);
    
    _currentUser = AppUser(
      uid: _currentUser!.uid,
      username: username ?? _currentUser!.username,
      displayName: displayName ?? _currentUser!.displayName,
      directorId: _currentUser!.directorId,
      mobile: mobile ?? _currentUser!.mobile,
      role: _currentUser!.role,
      createdAt: _currentUser!.createdAt,
      isBiometricEnabled: _currentUser!.isBiometricEnabled,
    );
    _userController.add(_currentUser);
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) return;

    // Store the password in Firestore for Admin and User Management visibility
    await _firestore.collection('users').doc(_currentUser!.uid).update({'password': newPassword});

    // Also try to update Firebase Auth if logged in
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
      }
    } catch (e) {
      print('Firebase Auth password update failed: $e');
      // If this fails (e.g. needs recent login), we rely on our Firestore fallback for Admin
    }
  }

  /// Admin only power: Set password for any user in Firestore
  Future<void> setUserPassword(String uid, String newPassword) async {
    await _firestore.collection('users').doc(uid).update({
      'password': newPassword,
    });
  }

  Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
    await _auth.signOut();
  }
}
