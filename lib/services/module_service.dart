import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../core/database_helper.dart';

class ModuleService {
  final ApiClient _apiClient = ApiClient();

  // ==========================================
  // AMBIL DAFTAR MODUL (KATALOG)
  // ==========================================
  Future<List<dynamic>> getModules({String? search}) async {
    try {
      final String query = search != null ? '?search=$search' : '';

      // 1. Jika TIDAK sedang mencari, baca memori HP dulu agar INSTAN
      if (search == null || search.isEmpty) {
        final localData = await DatabaseHelper.instance.getCache(
          'modules_list',
        );
        if (localData != null) {
          final data = jsonDecode(localData);

          // Mengecek server secara background. Jika ada materi baru, diam-diam simpan ke HP
          _apiClient.get('/modules').then((res) {
            if (res.statusCode == 200)
              DatabaseHelper.instance.saveCache('modules_list', res.body);
          });

          return data['data']['data'] ?? data['data'] ?? [];
        }
      }

      // 2. Jika memori HP kosong, tembak API langsung
      final response = await _apiClient.get('/modules$query');
      if (response.statusCode == 200) {
        if (search == null || search.isEmpty) {
          await DatabaseHelper.instance.saveCache(
            'modules_list',
            response.body,
          );
        }
        final data = jsonDecode(response.body);
        return data['data']['data'] ?? data['data'] ?? [];
      }
      return [];
    } catch (e) {
      // 3. JIKA OFFLINE (Gagal hit API), paksa gunakan memori HP
      final localData = await DatabaseHelper.instance.getCache('modules_list');
      if (localData != null) {
        final data = jsonDecode(localData);
        return data['data']['data'] ?? data['data'] ?? [];
      }
      return [];
    }
  }

  // ==========================================
  // AMBIL DETAIL MODUL BACA
  // ==========================================
  Future<Map<String, dynamic>?> getModuleDetail(String slug) async {
    try {
      final response = await _apiClient.get('/modules/$slug');

      print("\n=== 🔍 DEBUG API MODULE DETAIL ===");
      print("Slug        : $slug");
      print("Status Code : ${response.statusCode}");
      print("Body        : ${response.body}");
      print("==================================\n");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] == null) {
          print("❌ Key 'data' tidak ditemukan dalam response!");
          return null;
        }
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'is_locked': true,
          'message': data['message'] ?? 'Akses ditolak.',
          'module': data['data'],
        };
      } else if (response.statusCode == 401) {
        print("❌ TOKEN EXPIRED! Silakan Logout dan Login kembali.");
        return null;
      } else if (response.statusCode == 404) {
        print("❌ Modul dengan slug '$slug' tidak ditemukan.");
        return null;
      }

      print("❌ Status tidak ditangani: ${response.statusCode}");
      return null;
    } catch (e) {
      print("❌ Error fetching module detail: $e");
      return null;
    }
  }
}
