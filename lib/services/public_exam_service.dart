import 'dart:convert';
import '../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database_helper.dart';

class PublicExamService {
  final ApiClient _apiClient = ApiClient();

  static String? currentSessionToken;

  Future<List<dynamic>> getPublicExams() async {
    try {
      final response = await _apiClient.get('/public/exams');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data']['exams']['data'];
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPublicExamsPaginated({int page = 1}) async {
    try {
      // 1. Ambil dari memori HP (Hanya untuk halaman 1 agar Home cepat)
      if (page == 1) {
        final localData = await DatabaseHelper.instance.getCache(
          'exams_page_1',
        );
        if (localData != null) {
          final data = jsonDecode(localData);

          // Background Sync
          _apiClient.get('/public/exams?page=1').then((res) {
            if (res.statusCode == 200)
              DatabaseHelper.instance.saveCache('exams_page_1', res.body);
          });

          return data['data']['exams'];
        }
      }

      // 2. Ambil dari Server
      final response = await _apiClient.get('/public/exams?page=$page');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (page == 1) {
          await DatabaseHelper.instance.saveCache(
            'exams_page_1',
            response.body,
          );
        }
        return data['data']['exams'];
      }
      return null;
    } catch (e) {
      // 3. JIKA OFFLINE, paksa gunakan memori HP
      if (page == 1) {
        final localData = await DatabaseHelper.instance.getCache(
          'exams_page_1',
        );
        if (localData != null) {
          final data = jsonDecode(localData);
          return data['data']['exams'];
        }
      }
      return null;
    }
  }

  Future<Map<String, dynamic>> getVerificationCode(String examId) async {
    try {
      final response = await _apiClient.get('/public/exams/$examId/verify');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'verification_code': data['data']['verification_code'],
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendapatkan kode verifikasi.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau server.',
      };
    }
  }

  Future<bool> submitVerification(
    String examId,
    String name,
    String school,
    String token,
  ) async {
    try {
      final body = {
        'nama_peserta': name,
        'asal_sekolah': school,
        'verification_code': token,
      };

      final response = await _apiClient.post(
        '/public/exams/$examId/verify',
        body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' || data['success'] == true) {
          if (data['data'] != null && data['data']['session_token'] != null) {
            final sessionToken = data['data']['session_token'] as String;

            // ✅ FIX 1: Simpan ke SharedPreferences DAN assign ke static variable
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('session_token', sessionToken);
            currentSessionToken = sessionToken; // ← TAMBAHAN INI
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print("❌ Error submit verification: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> startExam(String examId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionToken = prefs.getString('session_token');

      if (sessionToken == null) {
        return {'SERVER_ERROR': 'Token sesi hilang. Silakan verifikasi ulang.'};
      }

      // ✅ FIX 2: Selalu load ulang currentSessionToken dari SharedPreferences
      // agar submitAnswer & finishExam bisa menggunakannya
      currentSessionToken = sessionToken;

      final body = {'session_token': sessionToken};
      final response = await _apiClient.post(
        '/public/exams/$examId/start',
        body,
      );

      print("--- RESPONSE START EXAM ---");
      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'SERVER_ERROR': 'Gagal memulai ujian (Code: ${response.statusCode})',
      };
    } catch (e) {
      return {'SERVER_ERROR': 'Terjadi kesalahan: $e'};
    }
  }

  Future<bool> submitAnswer(
    String examId,
    String questionId,
    dynamic answer,
    bool isDoubtful,
  ) async {
    try {
      // ✅ FIX 3: Fallback ke SharedPreferences jika currentSessionToken null
      if (currentSessionToken == null) {
        final prefs = await SharedPreferences.getInstance();
        currentSessionToken = prefs.getString('session_token');
      }

      final response = await _apiClient.post('/public/exams/$examId/answer', {
        'session_token': currentSessionToken,
        'question_id': questionId,
        'answer': answer,
        'is_doubtful': isDoubtful,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('submitAnswer Exception: $e');
      return false;
    }
  }

  Future<void> recordViolation(String examId) async {
    try {
      // ✅ FIX 4: Fallback ke SharedPreferences
      if (currentSessionToken == null) {
        final prefs = await SharedPreferences.getInstance();
        currentSessionToken = prefs.getString('session_token');
      }

      await _apiClient.post('/public/exams/$examId/violation', {
        'session_token': currentSessionToken,
      });
    } catch (e) {
      print('recordViolation Exception: $e');
    }
  }

  Future<Map<String, dynamic>?> finishExam(
    String examId,
    Map<String, dynamic> finalAnswers,
  ) async {
    try {
      // ✅ FIX 5: Fallback ke SharedPreferences — INI PALING PENTING
      if (currentSessionToken == null) {
        final prefs = await SharedPreferences.getInstance();
        currentSessionToken = prefs.getString('session_token');
      }

      print("--- FINISH EXAM ---");
      print("Session Token: $currentSessionToken");
      print("Final Answers: $finalAnswers");

      final response = await _apiClient.post('/public/exams/$examId/finish', {
        'session_token': currentSessionToken,
        'final_answers': finalAnswers,
      });

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'] ?? {'success': true};
      }
      return null;
    } catch (e) {
      print('finishExam Exception: $e');
      return null;
    }
  }

  Future<List<dynamic>> getRanking(String examId) async {
    try {
      final response = await _apiClient.get('/public/exams/$examId/ranking');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
      return [];
    } catch (e) {
      print("Error getRanking: $e");
      return [];
    }
  }
}
