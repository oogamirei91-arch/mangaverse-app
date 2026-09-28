import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manga_provider.dart';
import '../../widgets/manga_card.dart';
import 'popular_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MangaProvider>().fetchHomeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        title: Row(
          children: [
            if (auth.currentUser?.photoUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(auth.currentUser!.photoUrl!),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${auth.currentUser?.displayName?.split(' ').first ?? 'Pembaca'}!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Mau baca komik apa hari ini?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
            tooltip: 'Keluar',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        backgroundColor: AppTheme.surfaceColor,
        onRefresh: () => context.read<MangaProvider>().fetchHomeData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Bar
              _buildSearchBar(context),
              const SizedBox(height: 14),

              // 2. Dropdown Tipe Komik & Filter Bahasa
              _buildTypeAndLanguageFilters(context, mangaProvider),
              const SizedBox(height: 20),

              // Jika sedang dalam mode pencarian
              if (_searchController.text.trim().isNotEmpty) ...[
                Text(
                  'Hasil Pencarian (${mangaProvider.searchResults.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (mangaProvider.isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                else if (mangaProvider.searchResults.isEmpty)
                  _buildEmptyState('Tidak ada komik yang sesuai kata kunci dan filter terpilih.')
                else
                  _buildMangaGrid(mangaProvider.searchResults),
              ] else ...[
                // 3. Section: Komik Populer (Horizontal Carousel)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🔥 Paling Populer',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PopularListScreen(
                              comicType: mangaProvider.selectedComicType,
                              language: mangaProvider.selectedLanguage,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getTypeDisplayName(mangaProvider.selectedComicType),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (mangaProvider.isLoadingPopular)
                  const SizedBox(
                    height: 210,
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                else if (mangaProvider.popularManga.isEmpty)
                  _buildEmptyState('Belum ada data untuk kategori ini.')
                else
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: mangaProvider.popularManga.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        return MangaCard(
                          manga: mangaProvider.popularManga[index],
                          width: 145,
                          height: 220,
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 28),

                // 4. Section: Baru Diupdate (Grid 2 Kolom)
                Text(
                  '⚡ Baru Diupdate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                if (mangaProvider.isLoadingLatest)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  )
                else if (mangaProvider.latestManga.isEmpty)
                  _buildEmptyState('Belum ada update terbaru untuk kategori ini.')
                else
                  _buildMangaGrid(mangaProvider.latestManga),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
        onSubmitted: (value) => context.read<MangaProvider>().search(value),
        decoration: InputDecoration(
          hintText: 'Cari judul manga, manhwa, author...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    context.read<MangaProvider>().clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Filter Gabungan: Dropdown Tipe (Manga/Manhwa/Manhua) & Pilihan Bahasa
  Widget _buildTypeAndLanguageFilters(BuildContext context, MangaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Tipe Komik (Manga, Manhwa, Manhua)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: provider.selectedComicType,
              isExpanded: true,
              dropdownColor: AppTheme.cardColor,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, size: 18, color: AppTheme.secondaryColor),
                      SizedBox(width: 10),
                      Text('Semua Tipe Komik (Manga, Manhwa, Manhua)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'manhwa',
                  child: Row(
                    children: [
                      Text('🇰🇷', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Manhwa (Korea - Full Color / Webtoon)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'manga',
                  child: Row(
                    children: [
                      Text('🇯🇵', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Manga (Jepang)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'manhua',
                  child: Row(
                    children: [
                      Text('🇨🇳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Manhua (China)'),
                    ],
                  ),
                ),
              ],
              onChanged: (newType) {
                if (newType != null) {
                  provider.setComicType(newType);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Filter Bahasa (Indonesia, English, Semua)
        Row(
          children: [
            Text(
              'Bahasa Server: ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildLanguageChip(context, provider, 'id', '🇮🇩 Indonesia'),
                    const SizedBox(width: 6),
                    _buildLanguageChip(context, provider, 'en', '🇬🇧 English'),
                    const SizedBox(width: 6),
                    _buildLanguageChip(context, provider, 'all', '🌐 Semua'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageChip(
    BuildContext context,
    MangaProvider provider,
    String key,
    String label,
  ) {
    final isSelected = provider.selectedLanguage == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setLanguageFilter(key),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'manhwa':
        return '🇰🇷 Manhwa';
      case 'manga':
        return '🇯🇵 Manga';
      case 'manhua':
        return '🇨🇳 Manhua';
      default:
        return '🌐 Semua';
    }
  }

  Widget _buildMangaGrid(List<dynamic> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return MangaCard(manga: list[index]);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Text(
          'Anda dapat masuk kembali kapan saja.',
          style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
