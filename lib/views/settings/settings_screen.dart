import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manga_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mangaProvider = context.watch<MangaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Pengaturan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Akun Profil Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  if (auth.currentUser?.photoUrl != null)
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(auth.currentUser!.photoUrl!),
                    )
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.currentUser?.displayName ?? 'Pengguna Tamu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          auth.currentUser?.email ?? 'tamu@kuroreader.local',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Section Konten & Keamanan
            Text(
              'Konten & Keamanan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Safe Search (Filter Konten Dewasa)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: mangaProvider.isSafeSearchEnabled
                        ? const Color(0xFF06D6A0).withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    mangaProvider.isSafeSearchEnabled ? Icons.shield_rounded : Icons.warning_amber_rounded,
                    color: mangaProvider.isSafeSearchEnabled ? const Color(0xFF06D6A0) : Colors.redAccent,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Safe Search (Filter 18+)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  mangaProvider.isSafeSearchEnabled
                      ? 'Aktif: Konten dewasa (18+) diblokir secara otomatis.'
                      : 'Nonaktif: Menampilkan semua kategori komik termasuk 18+.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                activeColor: AppTheme.primaryColor,
                value: mangaProvider.isSafeSearchEnabled,
                onChanged: (bool value) {
                  if (!value) {
                    // Ingin mematikan Safe Search (perlu konfirmasi usia)
                    _showAgeVerificationDialog(context, mangaProvider);
                  } else {
                    // Mengaktifkan kembali Safe Search (aman)
                    mangaProvider.setSafeSearch(true);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. Section Aplikasi & Info
            Text(
              'Tentang Aplikasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                    title: Text(
                      'Versi Aplikasi',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    trailing: const Text('1.0.0+1', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.api_rounded, color: AppTheme.textSecondary),
                    title: Text(
                      'Sumber Server Utama',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    trailing: const Text('MangaDex API v5', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Tombol Keluar Akun
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                label: Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => context.read<AuthProvider>().logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAgeVerificationDialog(BuildContext context, MangaProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'Konfirmasi Usia (18+)',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Mematikan Safe Search akan menampilkan seluruh kategori komik termasuk konten dewasa (18+).\n\nApakah Anda menyatakan bahwa Anda telah berusia 18 tahun atau lebih?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.setSafeSearch(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe Search dinonaktifkan. Menampilkan seluruh kategori.'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Saya 18+ Tahun'),
          ),
        ],
      ),
    );
  }
}
