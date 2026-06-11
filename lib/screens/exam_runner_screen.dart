import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../services/public_exam_service.dart';
import '../core/api_client.dart';

class ExamRunnerScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const ExamRunnerScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<ExamRunnerScreen> createState() => _ExamRunnerScreenState();
}

class _ExamRunnerScreenState extends State<ExamRunnerScreen>
    with WidgetsBindingObserver {
  final PublicExamService _examService = PublicExamService();

  final String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _questions = [];
  Map<String, dynamic> _answers = {};
  List<String> _flags = [];
  String? _activePremiseId;

  int _currentIndex = 0;
  int _timeLeft = 0;
  Timer? _timer;

  // Controller untuk soal essay/isian — di-dispose saat ganti soal
  TextEditingController? _essayController;
  String? _essayCurrentQId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _essayController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_isLoading && !_isSubmitting) {
      _examService.recordViolation(widget.examId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peringatan! Anda keluar dari aplikasi ujian.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startExam() async {
    final data = await _examService.startExam(widget.examId);
    if (!mounted) return;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kesalahan jaringan. Coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    if (data.containsKey('SERVER_ERROR')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['SERVER_ERROR']),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // 1. Ambil object 'data' dari dalam respons JSON
    final payload = data['data'];

    // 2. Gunakan payload untuk mengecek questions
    if (payload == null ||
        payload['questions'] == null ||
        (payload['questions'] as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ujian belum memiliki soal.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
      return;
    }

    // 3. Gunakan payload untuk mengakses semua data state dan soal
    setState(() {
      _questions = payload['questions'];
      _timeLeft = (payload['state']['time_left_seconds'] as num).toInt();
      _answers = Map<String, dynamic>.from(payload['state']['answers'] ?? {});
      _flags = List<String>.from(payload['state']['flags'] ?? []);
      _isLoading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _finishExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Simpan jawaban lokal + kirim ke server (fire-and-forget)
  void _saveAnswer(String qId, dynamic value) {
    setState(() => _answers[qId] = value);
    _examService.submitAnswer(widget.examId, qId, value, _flags.contains(qId));
  }

  // Khusus dipanggil dari _buildOptions agar pakai qId soal saat ini
  void _saveAnswerLocally(dynamic value) {
    final qId = _questions[_currentIndex]['id'].toString();
    _saveAnswer(qId, value);
  }

  void _toggleFlag() {
    final qId = _questions[_currentIndex]['id'].toString();
    setState(() {
      if (_flags.contains(qId))
        _flags.remove(qId);
      else
        _flags.add(qId);
    });
    // Sync flag ke server tanpa mengubah jawaban
    _examService.submitAnswer(
      widget.examId,
      qId,
      _answers[qId],
      _flags.contains(qId),
    );
  }

  void _finishExam() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    if (_essayController != null && _essayCurrentQId != null) {
      _answers[_essayCurrentQId!] = _essayController!.text;
    }

    // Tunggu nilai dari server
    final resultData = await _examService.finishExam(
      widget.examId,
      Map<String, dynamic>.from(_answers),
    );

    if (!mounted) return;

    if (resultData != null && resultData.containsKey('score')) {
      showDialog(
        context: context,
        barrierDismissible: false, // Tidak bisa ditutup dengan tap di luar
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 60),
              SizedBox(height: 10),
              Text(
                'Ujian Selesai!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Skor Anda:', style: TextStyle(color: Colors.grey[600])),
              Text(
                '${resultData['score']}',
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Benar', resultData['correct'], Colors.green),
                  _buildStatItem('Salah', resultData['wrong'], Colors.red),
                  _buildStatItem(
                    'Kosong',
                    resultData['unanswered'],
                    Colors.grey,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 2. JIKA GAGAL MENGAMBIL NILAI (Tapi ujian terkirim)
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ujian Selesai. Jawaban dikumpulkan.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Widget Bantuan untuk menampilkan Benar/Salah/Kosong
  Widget _buildStatItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kumpulkan Ujian?'),
        content: const Text(
          'Anda tidak bisa kembali setelah menekan kumpulkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              'Ya, Kumpulkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuestionGrid() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Navigasi Soal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: _questions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final qId = _questions[index]['id'].toString();

                    // PERBAIKAN: Deteksi pintar apakah soal benar-benar terisi
                    final ans = _answers[qId];
                    bool isAnswered = false;
                    if (ans != null) {
                      if (ans is String) {
                        isAnswered = ans.trim().isNotEmpty;
                      } else if (ans is List) {
                        isAnswered = ans.isNotEmpty;
                      } else if (ans is Map) {
                        isAnswered = ans.isNotEmpty;
                      } else {
                        isAnswered = true; // Fallback int/bool
                      }
                    }

                    final isFlagged = _flags.contains(qId);
                    final isCurrent = index == _currentIndex;

                    Color bgColor = Colors.white;
                    Color borderColor = Colors.grey[300]!;
                    Color textColor = Colors.grey[700]!;

                    if (isCurrent) {
                      bgColor = Colors.indigo;
                      textColor = Colors.white;
                      borderColor = Colors.indigo;
                    } else if (isFlagged) {
                      bgColor = Colors.orange[100]!;
                      textColor = Colors.orange[800]!;
                      borderColor = Colors.orange;
                    } else if (isAnswered) {
                      bgColor = Colors.green;
                      textColor = Colors.white;
                      borderColor = Colors.green;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() => _currentIndex = index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHtml(String rawHtml, {TextStyle? style}) {
    String processedHtml = rawHtml.replaceAll(
      'src="/storage',
      'src="$baseUrl/storage',
    );

    // Block LaTeX ($$ ... $$)
    processedHtml = processedHtml.replaceAllMapped(
      RegExp(r'\$\$(.*?)\$\$', dotAll: true),
      (match) {
        String math = Uri.encodeComponent(match[1]!.trim());
        return '<div style="text-align: center; margin: 10px 0;"><img src="https://latex.codecogs.com/png.latex?\\dpi{200}\\inline&space;$math" style="max-width: 100%; height: auto;" /></div>';
      },
    );

    // Inline LaTeX ($ ... $)
    processedHtml = processedHtml.replaceAllMapped(RegExp(r'\$(.*?)\$'), (
      match,
    ) {
      String math = Uri.encodeComponent(match[1]!.trim());
      return '<img src="https://latex.codecogs.com/png.latex?\\dpi{200}\\inline&space;$math" style="vertical-align: middle; height: 1.6em;" />';
    });

    // Rumus Quill (<span class="ql-formula">)
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

    return HtmlWidget(
      processedHtml,
      textStyle:
          style ??
          const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );

    final question = _questions[_currentIndex];
    final qId = question['id'].toString();
    final qType = question['type'];

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: Text(
            widget.examTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _timeLeft < 300 ? Colors.red : Colors.indigo[900],
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _formatTime(_timeLeft),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'No. ${_currentIndex + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _toggleFlag,
                          icon: Icon(
                            _flags.contains(qId)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _flags.contains(qId)
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          label: Text(
                            'Ragu-ragu',
                            style: TextStyle(
                              color: _flags.contains(qId)
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: _buildHtml(question['content']),
                    ),
                    const SizedBox(height: 24),
                    _buildOptions(question, qId, qType),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                    ),
                    child: const Icon(Icons.chevron_left),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openQuestionGrid,
                    icon: const Icon(Icons.grid_view),
                    label: Text('${_currentIndex + 1}/${_questions.length}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[50],
                      foregroundColor: Colors.indigo,
                    ),
                  ),
                  if (_currentIndex < _questions.length - 1)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentIndex++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _showFinishDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Selesai',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> question, String qId, String type) {
    // ── TRUE / FALSE ──────────────────────────────────────────
    if (type == 'true_false') {
      Map<String, dynamic> tfAnswers = {};
      if (_answers[qId] is Map)
        tfAnswers = Map<String, dynamic>.from(_answers[qId]);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (question['options'] as List).map((opt) {
          final String optId = opt['id'].toString();
          final bool isTrue = tfAnswers[optId] == 'benar';
          final bool isFalse = tfAnswers[optId] == 'salah';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHtml(opt['option_text']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          tfAnswers[optId] = 'benar';
                          _saveAnswerLocally(
                            Map<String, dynamic>.from(tfAnswers),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isTrue ? Colors.green : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isTrue ? Colors.green : Colors.grey[300]!,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'BENAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isTrue ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          tfAnswers[optId] = 'salah';
                          _saveAnswerLocally(
                            Map<String, dynamic>.from(tfAnswers),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isFalse ? Colors.red : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFalse ? Colors.red : Colors.grey[300]!,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SALAH',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFalse ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // ── SINGLE CHOICE ─────────────────────────────────────────
    if (type == 'single_choice') {
      return Column(
        children: (question['options'] as List).map((opt) {
          final bool isSelected = _answers[qId] == opt['id'];
          return Card(
            elevation: isSelected ? 2 : 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? Colors.indigo : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: RadioListTile(
              title: _buildHtml(opt['option_text']),
              value: opt['id'],
              groupValue: _answers[qId],
              activeColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onChanged: (val) => _saveAnswerLocally(val),
            ),
          );
        }).toList(),
      );
    }

    // ── COMPLEX CHOICE ────────────────────────────────────────
    if (type == 'complex_choice') {
      List<dynamic> currentAnswers = _answers[qId] != null
          ? List.from(_answers[qId])
          : [];

      return Column(
        children: (question['options'] as List).map((opt) {
          final bool isChecked = currentAnswers.contains(opt['id']);
          return Card(
            elevation: isChecked ? 2 : 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isChecked ? Colors.indigo : Colors.grey[300]!,
                width: isChecked ? 2 : 1,
              ),
            ),
            child: CheckboxListTile(
              title: _buildHtml(opt['option_text']),
              value: isChecked,
              activeColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onChanged: (bool? val) {
                final updated = List<dynamic>.from(currentAnswers);
                if (val == true)
                  updated.add(opt['id']);
                else
                  updated.remove(opt['id']);
                _saveAnswerLocally(updated);
              },
            ),
          );
        }).toList(),
      );
    }

    // ── ESSAY / ISIAN / SHORT ANSWER ──────────────────────────
    // PERBAIKAN: Tangkap tipe 'isian' dan 'short_answer'
    if (type == 'essay' || type == 'isian' || type == 'short_answer') {
      // Buat controller baru hanya jika pindah ke soal textfield yang berbeda
      if (_essayCurrentQId != qId) {
        _essayController?.dispose();
        _essayController = TextEditingController(
          text: _answers[qId]?.toString() ?? '',
        );
        _essayCurrentQId = qId;
      }

      return TextField(
        controller: _essayController,
        maxLines: type == 'essay' ? 6 : 2, // Jika isian, kotaknya lebih pendek
        decoration: InputDecoration(
          hintText: type == 'essay'
              ? 'Ketik jawaban uraian Anda di sini...'
              : 'Ketik jawaban isian Anda di sini...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (val) {
          // Simpan lokal setiap ketikan tanpa spam ke server
          _answers[qId] = val;
        },
        onEditingComplete: () {
          // Kirim ke server saat selesai mengetik
          _saveAnswerLocally(_essayController!.text);
        },
      );
    }

    // ── MATCHING ──────────────────────────────────────────────
    if (type == 'matching') {
      Map<String, dynamic> matchAnswers = _answers[qId] != null
          ? Map<String, dynamic>.from(_answers[qId])
          : {};

      final List<dynamic> rawMatches = question['matches'] ?? [];

      // [BARU] Lakukan pengacakan (shuffle) hanya SEKALI.
      // Simpan di dalam state `question` agar susunannya tidak berubah-ubah
      // setiap kali layar di-render ulang akibat setState (saat user tap kotak).
      if (question['left_matches'] == null ||
          question['right_matches'] == null) {
        question['left_matches'] = List.from(rawMatches)..shuffle();
        question['right_matches'] = List.from(rawMatches)..shuffle();
      }

      final List<dynamic> leftMatches = question['left_matches'];
      final List<dynamic> rightMatches = question['right_matches'];

      final List<Color> pairColors = [
        Colors.blue,
        Colors.pink,
        Colors.orange,
        Colors.purple,
        Colors.teal,
        Colors.red,
        Colors.brown,
        Colors.cyan,
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.indigo, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cara jawab: Tap kotak di kiri, lalu tap pasangannya di kanan.',
                    style: TextStyle(color: Colors.indigo, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================
              // KOLOM KIRI: PREMISE (Telah Diacak)
              // =====================================
              Expanded(
                child: Column(
                  // Gunakan leftMatches
                  children: leftMatches.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final m = entry.value;
                    final String pId = m['id'].toString();
                    final bool isActive = _activePremiseId == pId;
                    final bool hasAnswer = matchAnswers.containsKey(pId);
                    final Color currentColor =
                        pairColors[index % pairColors.length];

                    return GestureDetector(
                      onTap: () => setState(() => _activePremiseId = pId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? currentColor
                              : (hasAnswer
                                    ? currentColor.withOpacity(0.15)
                                    : Colors.white),
                          border: Border.all(
                            color: isActive || hasAnswer
                                ? currentColor
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: currentColor.withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildHtml(
                                m['premise_text'],
                                style: TextStyle(
                                  color: isActive ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (hasAnswer && !isActive)
                              Icon(
                                Icons.check_circle,
                                color: currentColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),

              // =====================================
              // KOLOM KANAN: TARGET (Telah Diacak)
              // =====================================
              Expanded(
                child: Column(
                  // Gunakan rightMatches
                  children: rightMatches.map((m) {
                    final int tId = m['id'];
                    final String? matchedPremiseId = matchAnswers.entries
                        .where((e) => e.value == tId)
                        .map((e) => e.key)
                        .firstOrNull;
                    final bool isMatched = matchedPremiseId != null;

                    Color targetColor = Colors.grey[300]!;
                    Color targetBgColor = Colors.white;

                    if (isMatched) {
                      // [BARU] Cari index warna berdasarkan posisi di leftMatches,
                      // agar warnanya cocok (sinkron) dengan pasangannya di kiri.
                      final int premiseIndex = leftMatches.indexWhere(
                        (p) => p['id'].toString() == matchedPremiseId,
                      );
                      if (premiseIndex != -1) {
                        targetColor =
                            pairColors[premiseIndex % pairColors.length];
                        targetBgColor = targetColor.withOpacity(0.15);
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        if (_activePremiseId != null) {
                          final updated = Map<String, dynamic>.from(
                            matchAnswers,
                          );
                          updated[_activePremiseId!] = tId;
                          _saveAnswerLocally(updated);
                          setState(() => _activePremiseId = null);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pilih kotak sebelah kiri terlebih dahulu!',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: targetBgColor,
                          border: Border.all(
                            color: isMatched ? targetColor : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildHtml(
                          m['target_text'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const Text('Tipe soal tidak didukung.');
  }
}
