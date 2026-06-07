import 'package:flutter/material.dart';
import '../services/public_exam_service.dart';

class RankingScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const RankingScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final PublicExamService _examService = PublicExamService();
  List<dynamic> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  Future<void> _fetchRankings() async {
    setState(() => _isLoading = true);
    final data = await _examService.getRanking(widget.examId);
    setState(() {
      _rankings = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Indigo yang Melengkung
          SliverAppBar(
            expandedHeight: 220, // Sedikit ditinggikan agar lebih lega
            pinned: true,
            backgroundColor: const Color(0xFF4338CA),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "Leaderboard Nasional",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran dekorasi di background
                    Positioned(
                      right: -50,
                      top: -50,
                      child: CircleAvatar(
                        radius: 130,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    // Ikon Piala Besar
                    const Opacity(
                      opacity: 0.15,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 180,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Judul Ujian
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "🏆 TOP 100",
                      style: TextStyle(
                        color: Color(0xFF4338CA),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.examTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Daftar Peserta dengan Nilai Tertinggi",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Ranking
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  ),
                )
              : _rankings.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Belum ada data ranking",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _rankings[index];
                    // Mengirim index untuk efek delay animasi yang berurutan (Staggered Effect)
                    return _buildAnimatedRankingItem(index + 1, item, index);
                  }, childCount: _rankings.length),
                ),
        ],
      ),
    );
  }

  // ==============================================================
  // WIDGET ANIMASI: Membuat list muncul berurutan dari bawah ke atas
  // ==============================================================
  Widget _buildAnimatedRankingItem(int rank, dynamic data, int index) {
    // Delay animasi berdasarkan urutan (hanya untuk 10 teratas agar tidak berat)
    final delay = index < 10 ? index * 100 : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      // Menambahkan delay sebelum animasi dimulai
      builder: (context, value, child) {
        // Jika belum waktunya muncul (menunggu delay), sembunyikan
        if (value == 0.0) return const SizedBox.shrink();

        return Transform.translate(
          offset: Offset(
            0,
            50 * (1 - value),
          ), // Efek meluncur dari bawah (Slide Up)
          child: Opacity(
            opacity: value, // Efek memudar masuk (Fade In)
            child: child,
          ),
        );
      },
      child: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delay)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 90,
            ); // Placeholder ruang kosong selama delay
          }
          return _buildPremiumCard(rank, data);
        },
      ),
    );
  }

  // ==============================================================
  // WIDGET KARTU PREMIUM: Desain Khusus Juara 1, 2, dan 3
  // ==============================================================
  Widget _buildPremiumCard(int rank, dynamic data) {
    bool isTopThree = rank <= 3;
    bool isFirst = rank == 1;

    // Pengaturan Gaya berdasarkan Peringkat
    List<Color> gradientColors;
    Color glowColor;
    IconData? rankIcon;
    Color scoreColor;

    if (rank == 1) {
      gradientColors = [
        const Color(0xFFFFDF00),
        const Color(0xFFD4AF37),
      ]; // EMAS
      glowColor = const Color(0xFFFFDF00).withOpacity(0.4);
      rankIcon = Icons.workspace_premium_rounded;
      scoreColor = const Color(0xFFB8860B);
    } else if (rank == 2) {
      gradientColors = [
        const Color(0xFFE2E8F0),
        const Color(0xFF94A3B8),
      ]; // PERAK
      glowColor = const Color(0xFF94A3B8).withOpacity(0.3);
      rankIcon = Icons.military_tech_rounded;
      scoreColor = const Color(0xFF475569);
    } else if (rank == 3) {
      gradientColors = [
        const Color(0xFFFDBA74),
        const Color(0xFFC2410C),
      ]; // PERUNGGU
      glowColor = const Color(0xFFFDBA74).withOpacity(0.3);
      rankIcon = Icons.military_tech_rounded;
      scoreColor = const Color(0xFF9A3412);
    } else {
      gradientColors = [Colors.white, Colors.white]; // BIASA
      glowColor = Colors.black.withOpacity(0.04);
      rankIcon = null;
      scoreColor = const Color(0xFF4338CA);
    }

    return Container(
      // Juara 1 dibuat sedikit lebih besar dan berjarak
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: isFirst ? 12 : 8),
      padding: EdgeInsets.all(isFirst ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopThree
              ? gradientColors[1].withOpacity(0.5)
              : Colors.transparent,
          width: isFirst ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: isTopThree ? 15 : 10,
            spreadRadius: isFirst ? 2 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // ========================
          // BULATAN ANGKA / PIALA
          // ========================
          Container(
            width: isFirst ? 55 : 45,
            height: isFirst ? 55 : 45,
            decoration: BoxDecoration(
              gradient: isTopThree
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isTopThree ? null : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              boxShadow: isTopThree
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isTopThree
                  ? Icon(rankIcon, color: Colors.white, size: isFirst ? 32 : 26)
                  : Text(
                      rank.toString(),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // ========================
          // NAMA & SEKOLAH
          // ========================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data['nama_peserta'],
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isFirst ? 18 : 16,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  data['asal_sekolah'] ?? "Umum",
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: isFirst ? 14 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ========================
          // SKOR
          // ========================
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isFirst ? 16 : 12,
              vertical: isFirst ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: isTopThree
                  ? gradientColors[0].withOpacity(0.15)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
              border: isTopThree
                  ? Border.all(color: gradientColors[1].withOpacity(0.3))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['score'].toString(),
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 18 : 16,
                  ),
                ),
                Text(
                  "POIN",
                  style: TextStyle(
                    color: scoreColor.withOpacity(0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
