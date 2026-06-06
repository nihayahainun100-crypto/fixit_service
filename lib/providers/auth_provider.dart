import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // ==================== AMBIL ROLE DARI DATABASE ====================
  
  Future<String> _getUserRoleFromDatabase(String email) async {
    try {
      final url = Uri.parse('http://192.168.0.104/fixit_api/get_user_role.php?email=$email');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('📋 Role dari API: ${data['role']}');
          return data['role'] ?? 'customer';
        }
      }
      return 'customer';
    } catch (e) {
      print('❌ Get role error: $e');
      return 'customer';
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  
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
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      
      final firebase_auth.UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;
      
      if (firebaseUser != null) {
        final userEmail = firebaseUser.email ?? googleUser.email;
        final userName = firebaseUser.displayName ?? googleUser.displayName ?? 'User';
        final userId = firebaseUser.uid;
        
        print('User email: $userEmail');
        print('User name: $userName');
        
        // Ambil role dari database
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
          await prefs.setString('user', jsonEncode(_currentUser!.toMap()));
          
          _isLoading = false;
          notifyListeners();
          print('Login success, role: ${_currentUser!.role}');
          
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
    await prefs.setString('user', jsonEncode(_currentUser!.toMap()));
    
    // Simpan ke database
    await _saveUserToDatabase(email, name, role);
    
    notifyListeners();
    print('User saved successfully');
    return true;
  }
  
  Future<void> _saveUserToDatabase(String email, String name, String role) async {
    try {
      final url = Uri.parse('http://192.168.0.104/fixit_api/save_user.php');
      final response = await http.post(
        url,
        body: {'email': email, 'name': name, 'role': role},
      );
      print('📡 Save user to DB: ${response.body}');
    } catch (e) {
      print('❌ Failed to save user to database: $e');
    }
  }

  // ==================== EMAIL/PASSWORD LOGIN ====================
  
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebase_auth.UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Ambil role dari database
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
        await prefs.setString('user', jsonEncode(_currentUser!.toMap()));
        
        _isLoading = false;
        notifyListeners();
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

  // ==================== REGISTER ====================
  
  Future<bool> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final firebase_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(name);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: name,
          email: email,
          phone: phone,
          role: 'customer',
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_currentUser!.toMap()));
        
        // Simpan ke database
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

  // ==================== LOAD USER ====================
  
  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = UserModel.fromMap(jsonDecode(userJson));
        print('User loaded: ${_currentUser?.email}, role: ${_currentUser?.role}');
      } else {
        print('No user found');
      }
      notifyListeners();
    } catch (e) {
      print('Load user error: $e');
    }
  }

  // ==================== LOGOUT ====================
  
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    _currentUser = null;
    notifyListeners();
  }
}