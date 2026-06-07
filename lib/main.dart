import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SoalTkaSdApp());
}

class SoalTkaSdApp extends StatelessWidget {
  const SoalTkaSdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soal TKA SD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4F46E5),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

// =========================================
// SPLASH SCREEN
// =========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final bool isLoggedIn = await authService.isLoggedIn();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Soal TKA SD',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Platform Ujian Interaktif',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class AppTheme {
  static ThemeData get freeTheme => ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF6F7F9),
    primaryColor: const Color(0xFF4F46E5),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF4338CA)),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFF4F46E5),
    ),
  );

  static ThemeData get premiumTheme => ThemeData(
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    primaryColor: const Color(0xFFD97706),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFBBF24)),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFFD97706),
    ),
  );
}
