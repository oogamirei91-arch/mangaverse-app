import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manga_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _suwayomiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<MangaProvider>();
    _suwayomiUrlController.text = provider.suwayomiUrl;
  }

  @override
  void dispose() {
    _suwayomiUrlController.dispose();
    super.dispose();
  }

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

            // 2. Section Server Komik (Suwayomi Engine)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Server Komik (Suwayomi Engine)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: mangaProvider.isSuwayomiConnected
                        ? const Color(0xFF06D6A0).withOpacity(0.2)
                        : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mangaProvider.isSuwayomiConnected ? 'Terhubung' : 'Belum Terhubung',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: mangaProvider.isSuwayomiConnected ? const Color(0xFF06D6A0) : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Card Konfigurasi Server Suwayomi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_rounded, size: 20, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Konfigurasi Server Suwayomi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Input URL Server Suwayomi
                  Text(
                    'Alamat URL Server:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _suwayomiUrlController,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'http://192.168.137.1:4567 atau https://pilot-omaha-korea-limousines.trycloudflare.com',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 12),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    onChanged: (val) => mangaProvider.setSuwayomiUrl(val),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💡 Tips: Gunakan URL Cloudflare jika di luar rumah, atau http://192.168.137.1:4567 jika HP terhubung langsung ke Hotspot PC (lebih cepat & stabil tanpa expired).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.textSecondary.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol Tes Koneksi & Status
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: mangaProvider.isTestingSuwayomi
                          ? null
                          : () async {
                              await mangaProvider.testSuwayomiConnection(
                                customUrl: _suwayomiUrlController.text,
                              );
                            },
                      icon: mangaProvider.isTestingSuwayomi
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        mangaProvider.isTestingSuwayomi ? 'Menguji Koneksi...' : 'Tes Koneksi & Ambil Sumber',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  // Pesan Feedback Hasil Tes
                  if (mangaProvider.suwayomiConnectionStatus != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (mangaProvider.isSuwayomiConnected ? const Color(0xFF06D6A0) : Colors.redAccent)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (mangaProvider.isSuwayomiConnected ? const Color(0xFF06D6A0) : Colors.redAccent)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            mangaProvider.isSuwayomiConnected ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                            size: 16,
                            color: mangaProvider.isSuwayomiConnected ? const Color(0xFF06D6A0) : Colors.redAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mangaProvider.suwayomiConnectionStatus!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: mangaProvider.isSuwayomiConnected ? const Color(0xFF06D6A0) : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Pilihan Sumber/Ekstensi Aktif
                  if (mangaProvider.suwayomiSources.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Pilih Sumber Komik Aktif:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: mangaProvider.suwayomiSourceId,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceColor,
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.primaryColor),
                          items: mangaProvider.suwayomiSources.map((source) {
                            return DropdownMenuItem(
                              value: source.id,
                              child: Row(
                                children: [
                                  Icon(
                                    source.isNsfw ? Icons.warning_amber_rounded : Icons.extension_rounded,
                                    size: 16,
                                    color: source.isNsfw ? Colors.redAccent : AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      source.displayName,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: source.isNsfw ? const Color(0xFFFF6B6B) : Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (selectedId) {
                            if (selectedId != null) {
                              final selected = mangaProvider.suwayomiSources.firstWhere((s) => s.id == selectedId);
                              mangaProvider.setSuwayomiSource(selected.id, selected.name);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  // Petunjuk Ekstensi
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'Menambah Sumber / Ekstensi:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1. Buka browser di PC ke http://localhost:4567\n2. Masuk ke menu "Browse" > "Extensions" lalu instal ekstensi komik yang diinginkan (Komikindo, Kiryuu, MangaFox, Mangabat, dll).\n3. Klik "Tes Koneksi & Ambil Sumber" di atas untuk memperbarui daftar.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            height: 1.5,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Section Konten & Keamanan
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
                  'Safe Search & Filter 18+',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  mangaProvider.isSafeSearchEnabled
                      ? 'Safe Search AKTIF: Hanya sumber aman (isNsfw: false) & sembunyikan komik 18+.'
                      : 'Filter 18+ AKTIF: Membuka sumber dewasa (isNsfw: true) & munculkan komik 18+/NSFW.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                activeColor: AppTheme.primaryColor,
                value: mangaProvider.isSafeSearchEnabled,
                onChanged: (bool value) {
                  if (!value) {
                    _showAgeVerificationDialog(context, mangaProvider);
                  } else {
                    mangaProvider.setSafeSearch(true);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // 4. Section Aplikasi & Info
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
                      'Server Aktif Saat Ini',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    trailing: Text(
                      'Suwayomi (${mangaProvider.suwayomiSourceName ?? 'Aktif'})',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
