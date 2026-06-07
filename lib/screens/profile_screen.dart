import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  // Variabel untuk menampung data user dari SharedPreferences
  String _userName = "Pelajar";
  String _userSchool = "Umum";
  String _userEmail = "-";
  String _userUsername = "-";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Mengambil data user yang sedang login
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('nama_peserta') ?? "Pelajar";
      _userSchool = prefs.getString('asal_sekolah') ?? "Umum";
      _userEmail = prefs.getString('email') ?? "email@siswa.com";
      _userUsername = prefs.getString('username') ?? "siswa123";
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
          // ========================
          // HEADER PREMIUM MELENGKUNG
          // ========================
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF4338CA),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'Profil Saya',
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
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -40,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ========================
          // KONTEN PROFIL UTAMA
          // ========================
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _buildProfileHeader(),
                      _buildStatsRow(),
                      _buildMenuSection(context),
                      const SizedBox(height: 40), // Jarak bawah
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 1. Bagian Foto & Nama
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
          // Foto Profil (Avatar)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(
                Icons.person_rounded,
                size: 50,
                color: Color(0xFF818CF8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nama
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Info Sekolah / Username
          Text(
            "$_userSchool • $_userUsername",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Bagian Statistik Latihan & Poin
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Latihan Selesai",
              "0", // TODO: Dinamis dari API nanti
              Icons.task_alt_rounded,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Total Poin",
              "0", // TODO: Dinamis dari API nanti
              Icons.stars_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Bagian Daftar Menu
  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFF6366F1),
              title: "Edit Profil",
              onTap: () => _showEditProfileDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFFF59E0B), // Warna Amber
              title: "Ubah Kata Sandi",
              onTap: () => _showEditPasswordDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF14B8A6),
              title: "Riwayat Latihan",
              onTap: () {
                // TODO: Navigasi ke halaman Riwayat
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: "Tentang Aplikasi",
              onTap: () => _showAboutDialog(context),
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFEF4444),
              title: "Keluar",
              isDestructive: true,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFEF2F2)
                      : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDestructive
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 64,
      endIndent: 20,
    );
  }

  // ==========================================
  // 1. DIALOG EDIT PROFIL
  // ==========================================
  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: _userName);
    final schoolController = TextEditingController(text: _userSchool);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Profil",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bisa di-edit
              _buildCustomTextField("Nama Lengkap", nameController, true),
              const SizedBox(height: 12),
              _buildCustomTextField("Asal Sekolah", schoolController, true),
              const SizedBox(height: 12),

              // Read-only (Tidak bisa di-edit)
              _buildCustomTextField(
                "Username",
                TextEditingController(text: _userUsername),
                false,
              ),
              const SizedBox(height: 12),
              _buildCustomTextField(
                "Email",
                TextEditingController(text: _userEmail),
                false,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. Tembak API ke database Laravel
              bool isSuccess = await _authService.updateProfile(
                nameController.text,
                schoolController.text,
              );

              if (isSuccess) {
                // 2. Jika sukses di database, baru kita simpan lokal & update UI
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('nama_peserta', nameController.text);
                await prefs.setString('asal_sekolah', schoolController.text);

                setState(() {
                  _userName = nameController.text;
                  _userSchool = schoolController.text;
                });

                Navigator.pop(context); // Tutup dialog
                _showSnackBar("Profil berhasil diperbarui!", isError: false);
              } else {
                _showSnackBar(
                  "Gagal memperbarui profil di server.",
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    String label,
    TextEditingController controller,
    bool isEnabled,
  ) {
    return TextField(
      controller: controller,
      enabled: isEnabled,
      style: TextStyle(
        fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
        color: isEnabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        filled: true,
        fillColor: isEnabled
            ? const Color(0xFFF8FAFC)
            : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  // ==========================================
  // 2. DIALOG UBAH KATA SANDI
  // ==========================================
  void _showEditPasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Variabel state untuk menampilkan/menyembunyikan teks password
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // StatefulBuilder agar tombol mata berfungsi di dalam dialog
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Ubah Kata Sandi",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordTextField(
                    "Kata Sandi Lama",
                    oldPasswordController,
                    obscureOld,
                    () => setStateDialog(() => obscureOld = !obscureOld),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordTextField(
                    "Kata Sandi Baru",
                    newPasswordController,
                    obscureNew,
                    () => setStateDialog(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordTextField(
                    "Konfirmasi Sandi Baru",
                    confirmPasswordController,
                    obscureConfirm,
                    () =>
                        setStateDialog(() => obscureConfirm = !obscureConfirm),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validasi Sederhana
                  if (oldPasswordController.text.isEmpty ||
                      newPasswordController.text.isEmpty) {
                    _showSnackBar(
                      "Harap isi semua kolom sandi!",
                      isError: true,
                    );
                    return;
                  }
                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    _showSnackBar(
                      "Kata sandi baru tidak cocok!",
                      isError: true,
                    );
                    return;
                  }
                  if (newPasswordController.text.length < 6) {
                    _showSnackBar(
                      "Kata sandi minimal 6 karakter!",
                      isError: true,
                    );
                    return;
                  }

                  // Tembak API ke database Laravel
                  final result = await _authService.updatePassword(
                    oldPasswordController.text,
                    newPasswordController.text,
                  );

                  if (result['success']) {
                    Navigator.pop(context); // Tutup dialog jika sukses
                    _showSnackBar(result['message'], isError: false);
                  } else {
                    // Tampilkan pesan error dari Laravel (misal: "Sandi lama salah")
                    _showSnackBar(result['message'], isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), // Amber sesuai ikon
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Ubah Sandi"),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget khusus Input Password dengan tombol mata (Eye Toggle)
  Widget _buildPasswordTextField(
    String label,
    TextEditingController controller,
    bool isObscure,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: onToggle, // Memanggil setStateDialog saat diklik
        ),
      ),
    );
  }

  // Helper untuk memunculkan SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // 3. DIALOG TENTANG APLIKASI
  // ==========================================
  void _showAboutDialog(BuildContext context) {
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
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 60,
                color: Color(0xFF4338CA),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Aplikasi Ujian CBT",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Versi 1.0.0",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Dibuat dengan ❤️ oleh:",
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              "Pengembang Aplikasi CBT SD",
              style: TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Tutup",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. DIALOG KONFIRMASI LOGOUT
  // ==========================================
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Keluar dari Akun?",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          "Apakah kamu yakin ingin keluar dari aplikasi?",
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }
}
