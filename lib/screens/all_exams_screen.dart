import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/public_exam_service.dart';
import 'exam_verify_screen.dart';
import 'ranking_screen.dart';
import '../widgets/base_layout.dart';

class AllExamsScreen extends StatefulWidget {
  final String? subjectFilter;
  final bool isRankingMode;

  const AllExamsScreen({
    super.key,
    this.subjectFilter,
    this.isRankingMode = false,
  });

  @override
  State<AllExamsScreen> createState() => _AllExamsScreenState();
}

class _AllExamsScreenState extends State<AllExamsScreen> {
  final PublicExamService _publicExamService = PublicExamService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _exams = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  bool _isUserPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _fetchExams(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        if (!_isLoading && !_isFetchingMore && _hasMoreData) {
          _fetchExams(isRefresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isUserPremium = prefs.getBool('is_premium') ?? false;
    });
  }

  Future<void> _fetchExams({required bool isRefresh}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
        _exams.clear();
      });
    } else {
      setState(() => _isFetchingMore = true);
    }

    try {
      final result = await _publicExamService.getPublicExamsPaginated(
        page: _currentPage,
      );

      if (result != null && result['data'] != null) {
        List<dynamic> newExams = result['data'];

        if (widget.subjectFilter != null) {
          newExams = newExams.where((exam) {
            final subjectName = exam['subject'] != null
                ? exam['subject']['name'].toString().toLowerCase()
                : '';
            return subjectName.contains(widget.subjectFilter!.toLowerCase());
          }).toList();
        }

        setState(() {
          _exams.addAll(newExams);

          int currentPage = result['current_page'] ?? 1;
          int lastPage = result['last_page'] ?? 1;

          if (currentPage >= lastPage) {
            _hasMoreData = false;
          } else {
            _currentPage++;
          }
        });
      } else {
        setState(() => _hasMoreData = false);
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
    } finally {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isRankingMode ? "Peringkat Ujian" : "Semua Ujian";

    return BaseLayout(
      showAppBar: false,
      usePadding: false,
      child: RefreshIndicator(
        onRefresh: () => _fetchExams(isRefresh: true),
        color: const Color(0xFF4338CA),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ==========================================
            // HEADER DENGAN SLIVER APPBAR
            // ==========================================
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: const Color(0xFF4338CA),
              elevation: 0,
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
            // KONTEN UTAMA (LIST UJIAN)
            // ==========================================
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _isLoading && _exams.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    )
                  : _exams.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Tidak ada ujian tersedia.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _exams.length) {
                          return _buildBottomLoader();
                        }
                        final exam = _exams[index];
                        final subjectName = exam['subject'] != null
                            ? exam['subject']['name'].toString()
                            : 'UMUM';

                        // Perbaikan error method name di sini:
                        return _buildAnimatedExamCard(exam, subjectName, index);
                      }, childCount: _exams.length + (_isFetchingMore ? 1 : 0)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedExamCard(dynamic exam, String subjectName, int index) {
    final delay = index < 8 ? index * 100 : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        if (value == 0.0) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: delay)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 100);
          }
          return _buildModernExamCard(exam, subjectName);
        },
      ),
    );
  }

  Widget _buildModernExamCard(dynamic exam, String subjectName) {
    bool isExamPremium = exam['is_premium'] == true || exam['is_premium'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          highlightColor: const Color(0xFFEEF2FF),
          splashColor: const Color(0xFFE0E7FF),
          onTap: () {
            if (isExamPremium && !_isUserPremium) {
              _showPremiumPaywall(context);
              return;
            }

            if (widget.isRankingMode) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RankingScreen(
                    examId: (exam['hashid'] ?? exam['id']).toString(),
                    examTitle: exam['title'],
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExamVerifyScreen(
                    examId: (exam['hashid'] ?? exam['id']).toString(),
                    examTitle: exam['title'],
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExamPremium
                          ? [const Color(0xFFFFDF00), const Color(0xFFD4AF37)]
                          : [const Color(0xFF6366F1), const Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isExamPremium
                            ? const Color(0xFFD4AF37).withOpacity(0.3)
                            : const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isExamPremium
                        ? Icons.workspace_premium_rounded
                        : (widget.isRankingMode
                              ? Icons.emoji_events_rounded
                              : Icons.edit_document),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subjectName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (isExamPremium) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFDF00),
                                    Color(0xFFD4AF37),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "PRO",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        exam['title'] ?? 'Latihan Tanpa Judul',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exam['duration_minutes']} Menit',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    (isExamPremium && !_isUserPremium)
                        ? Icons.lock_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: (isExamPremium && !_isUserPremium)
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFCBD5E1),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomLoader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4338CA),
            ),
          ),
          SizedBox(width: 12),
          Text(
            "Memuat latihan lainnya...",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
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
              "Akses Terkunci",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Latihan ini eksklusif hanya untuk member Premium. Tingkatkan akunmu sekarang untuk membuka semua materi dan soal rahasia!",
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
              "Nanti Saja",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Arahkan ke halaman Pembelian/Upgrade Premium
            },
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
              "Dapatkan Akses PRO",
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
