import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chapter_provider.dart';
import 'providers/library_provider.dart';
import 'providers/manga_provider.dart';
import 'providers/reader_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MangaApp());
}

class MangaApp extends StatelessWidget {
  const MangaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeAuth(),
        ),
        ChangeNotifierProvider(
          create: (_) => MangaProvider()..initPreferences(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChapterProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReaderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LibraryProvider()..loadLibraryData(),
        ),
      ],
      child: MaterialApp(
        title: 'KuroReader',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Hanya tampilkan splash layar penuh saat aplikasi pertama kali dibuka untuk cek sesi lokal
    if (auth.isCheckingSession) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Memuat KuroReader...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Jika belum login, tampilkan LoginScreen
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Jika sudah login, tampilkan MainNavigationScreen (Katalog + Koleksi/Riwayat)
    return const MainNavigationScreen();
  }
}
