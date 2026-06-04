class IpConfig {
  // 🔥 GANTI DENGAN IP LAPTOP ANDA 🔥
  // Cara dapatkan IP:
  // Windows: buka CMD ketik 'ipconfig' cari IPv4 Address
  // Mac/Linux: buka Terminal ketik 'ifconfig' cari inet
  static String get ipAddress => '192.168.0.108';  // ← GANTI INI
  
  static String get baseUrl => 'http://$ipAddress:3000/api';
  static String get baseUrlV2 => 'http://$ipAddress:3000/api/v2';
  
  static int get port => 3000;
}