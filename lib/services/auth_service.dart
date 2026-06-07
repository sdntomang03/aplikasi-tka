import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  // ==========================================
  // 1. FUNGSI LOGIN
  // ==========================================
  Future<bool> login(String loginId, String password) async {
    try {
      final response = await _apiClient.post('/login', {
        'login_id': loginId,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Tangkap Token dan Data User dari JSON
          final token = data['data']['access_token'];
          final user = data['data']['user'];

          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setString('nama_peserta', user['name'] ?? 'Pelajar');
          await prefs.setString('email', user['email'] ?? '-');

          // Tangkap status premium (pastikan menjadi boolean)
          await prefs.setBool('is_premium', user['is_premium'] == true);

          // Tangkap total poin (karena di JSON belum ada, kita beri default 0)
          await prefs.setInt('total_poin', user['total_poin'] ?? 0);

          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }

  // ==========================================
  // 2. FUNGSI REGISTER
  // ==========================================
  Future<bool> register({
    required String name,
    required String email,
    required String username,
    required String school,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.post('/register', {
        'name': name,
        'email': email,
        'username': username,
        'sekolah': school,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Tangkap Token dan Data User dari response Register
          final token = data['data']['access_token'];
          final user = data['data']['user'];

          // Simpan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          await prefs.setString('nama_peserta', user['name'] ?? 'Pelajar');
          await prefs.setString('email', user['email'] ?? '-');

          // Tangkap status premium
          await prefs.setBool('is_premium', user['is_premium'] == true);

          // Tangkap total poin
          await prefs.setInt('total_poin', user['total_poin'] ?? 0);

          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error Register: $e");
      return false;
    }
  }

  // ==========================================
  // 3. FUNGSI LOGOUT (DIPERBARUI)
  // ==========================================
  Future<void> logout() async {
    try {
      await _apiClient.post('/logout', {});
    } catch (e) {
      // Abaikan error jaringan saat logout, tetap hapus memori lokal
      print("Logout API error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    // SAPU BERSIH SEMUA DATA! Ini akan mencegah status premium terbawa ke user lain
    await prefs.clear();
  }

  // ==========================================
  // 4. CEK STATUS LOGIN
  // ==========================================
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  // ==========================================
  // 5. UPDATE PROFIL
  // ==========================================
  Future<bool> updateProfile(String nama, String sekolah) async {
    try {
      final response = await _apiClient.post('/profile/update', {
        'nama_peserta': nama,
        'asal_sekolah': sekolah,
      });

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      print("Error Update Profile: $e");
      return false;
    }
  }

  // ==========================================
  // 6. UPDATE PASSWORD
  // ==========================================
  Future<Map<String, dynamic>> updatePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await _apiClient.post('/profile/password', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Terjadi kesalahan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server'};
    }
  }
}
