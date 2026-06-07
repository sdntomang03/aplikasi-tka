import 'dart:convert';
import '../core/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicExamService {
  final ApiClient _apiClient = ApiClient();

  // Token sesi ujian yang sedang berjalan
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
      final response = await _apiClient.get('/public/exams?page=$page');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true)
        return data['data']['exams'];
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getVerificationCode(String examId) async {
    try {
      final response = await _apiClient.get('/public/exams/$examId/verify');
      final data = jsonDecode(response.body);

      // Jika sukses (Status 200)
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'verification_code': data['data']['verification_code'],
        };
      }

      // Jika gagal karena aturan backend (Status 401 Unauthorized atau 403 Forbidden)
      // Akan menangkap pesan spesifik seperti "Ujian ini khusus member Premium..."
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal mendapatkan kode verifikasi.',
      };
    } catch (e) {
      // Jika terjadi error jaringan atau server mati
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
          // WAJIB: Simpan Session Token agar ExamRunnerScreen diizinkan mengambil soal oleh Laravel
          if (data['data'] != null && data['data']['session_token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'session_token',
              data['data']['session_token'],
            );
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
      // 1. Ambil token yang sudah disimpan saat verifikasi tadi
      final prefs = await SharedPreferences.getInstance();
      final String? sessionToken = prefs.getString('session_token');

      if (sessionToken == null) {
        return {'SERVER_ERROR': 'Token sesi hilang. Silakan verifikasi ulang.'};
      }

      // 2. Kirim token ke API
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
      final response = await _apiClient.post('/public/exams/$examId/answer', {
        'session_token': currentSessionToken,
        'question_id': questionId,
        'answer': answer,
        'is_doubtful': isDoubtful,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> recordViolation(String examId) async {
    try {
      await _apiClient.post('/public/exams/$examId/violation', {
        'session_token': currentSessionToken,
      });
    } catch (e) {
      print('recordViolation Exception: $e');
    }
  }

  // PERBAIKAN: Tangkap data nilai yang dikirim dari Laravel
  Future<Map<String, dynamic>?> finishExam(
    String examId,
    Map<String, dynamic> finalAnswers,
  ) async {
    try {
      final response = await _apiClient.post('/public/exams/$examId/finish', {
        'session_token': currentSessionToken,
        'final_answers': finalAnswers,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Mengembalikan data skor jika ada
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
      // PASTIKAN BARIS INI TEPAT SEPERTI INI:
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
