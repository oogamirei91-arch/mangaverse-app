import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manga_provider.dart';
import '../../widgets/manga_card.dart';
import '../../widgets/server_source_picker_sheet.dart';
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
              // Banner peringatan jika Suwayomi / Cloudflare terputus
              if (!mangaProvider.isSuwayomiConnected)
                _buildDisconnectedServerBanner(context, mangaProvider),

              // 1. Search Bar
              _buildSearchBar(context),
              const SizedBox(height: 14),

              // 2. Dropdown Tipe Komik & Filter Bahasa
              _buildTypeAndLanguageFilters(context, mangaProvider),
              const SizedBox(height: 20),

              // Jika sedang dalam mode pencarian
              if (mangaProvider.isSearchActive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hasil Pencarian (${mangaProvider.searchResults.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primaryColor),
                      label: const Text('Tutup Hasil', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                        mangaProvider.clearSearch();
                      },
                    ),
                  ],
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
                  _buildEmptyState('Tidak ada komik yang sesuai kata kunci "${mangaProvider.lastSearchQuery}".')
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
                              mangaProvider.isSuwayomiActive
                                  ? (mangaProvider.suwayomiSourceName ?? 'Suwayomi')
                                  : _getTypeDisplayName(mangaProvider.selectedComicType),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: mangaProvider.isSuwayomiActive ? AppTheme.secondaryColor : AppTheme.primaryColor,
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
    final provider = context.read<MangaProvider>();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
        textInputAction: TextInputAction.search,
        onChanged: (_) => setState(() {}),
        onSubmitted: (value) => provider.search(value),
        decoration: InputDecoration(
          hintText: 'Cari judul manga, manhwa, author...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            tooltip: 'Cari',
            onPressed: () => provider.search(_searchController.text),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                  tooltip: 'Hapus Teks',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    provider.clearSearch();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor, size: 20),
                tooltip: 'Cari Sekarang',
                onPressed: () => provider.search(_searchController.text),
              ),
              const SizedBox(width: 4),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Filter Gabungan: Dropdown Tipe (Manga/Manhwa/Manhua) & Pilihan Bahasa
  Widget _buildTypeAndLanguageFilters(BuildContext context, MangaProvider provider) {
    if (provider.isSuwayomiActive) {
      final availableSources = provider.isSafeSearchEnabled
          ? provider.suwayomiSources
          : provider.allSuwayomiSourcesRaw;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kartu Server Suwayomi Aktif (Ketuk untuk ganti modal sheet)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showServerSourcePickerSheet(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hub_rounded, color: AppTheme.secondaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Suwayomi Aktif (Ketuk untuk ganti)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          Text(
                            provider.suwayomiSourceName ?? 'Pilih Sumber Komik',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tombol Scroll Box Server
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swap_vert_rounded, color: AppTheme.primaryColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Ganti Server',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (availableSources.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Header Sumber Cepat dengan indikator jumlah sumber
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swipe_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Pilih Cepat (${availableSources.length} Sumber - Geser ➔):',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (provider.isSafeSearchEnabled) ...[
                      GestureDetector(
                        onTap: () => showServerSourcePickerSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9F1C).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFF9F1C).withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 10, color: Color(0xFFFFD166)),
                              const SizedBox(width: 3),
                              Text(
                                'Safe Search: ON',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFFD166),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    GestureDetector(
                      onTap: () => showServerSourcePickerSheet(context),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // KOTAK SCROLL HORIZONTAL (HORIZONTAL SCROLL PILLS)
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: availableSources.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == availableSources.length) {
                    return GestureDetector(
                      onTap: () => showServerSourcePickerSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.more_horiz_rounded, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Lainnya...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final source = availableSources[index];
                  final isCurrent = source.id == provider.suwayomiSourceId;
                  final langUpper = source.lang.toUpperCase();

                  return GestureDetector(
                    onTap: () {
                      provider.setSuwayomiSource(source.id, source.name);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.primaryColor
                            : AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.primaryColor
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrent) ...[
                            const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: source.isCosplayOrGallery
                                    ? const Color(0xFF7209B7).withOpacity(0.3)
                                    : (langUpper == 'ID'
                                        ? Colors.redAccent.withOpacity(0.25)
                                        : (langUpper == 'EN' ? Colors.blueAccent.withOpacity(0.25) : Colors.purpleAccent.withOpacity(0.25))),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                source.isCosplayOrGallery
                                    ? (source.name.toLowerCase().contains('cosplay') ? '🎬 COSPLAY' : '📸 FOTO')
                                    : langUpper,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: source.isCosplayOrGallery
                                      ? const Color(0xFFC77DFF)
                                      : (langUpper == 'ID'
                                          ? Colors.redAccent
                                          : (langUpper == 'EN' ? Colors.lightBlueAccent : Colors.purpleAccent)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            source.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                          if (source.isFeatured) ...[
                            const SizedBox(width: 3),
                            const Text('⭐', style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }

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
                    _buildLanguageChip(context, provider, 'gallery', '📸 Cosplay & Galeri'),
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

  Widget _buildDisconnectedServerBanner(BuildContext context, MangaProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1A0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade800.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade900.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Server Suwayomi Terputus',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tautan Cloudflare mungkin telah berganti.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showQuickUrlDialog(context, provider),
            child: Text(
              'Ganti URL',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickUrlDialog(BuildContext context, MangaProvider provider) {
    final controller = TextEditingController(text: provider.suwayomiUrl);
    bool isSaving = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Perbarui Alamat Cloudflare',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan tautan Cloudflare baru dari CMD (contoh: https://xxxx.trycloudflare.com). Alamat ini akan otomatis menimpa yang lama dan tersimpan untuk seterusnya.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'https://xxxx.trycloudflare.com',
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
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste_rounded, color: AppTheme.primaryColor, size: 20),
                    tooltip: 'Tempel dari Clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.trim().isNotEmpty) {
                        setModalState(() {
                          controller.text = data.text!.trim();
                        });
                      }
                    },
                  ),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMsg!,
                  style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newUrl = controller.text.trim();
                          if (newUrl.isEmpty) {
                            setModalState(() => errorMsg = 'Alamat URL tidak boleh kosong.');
                            return;
                          }
                          setModalState(() {
                            isSaving = true;
                            errorMsg = null;
                          });

                          final success = await provider.testSuwayomiConnection(
                            customUrl: newUrl,
                            refreshHomeOnSuccess: true,
                          );

                          if (ctx.mounted) {
                            if (success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Berhasil terhubung & alamat baru otomatis disimpan!'),
                                  backgroundColor: Color(0xFF2E7D32),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              setModalState(() {
                                isSaving = false;
                                errorMsg = provider.suwayomiConnectionStatus ??
                                    'Gagal terhubung. Pastikan CMD Cloudflare di PC masih aktif.';
                              });
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isSaving ? 'Menghubungkan...' : 'Simpan & Terapkan',
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
            ],
          ),
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
