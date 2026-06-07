import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/module_service.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String slug;
  const ModuleDetailScreen({super.key, required this.slug});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final ModuleService _moduleService = ModuleService();
  Map<String, dynamic>? _module;
  bool _isLoading = true;

  // Sesuaikan URL ini dengan backend CBT Laravel Anda
  final String baseUrl = "https://cbt.sdntomang03.sch.id";

  String _processHtml(String rawHtml) {
    String processedHtml = rawHtml.replaceAll(
      'src="/storage',
      'src="$baseUrl/storage',
    );

    // 1. Block LaTeX ($$ ... $$) -> Untuk pecahan/rumus baris baru (center)
    processedHtml = processedHtml.replaceAllMapped(
      RegExp(r'\$\$(.*?)\$\$', dotAll: true),
      (match) {
        String math = Uri.encodeComponent(match[1]!.trim());
        return '<div style="text-align: center; margin: 10px 0;"><img src="https://latex.codecogs.com/png.latex?\\dpi{200}\\inline&space;$math" style="max-width: 100%; height: auto;" /></div>';
      },
    );

    // 2. Inline LaTeX ($ ... $) -> Untuk pecahan di dalam barisan teks
    processedHtml = processedHtml.replaceAllMapped(RegExp(r'\$(.*?)\$'), (
      match,
    ) {
      String math = Uri.encodeComponent(match[1]!.trim());
      return '<img src="https://latex.codecogs.com/png.latex?\\dpi{200}\\inline&space;$math" style="vertical-align: middle; height: 1.6em;" />';
    });

    // 3. Rumus bawaan Quill Editor (<span class="ql-formula">)
    processedHtml = processedHtml.replaceAllMapped(
      RegExp(
        r'<span[^>]*class="ql-formula"[^>]*data-value="([^"]*)"[^>]*>.*?</span>',
      ),
      (match) {
        String math = match[1]!
            .replaceAll('&gt;', '>')
            .replaceAll('&lt;', '<')
            .replaceAll('&amp;', '&');
        String encoded = Uri.encodeComponent(math.trim());
        return '<img src="https://latex.codecogs.com/png.latex?\\dpi{200}\\inline&space;$encoded" style="vertical-align: middle; height: 1.6em;" />';
      },
    );

    return processedHtml;
  }

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final data = await _moduleService.getModuleDetail(widget.slug);
    setState(() {
      _module = data;
      _isLoading = false;
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _module != null ? (_module!['title'] ?? 'Baca Modul') : 'Baca Modul',
          style: const TextStyle(
            color: Color(0xFF1E293B), // Slate 800
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _module == null
          ? const Center(child: Text('Gagal memuat modul.'))
          : _module!['is_locked'] == true
          ? _buildLockedView()
          : _buildModuleContent(),
      bottomNavigationBar:
          _isLoading || _module == null || _module!['is_locked'] == true
          ? null
          : _buildStickyBottomActions(),
    );
  }

  Widget _buildModuleContent() {
    final String contentHtml =
        _module!['content'] ?? '<p>Tidak ada konten.</p>';
    final String processedHtml = _processHtml(contentHtml);

    // Mengekstrak nama subjek (mengakomodasi struktur nested di JSON)
    final String? subjectName =
        _module!['subject']?['name'] ?? _module!['subject_name'];

    // Mengekstrak Video URL
    final String? videoUrl = _module!['video_url'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Informasi Utama Modul
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subjectName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      subjectName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _module!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
                if (_module!['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _module!['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // [BARU] Menampilkan Komponen Video Jika Tersedia dari JSON (Bukan dari dalam HTML content)
          if (videoUrl != null && videoUrl.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _launchURL(videoUrl),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFFF43F5E), // Rose 500
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Video Pembelajaran Tersedia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ketuk untuk menonton di YouTube',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Area Isi Modul Utama
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: HtmlWidget(
              processedHtml,
              textStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                height: 1.7,
              ),
              customStylesBuilder: (element) {
                if (['h1', 'h2', 'h3', 'h4'].contains(element.localName)) {
                  return {
                    'color': '#1E293B',
                    'font-weight': '800',
                    'margin-top': '1.5em',
                    'margin-bottom': '0.5em',
                  };
                }
                if (element.localName == 'p') {
                  return {'margin-bottom': '1em'};
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActions() {
    // [PERBAIKAN] Menggunakan key 'document_path' sesuai JSON
    final String? documentPath = _module!['document_path'];

    final hasPdf = documentPath != null && documentPath.toString().isNotEmpty;
    if (!hasPdf) return const SizedBox.shrink();

    // Rangkai URL jika path tidak diawali dengan http
    String finalPdfUrl = documentPath.startsWith('http')
        ? documentPath
        : '$baseUrl/storage/$documentPath';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _launchURL(finalPdfUrl),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
            label: const Text(
              'Download PDF Materi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E), // Rose 500
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2), // Rose 50
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 64,
              color: Color(0xFFF43F5E), // Rose 500
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Materi Terkunci',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Modul ini khusus untuk pengguna akun Premium. Silakan tingkatkan akun Anda untuk mengakses materi pembelajaran ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Implementasi navigasi ke halaman langganan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), // Indigo 600
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Langganan Premium',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
