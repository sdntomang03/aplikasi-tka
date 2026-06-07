import 'dart:convert';
import '../core/api_client.dart';

class ExamService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getExams() async {
    try {
      // Menggunakan rute ujian internal siswa
      final response = await _apiClient.get('/student/exams');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
