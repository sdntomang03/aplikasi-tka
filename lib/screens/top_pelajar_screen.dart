import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class TopPelajarScreen extends StatefulWidget {
  const TopPelajarScreen({super.key});

  @override
  State<TopPelajarScreen> createState() => _TopPelajarScreenState();
}

class _TopPelajarScreenState extends State<TopPelajarScreen> {
  bool _isLoading = true;
  List<dynamic> _topUsers = [];
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fetchRankingData();
  }

  Future<void> _fetchRankingData() async {
    setState(() => _isLoading = true);
    try {
      // Panggil API (Pastikan endpoint sesuai dengan route di Laravel)
      final response = await ApiClient().get('/public/exams/ranking-nasional');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _topUsers = jsonResponse['data']['top_users'] ?? [];
            _currentUserData = jsonResponse['data']['current_user'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching ranking: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Top Pelajar Nasional",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4338CA), // Tema Indigo
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4338CA)),
            )
          : RefreshIndicator(
              onRefresh: _fetchRankingData,
              color: const Color(0xFF4338CA),
              child: _topUsers.isEmpty
                  ? _buildEmptyState()
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Bagian Podium (Top 3)
                        SliverToBoxAdapter(child: _buildPodiumSection()),
                        // Bagian List (Peringkat 4 dst)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // Karena 3 pertama sudah di podium, kita mulai dari index + 3
                                final realIndex = index + 3;
                                if (realIndex >= _topUsers.length) return null;
                                return _buildListItem(
                                  realIndex,
                                  _topUsers[realIndex],
                                );
                              },
                              childCount: _topUsers.length > 3
                                  ? _topUsers.length - 3
                                  : 0,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 80), // Ruang untuk bottom bar
                        ),
                      ],
                    ),
            ),
      // Sticky Bottom Bar untuk peringkat User saat ini
      bottomNavigationBar: _buildCurrentUserBottomBar(),
    );
  }

  // ==========================================
  // WIDGET PODIUM (TOP 3)
  // ==========================================
  Widget _buildPodiumSection() {
    if (_topUsers.isEmpty) return const SizedBox.shrink();

    // Pastikan data tidak error jika kurang dari 3
    final first = _topUsers.isNotEmpty ? _topUsers[0] : null;
    final second = _topUsers.length > 1 ? _topUsers[1] : null;
    final third = _topUsers.length > 2 ? _topUsers[2] : null;

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF4338CA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Juara 2 (Kiri)
          if (second != null)
            Expanded(
              child: _buildPodiumAvatar(second, 2, 80, const Color(0xFFC0C0C0)),
            ),

          // Juara 1 (Tengah)
          if (first != null)
            Expanded(
              child: _buildPodiumAvatar(first, 1, 110, const Color(0xFFFFD700)),
            ),

          // Juara 3 (Kanan)
          if (third != null)
            Expanded(
              child: _buildPodiumAvatar(third, 3, 70, const Color(0xFFCD7F32)),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar(
    dynamic user,
    int rank,
    double height,
    Color medalColor,
  ) {
    final isPremium = user['is_premium'] == true;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: 3),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person_rounded,
                  size: rank == 1 ? 45 : 35,
                  color: Colors.white,
                ),
              ),
            ),
            // Medali Angka
            Positioned(
              bottom: -10,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: medalColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4338CA), width: 2),
                ),
                child: Center(
                  child: Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Nama
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            user['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: rank == 1 ? FontWeight.w900 : FontWeight.w600,
              fontSize: rank == 1 ? 14 : 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Poin
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${user['total_poin']} pts",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        if (isPremium) ...[
          const SizedBox(height: 4),
          const Icon(
            Icons.workspace_premium_rounded,
            color: Color(0xFFFFD700),
            size: 14,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // WIDGET LIST (Peringkat 4 ke atas)
  // ==========================================
  Widget _buildListItem(int index, dynamic user) {
    final rank = index + 1;
    final isPremium = user['is_premium'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nomor Peringkat
          SizedBox(
            width: 30,
            child: Text(
              "#$rank",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ),
          // Avatar Kecil
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              user['name'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nama & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
                if (isPremium)
                  const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFD97706),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Member PRO",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Poin
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${user['total_poin']}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4F46E5),
                  fontSize: 16,
                ),
              ),
              const Text(
                "pts",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM BAR (Peringkat User Saat Ini)
  // ==========================================
  Widget _buildCurrentUserBottomBar() {
    if (_currentUserData == null || _currentUserData!['rank'] == null) {
      return const SizedBox.shrink();
    }

    final rank = _currentUserData!['rank'];
    final data = _currentUserData!['data'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFDE68A),
              child: Icon(Icons.person_rounded, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Peringkat Kamu",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    data['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "#$rank",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF4338CA),
                  ),
                ),
                Text(
                  "${data['total_poin']} pts",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Belum ada data peringkat",
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }
}
