import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/module_service.dart';
import 'module_detail_screen.dart';

class AllModulesScreen extends StatefulWidget {
  const AllModulesScreen({super.key});

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
    setState(() {
      _modules = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Katalog Modul Belajar",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _modules.isEmpty
          ? const Center(child: Text("Belum ada modul tersedia."))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _modules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final module = _modules[index];
                final isPremiumModule =
                    module['is_premium'] == 1 || module['is_premium'] == true;

                return GestureDetector(
                  onTap: () {
                    if (isPremiumModule && !_isUserPremium) {
                      _showPremiumPaywall(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ModuleDetailScreen(slug: module['slug']),
                        ),
                      );
                    }
                  },
                  child: Container(
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
                              if (isPremiumModule)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: const Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ),
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
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
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
              },
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
