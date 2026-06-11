import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/database_helper.dart';
// Ganti import home_screen di bawah ini sesuai jalur file Anda
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _downloadInitialData();
  }

  Future<void> _downloadInitialData() async {
    try {
      // 1. Download & Simpan Semua Modul
      final moduleRes = await _apiClient.get('/modules');
      if (moduleRes.statusCode == 200) {
        await DatabaseHelper.instance.saveCache('modules_list', moduleRes.body);
      }

      // 2. Download & Simpan Daftar Ujian (Halaman 1)
      final examRes = await _apiClient.get('/public/exams?page=1');
      if (examRes.statusCode == 200) {
        await DatabaseHelper.instance.saveCache('exams_page_1', examRes.body);
      }
    } catch (e) {
      // Jika internet HP mati, abaikan error (aplikasi akan menggunakan data lama)
      debugPrint("Offline mode, melewati sinkronisasi.");
    }

    // Jeda sejenak agar animasi loading terlihat natural, lalu masuk ke Home
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ), // Pastikan nama class Home Anda benar
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF4338CA), // Warna Biru Indigo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 80, color: Colors.white),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Menyiapkan Materi Ujian...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
