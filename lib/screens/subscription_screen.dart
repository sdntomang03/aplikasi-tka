import 'dart:ui';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Secara default, pilih paket tengah (yang paling menguntungkan)
  int _selectedPlanIndex = 1;

  final List<Map<String, dynamic>> _plans = [
    {
      "title": "1 Bulan",
      "price": "Rp 25.000",
      "original_price": "",
      "save_text": "",
      "duration": "/ bulan",
      "is_popular": false,
    },
    {
      "title": "6 Bulan",
      "price": "Rp 120.000",
      "original_price": "Rp 150.000",
      "save_text": "Hemat 20%",
      "duration": "/ 6 bln",
      "is_popular": true, // Ini yang akan kita tonjolkan
    },
    {
      "title": "Seumur Hidup",
      "price": "Rp 250.000",
      "original_price": "",
      "save_text": "Sekali Bayar",
      "duration": "/ selamanya",
      "is_popular": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ==========================================
          // 1. BACKGROUND DEKORATIF (EFEK GLOWING)
          // ==========================================
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4AF37).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4338CA).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ==========================================
          // 2. KONTEN UTAMA SCROLLABLE
          // ==========================================
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tombol Kembali
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Header Icon & Title
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFDF00),
                                      Color(0xFFD4AF37),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withOpacity(0.4),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Buka Semua Akses PRO",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Investasi terbaik untuk meraih nilai\ntertinggi di ujian sekolahmu.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // List Keunggulan
                        const Text(
                          "Keunggulan Member PRO:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(
                          "Akses tak terbatas ke semua soal latihan",
                        ),
                        _buildFeatureItem(
                          "Pembahasan soal detail & komprehensif",
                        ),
                        _buildFeatureItem(
                          "Materi pelajaran lengkap (Matematika & B.Indo)",
                        ),
                        _buildFeatureItem("Tanpa iklan & gangguan sama sekali"),
                        _buildFeatureItem(
                          "Prioritas di Papan Peringkat Nasional",
                        ),

                        const SizedBox(height: 40),

                        // Pilihan Paket
                        const Text(
                          "Pilih Paket Belajarmu:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Render daftar paket secara dinamis
                        ...List.generate(_plans.length, (index) {
                          return _buildPlanCard(index, _plans[index]);
                        }),

                        const SizedBox(
                          height: 120,
                        ), // Spasi ekstra untuk tombol bottom
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. BOTTOM STICKY BUTTON (CALL TO ACTION)
          // ==========================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFF1F5F9).withOpacity(0.5),
                      ),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Arahkan ke Payment Gateway (Midtrans/Xendit)
                      final selectedPlan = _plans[_selectedPlanIndex];
                      _showProcessingPayment(context, selectedPlan);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF1E1E24,
                      ), // Warna Premium Dark
                      foregroundColor: const Color(
                        0xFFFFDF00,
                      ), // Warna Teks Emas
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10,
                      shadowColor: const Color(0xFF1E1E24).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lanjutkan Pembayaran",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk List Keunggulan
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Kartu Paket (Animasi transisi saat diklik)
  Widget _buildPlanCard(int index, Map<String, dynamic> plan) {
    bool isSelected = _selectedPlanIndex == index;
    bool isPopular = plan['is_popular'];

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio Button Custom
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFCBD5E1),
                      width: isSelected ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Detail Paket
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? const Color(0xFFB45309)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plan['price'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              plan['duration'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Tampilkan harga coret jika ada diskon
                      if (plan['original_price'] != "") ...[
                        const SizedBox(height: 4),
                        Text(
                          plan['original_price'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Badge "PALING LARIS" (Pita di pojok kanan atas)
            if (isPopular)
              Positioned(
                top: -32,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "🔥 PALING LARIS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Badge "Hemat" di dalam card
            if (plan['save_text'] != "")
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan['save_text'],
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Efek Loading Pembayaran (Mockup)
  // Efek Loading Pembayaran (Mockup)
  void _showProcessingPayment(
    BuildContext context,
    Map<String, dynamic> selectedPlan,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        // <-- Hapus const di sini
        child: Container(
          padding: const EdgeInsets.all(32), // <-- Pindahkan const ke sini
          decoration: const BoxDecoration(
            // <-- Pindahkan const ke sini
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            color: Color(0xFFD4AF37),
          ), // <-- Pindahkan const ke sini
        ),
      ),
    );

    // Simulasi loading 2 detik lalu tutup
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Mengarahkan ke pembayaran paket ${selectedPlan['title']}...",
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    });
  }
}
