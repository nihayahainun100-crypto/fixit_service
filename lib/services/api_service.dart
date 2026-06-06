import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // 🔥 IP (WIFI ANDA)
  static const String _ipAddress = '192.168.0.104';
  static const int _port = 80;
  static const String baseUrl = 'http://$_ipAddress/fixit_api/teknisi';
  static const String bookingUrl = 'http://$_ipAddress/fixit_api/bookings';
  static const String uploadUrl = 'http://$_ipAddress/fixit_api/uploads';
  static const String reviewUrl = 'http://$_ipAddress/fixit_api/reviews';

  // ==================== HELPER ERROR HANDLER ====================
  static Map<String, dynamic> _handleError(dynamic e, String operation) {
    String message;
    if (e is TimeoutException) {
      message = 'Koneksi timeout. Periksa jaringan Anda.';
    } else if (e is SocketException) {
      message =
          'Tidak dapat terhubung ke server. Pastikan server menyala dan IP benar.';
    } else if (e is FormatException) {
      message = 'Format data dari server tidak valid.';
    } else {
      message = 'Error pada $operation: ${e.toString()}';
    }
    print(' [$operation] $message');
    return {'success': false, 'message': message};
  }

  static Map<String, dynamic> _handleHttpError(
      int statusCode, String operation) {
    String message;
    if (statusCode == 404) {
      message = 'Endpoint API tidak ditemukan (404). Periksa URL server.';
    } else if (statusCode == 500) {
      message = 'Terjadi kesalahan di server (500). Periksa log PHP.';
    } else {
      message = 'Server merespons dengan status $statusCode.';
    }
    print(' [$operation] HTTP $statusCode: $message');
    return {'success': false, 'message': message};
  }

  // ==================== TEKNISI CRUD ====================

  /// READ – Mengambil semua data teknisi dari MySQL
  static Future<Map<String, dynamic>> getAllTeknisi() async {
    const op = 'getAllTeknisi';
    try {
      final url = Uri.parse('$baseUrl/read.php');
      print(' [$op] GET $url');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      print(' [$op] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print(
            ' [$op] Loaded ${(decoded['teknisi'] as List?)?.length ?? 0} teknisi');
        return decoded;
      }
      return _handleHttpError(response.statusCode, op)..['teknisi'] = [];
    } catch (e) {
      return _handleError(e, op)..['teknisi'] = [];
    }
  }

  /// CREATE – Menambahkan teknisi baru ke MySQL
  static Future<Map<String, dynamic>> createTeknisi(
      Map<String, dynamic> data) async {
    const op = 'createTeknisi';
    try {
      final url = Uri.parse('$baseUrl/create.php');
      print(' [$op] POST $url | Data: $data');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      print(' [$op] Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded;
      }
      return _handleHttpError(response.statusCode, op);
    } catch (e) {
      return _handleError(e, op);
    }
  }

  /// UPDATE – Memperbarui data teknisi di MySQL
  static Future<Map<String, dynamic>> updateTeknisi(
      Map<String, dynamic> data) async {
    const op = 'updateTeknisi';
    try {
      final url = Uri.parse('$baseUrl/update.php');
      print(' [$op] POST $url | Data: $data');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      print(' [$op] Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return _handleHttpError(response.statusCode, op);
    } catch (e) {
      return _handleError(e, op);
    }
  }

  /// DELETE – Menghapus teknisi dari MySQL berdasarkan ID
  static Future<Map<String, dynamic>> deleteTeknisi(int id) async {
    const op = 'deleteTeknisi';
    try {
      if (id <= 0) {
        return {'success': false, 'message': 'ID teknisi tidak valid'};
      }
      final url = Uri.parse('$baseUrl/delete.php');
      print(' [$op] POST $url | id=$id');
      final response = await http.post(
        url,
        body: jsonEncode({'id': id}),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      print(' [$op] Status: ${response.statusCode} | Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return _handleHttpError(response.statusCode, op);
    } catch (e) {
      return _handleError(e, op);
    }
  }

  // ==================== BOOKING ====================

  static Future<Map<String, dynamic>> saveBooking(
      Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$bookingUrl/create.php');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(' Save booking response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print(' Save booking error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getBookingsForTechnician(
      String technicianId) async {
    try {
      final url = Uri.parse(
          '$bookingUrl/get_by_technician.php?technician_id=$technicianId');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'bookings': []};
    } catch (e) {
      print(' Get bookings error: $e');
      return {'success': false, 'bookings': []};
    }
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
      Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$bookingUrl/update_status.php');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<void> markBookingAsRated(String bookingId) async {}

  // ==================== TEKNISI PROFILE & UPLOAD ====================

  static Future<Map<String, dynamic>> getTechnicianByEmail(String email) async {
    try {
      final url = Uri.parse('$baseUrl/get_by_email.php?email=$email');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print(' Get technician by email response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'technician': null};
    } catch (e) {
      print(' Get technician by email error: $e');
      return {'success': false, 'technician': null};
    }
  }

  static Future<Map<String, dynamic>> updateTechnicianProfile(
      Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/update_profile.php');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(' Update profile response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print(' Update profile error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadTechnicianPhoto(
      File imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$uploadUrl/upload_photo.php'));

      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print(' Upload photo response: $responseData');

      if (response.statusCode == 200) {
        return jsonDecode(responseData);
      }
      return {'success': false, 'message': 'Upload failed'};
    } catch (e) {
      print(' Upload error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createReview(
      Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$reviewUrl/create.php');
      final response = await http.post(
        url,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(' Create review response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print(' Create review error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
