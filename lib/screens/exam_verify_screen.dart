import 'package:flutter/material.dart';
import '../services/public_exam_service.dart';
import 'exam_runner_screen.dart';
import 'subscription_screen.dart'; // <--- Import halaman subscription

class ExamVerifyScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamVerifyScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamVerifyScreen> createState() => _ExamVerifyScreenState();
}

class _ExamVerifyScreenState extends State<ExamVerifyScreen> {
  final PublicExamService _examService = PublicExamService();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _sekolahController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  String? _generatedToken;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchVerificationCode();
  }

  // ==========================================
  // DIALOG PAYWALL PREMIUM
  // ==========================================
  void _showPremiumPaywall(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // User tidak bisa menutup hanya dengan klik luar kotak
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Akses Terkunci",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Ujian ini eksklusif hanya untuk VIP Member. Tingkatkan akunmu sekarang untuk membuka soal rahasia ini!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.pop(
                      context,
                    ); // Kembali ke halaman sebelumnya (Home/All Exams)
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog paywall
                    // Arahkan ke halaman berlangganan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SubscriptionScreen(), // Ganti dengan halaman subscription Anda
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Akses PRO",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _fetchVerificationCode() async {
    // 1. CUKUP PANGGIL 1 KALI SAJA
    final result = await _examService.getVerificationCode(widget.examId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    // 2. JIKA GAGAL / ADA PESAN PREMIUM
    if (result['success'] == false) {
      String errorMessage = result['message'] ?? 'Terjadi kesalahan';

      if (errorMessage.toLowerCase().contains('premium') ||
          errorMessage.toLowerCase().contains('langganan')) {
        _showPremiumPaywall(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // 3. JIKA BERHASIL, TAMPILKAN TOKEN
    setState(() {
      // Fleksibilitas format JSON dari service Anda
      _generatedToken =
          result['verification_code'] ?? result['data']?['verification_code'];
    });
  }

  void _submitVerification() async {
    if (_namaController.text.isEmpty ||
        _sekolahController.text.isEmpty ||
        _tokenController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!')));
      return;
    }

    if (_tokenController.text.toUpperCase() != _generatedToken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak cocok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await _examService.submitVerification(
      widget.examId,
      _namaController.text,
      _sekolahController.text,
      _tokenController.text.toUpperCase(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Menuju halaman ujian dan ganti route agar tidak bisa di-back ke halaman verifikasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExamRunnerScreen(
            examId: widget.examId,
            examTitle: widget.examTitle,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi gagal. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    // Cek kecocokan token realtime untuk tombol disable/enable
    bool isTokenMatch = _tokenController.text.toUpperCase() == _generatedToken;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Verifikasi Peserta',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KOTAK INFO TOKEN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TOKEN UJIAN ANDA',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generatedToken ?? '------',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.examTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Lengkapi Data Diri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // FORM INPUT
            _buildTextField(
              label: 'Nama Lengkap',
              icon: Icons.person_rounded,
              controller: _namaController,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Asal Sekolah',
              icon: Icons.school_rounded,
              controller: _sekolahController,
              hint: 'Contoh: SDN Tomang 03',
            ),
            const SizedBox(height: 16),

            // INPUT TOKEN
            TextField(
              controller: _tokenController,
              onChanged: (val) => setState(() {}), // Update UI realtime
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Ketik Ulang Token Ujian',
                prefixIcon: const Icon(
                  Icons.key_rounded,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _tokenController.text.isEmpty
                    ? null
                    : Icon(
                        isTokenMatch
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isTokenMatch ? Colors.green : Colors.red,
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF4F46E5),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!isTokenMatch && _tokenController.text.isNotEmpty)
              const Text(
                'Token tidak cocok, periksa kembali!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 40),

            // TOMBOL SUBMIT
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (isTokenMatch && !_isSubmitting)
                    ? _submitVerification
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: isTokenMatch ? 4 : 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Mulai Mengerjakan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
        ),
      ),
    );
  }
}
