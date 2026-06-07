import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/io_client.dart';
import 'package:url_launcher/url_launcher.dart'; // Wajib untuk tombol buka di luar

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPdfBulletproof();
  }

  Future<void> _fetchPdfBulletproof() async {
    try {
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioClient);

      final response = await client
          .get(Uri.parse(widget.pdfUrl))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception("Koneksi lambat atau terblokir (Timeout).");
            },
          );

      if (response.statusCode == 200) {
        if (response.bodyBytes.length > 4 &&
            response.bodyBytes[0] == 0x25 &&
            response.bodyBytes[1] == 0x50 &&
            response.bodyBytes[2] == 0x44 &&
            response.bodyBytes[3] == 0x46) {
          if (mounted) {
            setState(() {
              _pdfBytes = response.bodyBytes;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'File yang diunduh bukan PDF yang valid.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat PDF (Status: ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan jaringan.';
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk membuka PDF di browser luar / Google Drive HP
  Future<void> _openInExternalBrowser() async {
    final Uri url = Uri.parse(widget.pdfUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi eksternal.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1E293B),
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF43F5E)),
                  SizedBox(height: 16),
                  Text('Membuka PDF...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tombol Penyelamat
                    ElevatedButton.icon(
                      onPressed: _openInExternalBrowser,
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('Buka dengan Aplikasi HP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SfPdfViewer.memory(
              _pdfBytes!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _errorMessage =
                      "File PDF ini rusak atau menggunakan format yang tidak didukung oleh aplikasi.";
                  _pdfBytes = null;
                });
              },
            ),
    );
  }
}
