import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/notification_service.dart';

const String _kUser = 'user';
const String _kToken = 'auth_token';
const String _kTokenExpiry = 'auth_token_expiry';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _token; 

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get token => _token;


  Future<String> _getUserRoleFromDatabase(String email) async {
    try {
      final url = Uri.parse(
          'http://192.168.0.181:3000/fixit_api/get_user_role.php?email=$email');
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('Role dari API: ${data['role']}');
          return data['role'] ?? 'customer';
        }
      }
      return 'customer';
    } catch (e) {
      print(' Get role error: $e');
      return 'customer';
    }
  }

  Future<void> _saveTokenToPrefs(firebase_auth.User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) return;

      _token = idToken;
      final expiry =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, idToken);
      await prefs.setInt(_kTokenExpiry, expiry);

      print(' Token disimpan ke SharedPrefs (expire: ${DateTime.fromMillisecondsSinceEpoch(expiry)})');
    } catch (e) {
      print(' Gagal menyimpan token: $e');
    }
  }

  Future<String?> getValidToken() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final freshToken = await firebaseUser.getIdToken();
      _token = freshToken;

      final prefs = await SharedPreferences.getInstance();
      if (freshToken != null) {
        await prefs.setString(_kToken, freshToken);
        await prefs.setInt(
          _kTokenExpiry,
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        );
      }
      return freshToken;
    } catch (e) {
      print(' Gagal refresh token: $e');
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_kToken);
      final expiry = prefs.getInt(_kTokenExpiry) ?? 0;

      if (cachedToken != null &&
          DateTime.now().millisecondsSinceEpoch < expiry) {
        return cachedToken;
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userEmail = firebaseUser.email ?? googleUser.email;
        final userName =
            firebaseUser.displayName ?? googleUser.displayName ?? 'User';
        final userId = firebaseUser.uid;

        print('User email: $userEmail');
        print('User name: $userName');

        await _saveTokenToPrefs(firebaseUser);

        String role = await _getUserRoleFromDatabase(userEmail);

        if (role != 'customer') {
          _currentUser = UserModel(
            id: userId,
            name: userName,
            email: userEmail,
            phone: firebaseUser.phoneNumber ?? '',
            role: role,
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kUser, jsonEncode(_currentUser!.toMap()));

          _isLoading = false;
          notifyListeners();
          print(' Login success, role: ${_currentUser!.role}');

          return {
            'success': true,
            'isNewUser': false,
            'user': _currentUser,
          };
        } else {
          _isLoading = false;
          notifyListeners();

          return {
            'success': true,
            'isNewUser': true,
            'email': userEmail,
            'name': userName,
            'id': userId,
          };
        }
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      print('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveUserAfterGoogleLogin({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    print('Save user: $email, role: $role');

    _currentUser = UserModel(
      id: id,
      name: name,
      email: email,
      phone: '',
      role: role,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(_currentUser!.toMap()));

    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _saveTokenToPrefs(firebaseUser);
    }

    await _saveUserToDatabase(email, name, role);

    await NotificationService().saveFcmTokenToServer(email);

    notifyListeners();
    print('User saved successfully');
    return true;
  }

  Future<void> _saveUserToDatabase(
      String email, String name, String role) async {
    try {
      final url = Uri.parse('http://192.168.0.181:3000/fixit_api/save_user.php');
      final response = await http.post(
        url,
        body: {'email': email, 'name': name, 'role': role},
      );
      print('📡 Save user to DB: ${response.body}');
    } catch (e) {
      print('❌ Failed to save user to database: $e');
    }
  }

  Future<bool> login(
      {required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await _saveTokenToPrefs(firebaseUser);

        String role = await _getUserRoleFromDatabase(email);
        print('📋 Role dari database untuk $email: $role');

        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: firebaseUser.email ?? email,
          phone: firebaseUser.phoneNumber ?? '',
          role: role,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUser, jsonEncode(_currentUser!.toMap()));

        await NotificationService().saveFcmTokenToServer(email);

        _isLoading = false;
        notifyListeners();
        print(' Login berhasil: \${_currentUser!.email} (\${_currentUser!.role})');
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await _saveTokenToPrefs(firebaseUser);

        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: name,
          email: email,
          phone: phone,
          role: 'customer',
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUser, jsonEncode(_currentUser!.toMap()));

        await _saveUserToDatabase(email, name, 'customer');

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_kUser);

      if (userJson == null || userJson.isEmpty) {
        print(' Tidak ada data user di SharedPrefs');
        _currentUser = null;
        notifyListeners();
        return;
      }

      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        print(' Firebase Auth tidak punya sesi aktif, hapus data lokal');
        await _clearAllPrefs(prefs);
        _currentUser = null;
        notifyListeners();
        return;
      }

      _currentUser = UserModel.fromMap(jsonDecode(userJson));

      try {
        final freshToken = await firebaseUser.getIdToken(false);
        _token = freshToken;
        if (freshToken != null) {
          await prefs.setString(_kToken, freshToken);
          await prefs.setInt(
            _kTokenExpiry,
            DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch,
          );
        }
        print(' Token diperbarui saat loadUser');
      } catch (tokenErr) {
        print(' Gagal refresh token saat loadUser: $tokenErr');
      }

      if (firebaseUser.email != null) {
        await NotificationService().saveFcmTokenToServer(firebaseUser.email!);
      }

      print(
          ' User dimuat: ${_currentUser?.email}, role: ${_currentUser?.role}');
      notifyListeners();
    } catch (e) {
      print(' Load user error: $e');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    print(' Mulai proses logout...');

    try {
      await _firebaseAuth.signOut();
      print(' Firebase sign out berhasil');
    } catch (e) {
      print(' Firebase sign out error (dilanjutkan): $e');
    }

    try {
      await _googleSignIn.signOut();
      print(' Google sign out berhasil');
    } catch (e) {
      print(' Google sign out error (dilanjutkan): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await _clearAllPrefs(prefs);

    _currentUser = null;
    _token = null;

    print(' Logout selesai — semua sesi dibersihkan');
    notifyListeners();
  }

  Future<void> _clearAllPrefs(SharedPreferences prefs) async {
    await prefs.remove(_kUser);
    await prefs.remove(_kToken);
    await prefs.remove(_kTokenExpiry);

    print(' SharedPrefs dibersihkan');
  }
}