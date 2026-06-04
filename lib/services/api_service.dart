import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.0.108:8080/fixit_api';
  
  // ==================== UNTUK BYPASS (SEMENTARA) ====================
  
  static Future<Map<String, dynamic>> saveUser({
    required String email,
    required String name,
    required String role,
  }) async {
    // BYPASS: langsung return success
    print('Save user: $email, $name, $role');
    return {
      'success': true,
      'user': {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'email': email,
        'role': role,
      }
    };
  }
  
  static Future<Map<String, dynamic>> getUser(String email) async {
    // BYPASS: return user not found
    print('Get user: $email');
    return {'success': false, 'message': 'User not found'};
  }
  
  // ==================== UNTUK KONEKSI KE SERVER ASLI (NANTI) ====================
  
  /*
  // Save user ke server
  static Future<Map<String, dynamic>> saveUserToServer({
    required String email,
    required String name,
    required String role,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/save_user.php');
      final response = await http.post(
        url,
        body: {
          'email': email,
          'name': name,
          'role': role,
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Get user dari server
  static Future<Map<String, dynamic>> getUserFromServer(String email) async {
    try {
      final url = Uri.parse('$baseUrl/get_user.php?email=$email');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  */
}