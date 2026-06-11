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
    final cacheKey = 'module_detail_$slug';

    try {
      // 1. Coba baca dari memori HP (SQLite) terlebih dahulu agar instan
      final localData = await DatabaseHelper.instance.getCache(cacheKey);
      if (localData != null) {
        final data = jsonDecode(localData);

        // Background sync: diam-diam update data di HP jika ada internet
        _apiClient
            .get('/modules/$slug')
            .then((res) {
              if (res.statusCode == 200) {
                DatabaseHelper.instance.saveCache(cacheKey, res.body);
              }
            })
            .catchError((_) {}); // Abaikan error jika offline

        return data['data'] as Map<String, dynamic>;
      }

      // 2. Jika tidak ada di HP, ambil dari server
      final response = await _apiClient.get('/modules/$slug');

      if (response.statusCode == 200) {
        // Simpan ke HP untuk dibuka offline besok
        await DatabaseHelper.instance.saveCache(cacheKey, response.body);
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return {
          'is_locked': true,
          'message': data['message'] ?? 'Akses ditolak.',
          'module': data['data'],
        };
      }
      return null;
    } catch (e) {
      // 3. JIKA INTERNET MATI / API ERROR, paksa buka dari HP
      final localData = await DatabaseHelper.instance.getCache(cacheKey);
      if (localData != null) {
        final data = jsonDecode(localData);
        return data['data'] as Map<String, dynamic>;
      }
      print("❌ Error fetching module detail & no cache: $e");
      return null;
    }
  }
}
