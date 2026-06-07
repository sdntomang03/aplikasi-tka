import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';

class ModuleService {
  final ApiClient _apiClient = ApiClient();

  // ==========================================
  // AMBIL DAFTAR MODUL (KATALOG)
  // ==========================================
  Future<List<dynamic>> getModules({String? search}) async {
    try {
      final String query = search != null ? '?search=$search' : '';
      final response = await _apiClient.get('/modules$query');

      print("\n=== 🔍 DEBUG API MODULES ===");
      print("Status Code : ${response.statusCode}");
      print("Body        : ${response.body}");
      print("============================\n");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['data'] != null && data['data']['data'] != null) {
          return data['data']['data'];
        } else if (data['data'] != null && data['data'] is List) {
          return data['data'];
        }

        print("⚠️ Struktur data tidak dikenali: ${data.keys}");
        return [];
      } else if (response.statusCode == 401) {
        print("❌ TOKEN EXPIRED! Silakan Logout dan Login kembali.");
      } else {
        print("❌ Status tidak ditangani: ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("❌ Error fetching modules: $e");
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
