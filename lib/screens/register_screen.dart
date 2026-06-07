import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController =
      TextEditingController(); // <--- CONTROLLER BARU UNTUK USERNAME
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  void _handleRegister() async {
    // Validasi sederhana jika ada kolom yang kosong
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data wajib!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password konfirmasi tidak cocok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _authService.register(
      name: _nameController.text,
      username: _usernameController.text, // <--- KIRIM USERNAME
      email: _emailController
          .text, // <--- KIRIM EMAIL (Boleh kosong jika di DB divalidasi nullable)
      school: _schoolController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran gagal. Username/Email mungkin sudah terdaftar.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.indigo[900],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 70,
                color: Colors.indigo[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Buat Akun Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data diri Anda untuk mendaftar',
                style: TextStyle(color: Colors.indigo[400]),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                _nameController,
                'Nama Lengkap',
                Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              // --- FIELD USERNAME (BARU) ---
              _buildTextField(
                _usernameController,
                'Username (Tanpa Spasi)',
                Icons.alternate_email,
              ),
              const SizedBox(height: 16),

              // --- FIELD EMAIL ---
              _buildTextField(
                _emailController,
                'Email Aktif (Opsional)',
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _schoolController,
                'Asal Sekolah',
                Icons.account_balance_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _passwordController,
                'Password',
                Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _confirmPasswordController,
                'Konfirmasi Password',
                Icons.lock_reset_outlined,
                isPassword: true,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'DAFTAR SEKARANG',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.indigo[300]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
