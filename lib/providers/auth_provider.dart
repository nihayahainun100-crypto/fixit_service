import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
// HAPUS import api_service.dart dan role_picker_screen.dart dari sini

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // ==================== GOOGLE SIGN-IN ====================
  
  // Return data user, navigasi di handle di UI
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
        
        // CEK DI SHAREDPREFERENCES LOKAL
        final prefs = await SharedPreferences.getInstance();
        final usersWithRoles = prefs.getStringList('users_with_roles') ?? [];
        
        String? existingRole;
        for (var jsonStr in usersWithRoles) {
          final data = jsonDecode(jsonStr);
          if (data['email'] == userEmail) {
            existingRole = data['role'];
            break;
          }
        }
        
        print('Existing role: $existingRole');
        
        if (existingRole != null) {
          // USER SUDAH ADA, LANGSUNG LOGIN
          _currentUser = UserModel(
            id: userId,
            name: userName,
            email: userEmail,
            phone: firebaseUser.phoneNumber ?? '',
            role: existingRole,
          );
          
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
          // USER BARU, butuh pilih role
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
  
  // Simpan user setelah pilih role
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
    
    // Simpan juga ke daftar users dengan role
    List<String> usersWithRoles = prefs.getStringList('users_with_roles') ?? [];
    bool exists = false;
    
    for (int i = 0; i < usersWithRoles.length; i++) {
      final data = jsonDecode(usersWithRoles[i]);
      if (data['email'] == email) {
        usersWithRoles[i] = jsonEncode({'email': email, 'role': role});
        exists = true;
        break;
      }
    }
    
    if (!exists) {
      usersWithRoles.add(jsonEncode({'email': email, 'role': role}));
    }
    
    await prefs.setStringList('users_with_roles', usersWithRoles);
    
    notifyListeners();
    print('User saved successfully');
    return true;
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
        final prefs = await SharedPreferences.getInstance();
        final usersWithRoles = prefs.getStringList('users_with_roles') ?? [];
        
        String role = 'customer';
        for (var jsonStr in usersWithRoles) {
          final data = jsonDecode(jsonStr);
          if (data['email'] == email) {
            role = data['role'];
            break;
          }
        }
        
        _currentUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: firebaseUser.email ?? email,
          phone: firebaseUser.phoneNumber ?? '',
          role: role,
        );
        
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
        
        List<String> usersWithRoles = prefs.getStringList('users_with_roles') ?? [];
        usersWithRoles.add(jsonEncode({'email': email, 'role': 'customer'}));
        await prefs.setStringList('users_with_roles', usersWithRoles);
        
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