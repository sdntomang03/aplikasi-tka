import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/public_exam_service.dart';
import 'exam_verify_screen.dart';
import 'all_exams_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';
import 'all_modules_screen.dart';

// ============================================================
// SUBTLE SHIMMER PAINTER (hanya untuk header premium)
// ============================================================
class _HeaderShimmerPainter extends CustomPainter {
  final double progress;
  _HeaderShimmerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width + (size.width * 2.5 * progress);
    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.3),
        Colors.white.withOpacity(0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(x, 0, size.width * 1.2, size.height),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_HeaderShimmerPainter old) => old.progress != progress;
}

// ============================================================
// MAIN SCREEN
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PublicExamService _publicExamService = PublicExamService();
  final AuthService _authService = AuthService();

  List<dynamic> _publicExams = [];
  bool _isLoading = true;

  String _namaUser = "Pelajar";
  int _totalPoin = 0;
  bool _isUserPremium = false;

  late AnimationController _shimmerController;
  late AnimationController _fadeInController;
  late Animation<double> _fadeInAnim;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeInAnim = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeOut,
    );

    _fetchDashboardData();
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaUser = prefs.getString('nama_peserta') ?? "Pelajar";
      _totalPoin = prefs.getInt('total_poin') ?? 0;
      _isUserPremium = prefs.getBool('is_premium') ?? false;
    });

    if (!_isUserPremium) {
      final String? lastPromoString = prefs.getString('last_promo_time');
      DateTime? lastPromoTime;

      if (lastPromoString != null) {
        lastPromoTime = DateTime.tryParse(lastPromoString);
      }

      final DateTime now = DateTime.now();

      if (lastPromoTime == null || now.difference(lastPromoTime).inHours >= 1) {
        await prefs.setString('last_promo_time', now.toIso8601String());

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPromotionalModal(context);
        });
      }
    }
  }

  void _showPromotionalModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                Icons.rocket_launch_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Tingkatkan Potensimu! 🚀",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Jangan biarkan belajarmu terhambat! Gabung dengan ribuan siswa VIP lainnya dan dapatkan akses tak terbatas ke ratusan soal rahasia, pembahasan super lengkap, serta prioritas di ranking nasional.\n\nMulai investasi pendidikanmu hari ini!",
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionScreen(),
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
                  "Lihat Penawaran PRO",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Mungkin Nanti",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    await _loadUserData();

    List<dynamic> exams = await _publicExamService.getPublicExams();

    exams.sort((a, b) {
      bool isAPremium = a['is_premium'] == true || a['is_premium'] == 1;
      bool isBPremium = b['is_premium'] == true || b['is_premium'] == 1;

      if (isAPremium && !isBPremium)
        return -1;
      else if (!isAPremium && isBPremium)
        return 1;
      return 0;
    });

    setState(() {
      _publicExams = exams;
      _isLoading = false;
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // ---- Design tokens (Light Luxury Theme) ----
  static const Color _premiumBg = Color(0xFFFAFAFA);
  static const Color _premiumSurface = Colors.white;
  static const Color _premiumGold = Color(0xFFD97706);
  static const Color _premiumText = Color(0xFF0F172A);

  static const Color _freeBg = Color(0xFFF6F7F9);
  static const Color _freeAccent = Color(0xFF4F46E5);
  static const Color _freeText = Color(0xFF111827);
  static const Color _freeTextSub = Color(
    0xFF64748B,
  ); // <--- TAMBAHKAN BARIS INI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isUserPremium ? _premiumBg : _freeBg,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _isUserPremium ? _premiumGold : _freeAccent,
          backgroundColor: _isUserPremium ? _premiumSurface : Colors.white,
          onRefresh: _fetchDashboardData,
          child: FadeTransition(
            opacity: _fadeInAnim,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildMenuGrid(),
                  const SizedBox(height: 32),
                  _buildExamSection(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER
  // ========================================================
  Widget _buildHeader() {
    return _isUserPremium ? _buildPremiumHeader() : _buildFreeHeader();
  }

  Widget _buildPremiumHeader() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
          decoration: BoxDecoration(
            // Gradasi Emas Bercahaya
            gradient: const LinearGradient(
              colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: CustomPaint(
                    painter: _HeaderShimmerPainter(_shimmerController.value),
                  ),
                ),
              ),
              // Ambient glow - Cahaya Putih Lembut
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Premium badge — White & Gold
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFD97706),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'VIP MEMBER',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.power_settings_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Greeting
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _namaUser,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Akses penuh ke seluruh materi & latihan.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Points row — Clean White Glassmorphism
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Poin Belajar',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_totalPoin',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'pts',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFreeHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x404F46E5),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Program TKA SD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Halo, $_namaUser! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Siap belajar hari ini?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // MENU GRID
  // ========================================================
  Widget _buildMenuGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Menu Belajar'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
            children: [
              _MenuCard(
                icon: Icons.calculate_rounded,
                color: const Color(0xFF3B82F6),
                title: 'Materi\nMTK',
                isPremium: _isUserPremium,
                onTap: () =>
                    _showDummyMessage('Materi Matematika belum tersedia'),
              ),
              _MenuCard(
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF10B981),
                title: 'Materi\nB. Indo',
                isPremium: _isUserPremium,
                onTap: () =>
                    _showDummyMessage('Materi B. Indonesia belum tersedia'),
              ),
              _MenuCard(
                icon: Icons.quiz_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Latihan\nMTK',
                isPremium: _isUserPremium,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AllExamsScreen(subjectFilter: 'Matematika'),
                    ),
                  );
                },
              ),
              _MenuCard(
                icon: Icons.assignment_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Latihan\nB. Indo',
                isPremium: _isUserPremium,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllExamsScreen(
                        subjectFilter: 'Bahasa Indonesia',
                      ),
                    ),
                  );
                },
              ),
              _MenuCard(
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF10B981),
                title: 'Katalog\nModul',
                isPremium: _isUserPremium,
                onTap: () {
                  // Arahkan ke Halaman Modul
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllModulesScreen()),
                  );
                },
              ),
              _MenuCard(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFF43F5E),
                title: 'Ranking\nNasional',
                isPremium: _isUserPremium,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllExamsScreen(isRankingMode: true),
                    ),
                  );
                },
              ),
              _MenuCard(
                icon: Icons.person_rounded,
                color: const Color(0xFF0EA5E9),
                title: 'Profil\nSaya',
                isPremium: _isUserPremium,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                  _loadUserData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // EXAM SECTION
  // ========================================================
  Widget _buildExamSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionLabel('Latihan Terbaru'),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllExamsScreen()),
                  );
                },
                child: Text(
                  'Lihat semua',
                  style: TextStyle(
                    color: _isUserPremium ? _premiumGold : _freeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _isUserPremium ? _premiumGold : _freeAccent,
                  ),
                ),
              ),
            )
          else if (_publicExams.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _publicExams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final exam = _publicExams[index];
                final subjectName = exam['subject'] != null
                    ? exam['subject']['name']
                    : 'Umum';
                return _buildExamCard(exam, subjectName);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: _isUserPremium ? _premiumText : _freeText,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildExamCard(dynamic exam, String subjectName) {
    final isExamPremium = exam['is_premium'] == true || exam['is_premium'] == 1;

    void onCardTap() {
      if (isExamPremium && !_isUserPremium) {
        _showPremiumPaywall(context);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamVerifyScreen(
            examId: (exam['hashid'] ?? exam['slug'] ?? exam['id']).toString(),
            examTitle: exam['title'] ?? 'Ujian',
          ),
        ),
      );
    }

    if (_isUserPremium) {
      return _PremiumExamCard(
        exam: exam,
        subjectName: subjectName,
        isExamPremium: isExamPremium,
        onTap: onCardTap,
      );
    }

    return _FreeExamCard(
      exam: exam,
      subjectName: subjectName,
      isExamPremium: isExamPremium,
      onTap: onCardTap,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isUserPremium
              ? const Color(0xFFFDE68A)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: _isUserPremium
                ? const Color(0xFFD97706).withOpacity(0.4)
                : const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada latihan tersedia',
            style: TextStyle(
              color: _isUserPremium ? const Color(0xFF92400E) : _freeTextSub,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumPaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFDF00), Color(0xFFD4AF37)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Akses Terkunci',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Latihan ini eksklusif hanya untuk member Premium. Tingkatkan akunmu sekarang untuk membuka semua materi dan soal rahasia!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Nanti Saja',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Dapatkan Akses PRO',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showDummyMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ============================================================
// PREMIUM EXAM CARD (White & Gold Theme)
// ============================================================
class _PremiumExamCard extends StatefulWidget {
  final dynamic exam;
  final String subjectName;
  final bool isExamPremium;
  final VoidCallback onTap;
  const _PremiumExamCard({
    required this.exam,
    required this.subjectName,
    required this.isExamPremium,
    required this.onTap,
  });
  @override
  State<_PremiumExamCard> createState() => _PremiumExamCardState();
}

class _PremiumExamCardState extends State<_PremiumExamCard> {
  bool _hovered = false;

  static const Color _bg = Colors.white;
  static const Color _bgHover = Color(0xFFFFFBEB);
  static const Color _gold = Color(0xFFD97706);
  static const Color _goldLight = Color(0xFFF59E0B);
  static const Color _text = Color(0xFF0F172A);
  static const Color _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_hovered ? 0.975 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? _bgHover : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isExamPremium
                ? _gold.withOpacity(0.3)
                : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isExamPremium
                  ? _gold.withOpacity(0.08)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.isExamPremium
                    ? const Color(0xFFFFFBEB)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.isExamPremium
                    ? Icons.workspace_premium_rounded
                    : Icons.edit_note_rounded,
                color: widget.isExamPremium ? _gold : _sub,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.subjectName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _sub,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (widget.isExamPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _goldLight.withOpacity(0.5),
                            ),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.exam['title'] ?? 'Latihan Tanpa Judul',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _text,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.exam['duration_minutes']} menit',
                    style: const TextStyle(
                      color: _sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _sub.withOpacity(0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FREE EXAM CARD
// ============================================================
class _FreeExamCard extends StatefulWidget {
  final dynamic exam;
  final String subjectName;
  final bool isExamPremium;
  final VoidCallback onTap;
  const _FreeExamCard({
    required this.exam,
    required this.subjectName,
    required this.isExamPremium,
    required this.onTap,
  });
  @override
  State<_FreeExamCard> createState() => _FreeExamCardState();
}

class _FreeExamCardState extends State<_FreeExamCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_pressed ? 0.975 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isExamPremium
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.isExamPremium
                    ? Icons.lock_rounded
                    : Icons.edit_note_rounded,
                color: widget.isExamPremium
                    ? const Color(0xFFD97706)
                    : const Color(0xFF6366F1),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.subjectName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (widget.isExamPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.exam['title'] ?? 'Latihan Tanpa Judul',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.exam['duration_minutes']} menit',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              widget.isExamPremium
                  ? Icons.lock_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: widget.isExamPremium
                  ? const Color(0xFFD97706)
                  : const Color(0xFFD1D5DB),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MENU CARD
// ============================================================
class _MenuCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool isPremium;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.isPremium,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  static const Color _premiumBg = Colors.white;
  static const Color _premiumBgPress = Color(0xFFFFFBEB);
  static const Color _premiumText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.isPremium;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_pressed ? 0.94 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPremium
              ? (_pressed ? _premiumBgPress : _premiumBg)
              : (_pressed ? const Color(0xFFF3F4F6) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPremium
                ? const Color(0xFFFDE68A)
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isPremium
              ? [
                  BoxShadow(
                    color: const Color(0xFFD97706).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPremium
                    ? widget.color.withOpacity(0.12)
                    : widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.icon,
                color: isPremium ? widget.color.withOpacity(0.9) : widget.color,
                size: 26,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isPremium ? _premiumText : const Color(0xFF374151),
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BACKWARD-COMPAT ALIAS (agar tidak break import lain jika ada)
// ============================================================
typedef AnimatedMenuCard = _MenuCard;
