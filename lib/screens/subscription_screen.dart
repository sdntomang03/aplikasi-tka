import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../services/auth_service.dart'; // Dibutuhkan untuk fungsi Logout
import 'login_screen.dart'; // Pastikan path ini sesuai dengan file login Anda
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 1;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // State untuk mengontrol tampilan layar
  bool _isLoadingStatus = true;
  bool _isPremium = false;
  String? _premiumUntil;
  List<Map<String, dynamic>> _pendingTransactions = [];

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
      "is_popular": true,
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
  void initState() {
    super.initState();
    _initDeepLinkListener();
    _fetchSubscriptionStatus(); // Cek status saat halaman dibuka
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  // ==========================================
  // 1. FUNGSI CEK STATUS (API)
  // ==========================================
  Future<void> _fetchSubscriptionStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final response = await ApiClient().get('/subscription/status');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 🔥 TAMBAHAN: Simpan status terbaru ke memori HP
        bool isPremiumFromServer = data['is_premium'] ?? false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium', isPremiumFromServer);

        setState(() {
          _isPremium = isPremiumFromServer;
          _premiumUntil = data['premium_until'];
          _pendingTransactions = List<Map<String, dynamic>>.from(
            data['pending_transactions'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat status langganan: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  // ==========================================
  // 2. FUNGSI BATALKAN TAGIHAN (API)
  // ==========================================
  Future<void> _cancelTransaction(String orderId) async {
    // Tampilkan loading kecil
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient().post(
        '/subscription/cancel/$orderId',
        {},
      );
      if (mounted) Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tagihan berhasil dihapus/dibatalkan.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchSubscriptionStatus(); // Refresh ulang tampilan
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membatalkan tagihan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error jaringan saat membatalkan.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==========================================
  // PENGINTAI DEEP LINK
  // ==========================================
  void _initDeepLinkListener() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'sahabatkreasianak') {
        if (uri.toString().contains('success') ||
            uri.toString().contains('settlement')) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          String orderId = uri.queryParameters['order_id'] ?? '-';
          _showSuccessDialog(orderId);
        } else if (uri.toString().contains('unfinish') ||
            uri.toString().contains('error')) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pembayaran belum diselesaikan atau telah dibatalkan.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          _fetchSubscriptionStatus(); // Refresh jika dibatalkan dari midtrans
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    // CABANG 1: JIKA SUDAH PREMIUM
    if (_isPremium) {
      return _buildPremiumActiveView();
    }

    // CABANG 2: JIKA ADA TAGIHAN MENGGANTUNG
    if (_pendingTransactions.isNotEmpty) {
      return _buildPendingTransactionsView();
    }

    // CABANG 3: JIKA NORMAL (BELUM PREMIUM & TIDAK ADA TAGIHAN)
    return _buildSubscriptionPlansView();
  }

  // ==========================================
  // TAMPILAN 1: SUDAH PREMIUM (AKTIF)
  // ==========================================
  Widget _buildPremiumActiveView() {
    // Format tanggal sederhana
    String untilText = "Seumur Hidup";
    if (_premiumUntil != null) {
      DateTime dt = DateTime.parse(_premiumUntil!).toLocal();
      untilText = "${dt.day}-${dt.month}-${dt.year}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Status PRO Aktif!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Akun Anda sudah memiliki akses premium.\nBerlaku sampai: $untilText",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  "Selamat! Akun Anda kini memiliki Akses PRO. Silakan kembali ke Beranda untuk mulai belajar.", // <-- Pesan diubah
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text("Logout Sekarang"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAMPILAN 2: ADA TAGIHAN MENGGANTUNG
  // ==========================================
  Widget _buildPendingTransactionsView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Tagihan Belum Dibayar",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _pendingTransactions.length,
        itemBuilder: (context, index) {
          final trx = _pendingTransactions[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Menunggu Pembayaran",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        trx['order_id'] ?? '-',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Paket ${trx['plan_name']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Total: Rp ${trx['amount']}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Tombol Batalkan / Hapus
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _cancelTransaction(trx['order_id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Hapus Tagihan"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Lanjut Bayar
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (trx['snap_token'] != null) {
                              // Pakai URL Snap langsung (karena kita simpan tokennya)
                              final snapUrl =
                                  "https://app.sandbox.midtrans.com/snap/v3/redirection/${trx['snap_token']}";
                              if (await canLaunchUrl(Uri.parse(snapUrl))) {
                                await launchUrl(
                                  Uri.parse(snapUrl),
                                  mode: LaunchMode.externalApplication,
                                );
                                if (mounted) _buildPaymentInstruction(context);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'URL Pembayaran tidak ditemukan.',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Bayar Sekarang"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // TAMPILAN 3: LAYAR PEMILIHAN PAKET (NORMAL)
  // ==========================================
  Widget _buildSubscriptionPlansView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Glow Dekoratif
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

          // Area Konten Utama
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
                        const Text(
                          "Pilih Paket Belajarmu:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_plans.length, (index) {
                          return _buildPlanCard(index, _plans[index]);
                        }),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tombol Sticky Bottom (Call To Action)
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
                      final selectedPlan = _plans[_selectedPlanIndex];
                      _showProcessingPayment(context, selectedPlan);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E24),
                      foregroundColor: const Color(0xFFFFDF00),
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

  // ==========================================
  // LOGIKA HIT API & PROSES PEMBAYARAN BARU
  // ==========================================
  Future<void> _showProcessingPayment(
    BuildContext context,
    Map<String, dynamic> selectedPlan,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      ),
    );

    try {
      String cleanPrice = selectedPlan['price'].replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final response = await ApiClient().post('/subscription/checkout', {
        'plan_name': selectedPlan['title'],
        'amount': int.parse(cleanPrice),
      });

      if (context.mounted) Navigator.pop(context); // Tutup Loading Ring

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['redirect_url'] != null) {
          final Uri url = Uri.parse(data['redirect_url']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            if (context.mounted) _buildPaymentInstruction(context);
          }
        }
      } else {
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gagal memproses. Coba lagi."),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _buildPaymentInstruction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Menunggu Pembayaran ⏳'),
        content: const Text(
          'Silakan tuntaskan proses transaksi pada jendela browser yang baru saja muncul di HP Anda.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fetchSubscriptionStatus(); // Refresh layar setelah modal ditutup
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pembayaran Berhasil! 🎉',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terima kasih. Berkas transaksi Anda sudah sukses diverifikasi oleh sistem.',
            ),
            const SizedBox(height: 12),
            Text(
              'ID Transaksi: $orderId',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Silakan muat ulang (Restart) aplikasi Anda untuk memperbarui hak akses premium.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Kembali ke Beranda',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
