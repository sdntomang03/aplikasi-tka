import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/module_service.dart';
import 'module_detail_screen.dart';
import '../widgets/base_layout.dart'; // Import BaseLayout

class AllModulesScreen extends StatefulWidget {
  final String? subjectFilter;
  final String? levelFilter;

  // Parameter filter
  const AllModulesScreen({super.key, this.subjectFilter, this.levelFilter});

  @override
  State<AllModulesScreen> createState() => _AllModulesScreenState();
}

class _AllModulesScreenState extends State<AllModulesScreen> {
  final ModuleService _moduleService = ModuleService();
  List<dynamic> _modules = [];
  bool _isLoading = true;
  bool _isUserPremium = false;

  @override
  void initState() {
    super.initState();
    _fetchModules();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isUserPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  Future<void> _fetchModules() async {
    setState(() => _isLoading = true);
    final data = await _moduleService.getModules();

    // ==========================================
    // LOGIKA FILTER LOKAL PINTAR
    // ==========================================
    List<dynamic> filteredData = data;

    // Filter berdasarkan Mata Pelajaran (Contoh: "Matematika")
    if (widget.subjectFilter != null) {
      filteredData = filteredData.where((m) {
        final subjectName =
            m['subject']?['name']?.toString().toLowerCase() ?? '';
        return subjectName.contains(widget.subjectFilter!.toLowerCase());
      }).toList();
    }

    // Filter berdasarkan Kelas (Contoh: "Kelas 6")
    if (widget.levelFilter != null) {
      filteredData = filteredData.where((m) {
        final levelName = m['level']?['name']?.toString().toLowerCase() ?? '';
        return levelName.contains(widget.levelFilter!.toLowerCase());
      }).toList();
    }

    setState(() {
      _modules = filteredData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ubah judul dinamis sesuai filter yang diklik
    String pageTitle = "Katalog Modul Belajar";
    if (widget.subjectFilter != null) {
      pageTitle = "Modul ${widget.subjectFilter}";
      if (widget.levelFilter != null) {
        pageTitle += " (${widget.levelFilter})";
      }
    }

    return BaseLayout(
      showAppBar: false,
      usePadding: false,
      child: RefreshIndicator(
        onRefresh: _fetchModules,
        color: const Color(0xFF4338CA),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ==========================================
            // HEADER DENGAN SLIVER APPBAR (SEPERTI EXAM)
            // ==========================================
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: const Color(0xFF4338CA),
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Colors.white,
              ), // Panah kembali putih
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pageTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    // Badge PRO Jika User Premium
                    if (_isUserPremium) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                            SizedBox(width: 2),
                            Text(
                              "PRO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4338CA), Color(0xFF312E81)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // KONTEN UTAMA (DAFTAR MODUL)
            // ==========================================
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _isLoading
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    )
                  : _modules.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Text(
                          widget.subjectFilter != null
                              ? "Belum ada materi untuk ${widget.subjectFilter}."
                              : "Belum ada modul tersedia.",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final module = _modules[index];
                        return _buildModuleCard(module);
                      }, childCount: _modules.length),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Komponen Kartu Modul yang diekstrak agar rapi
  Widget _buildModuleCard(dynamic module) {
    final isPremiumModule =
        module['is_premium'] == 1 || module['is_premium'] == true;
    final subjectName = module['subject']?['name'] ?? 'Umum';

    return GestureDetector(
      onTap: () {
        if (isPremiumModule && !_isUserPremium) {
          _showPremiumPaywall(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ModuleDetailScreen(slug: module['slug']),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16), // Pengganti separatorBuilder
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPremiumModule
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPremiumModule
                    ? Icons.workspace_premium
                    : Icons.menu_book_rounded,
                color: isPremiumModule
                    ? const Color(0xFFD97706)
                    : const Color(0xFF4F46E5),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        subjectName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (isPremiumModule) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${module['estimated_time_minutes']} Menit',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumPaywall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Akses Terkunci! Modul ini khusus member Premium."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
