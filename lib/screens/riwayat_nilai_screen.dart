import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class RiwayatNilaiScreen extends StatefulWidget {
  const RiwayatNilaiScreen({super.key});

  @override
  State<RiwayatNilaiScreen> createState() => _RiwayatNilaiScreenState();
}

class _RiwayatNilaiScreenState extends State<RiwayatNilaiScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  List<dynamic> _historyList = [];
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadThemeAndData();
  }

  Future<void> _loadThemeAndData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isPremium = prefs.getBool('is_premium') ?? false;
      });
    }
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    setState(() => _isLoading = true);
    try {
      // Memanggil API riwayat nilai siswa
      final response = await ApiClient().get('/student/history');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            _historyList = jsonResponse['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredList() {
    if (_selectedFilter == 'Semua') return _historyList;
    return _historyList.where((item) {
      final subject = item['subject_name'] ?? '';
      return subject.toString().toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Tema warna dinamis mengikuti status Premium Beranda
    final primaryColor = _isPremium
        ? const Color(0xFFD97706)
        : const Color(0xFF4338CA);
    final filteredData = _getFilteredList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Riwayat Nilai Ujian",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterRow(primaryColor),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchHistoryData,
                    color: primaryColor,
                    child: filteredData.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filteredData.length,
                            itemBuilder: (context, index) {
                              return _buildHistoryCard(
                                filteredData[index],
                                primaryColor,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET TOMBOL FILTER (Semua, MTK, B.Indo)
  // ==========================================
  Widget _buildFilterRow(Color primaryColor) {
    final filters = ['Semua', 'Matematika', 'Bahasa Indonesia'];
    return Container(
      color: primaryColor,
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : Colors.white,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide.none,
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() => _selectedFilter = filter);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET KARTU RIWAYAT (History Card)
  // ==========================================
  Widget _buildHistoryCard(dynamic item, Color primaryColor) {
    final score = double.tryParse(item['score'].toString()) ?? 0.0;
    final intScore = score.round();

    // Penentuan warna berdasarkan nilai lulus/tidak
    Color scoreColor = Colors.red;
    if (intScore >= 75)
      scoreColor = Colors.green;
    else if (intScore >= 60)
      scoreColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
          // Skor Lingkar Bulat
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$intScore",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Informasi Konten Ujian
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['exam_title'] ?? 'Ujian CBT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (item['subject_name'] ?? 'Umum').toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${item['duration'] ?? '-'} mnt",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 12,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['date'] ?? '-',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Indikator Benar / Salah Mini
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "✅ B: ${item['correct_count'] ?? 0}",
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "❌ S: ${item['wrong_count'] ?? 0}",
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            "Belum ada riwayat ujian",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
