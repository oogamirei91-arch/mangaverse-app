import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/suwayomi_source_model.dart';
import '../providers/manga_provider.dart';

/// Modal Bottom Sheet & Scroll Box untuk memilih Server / Sumber Komik di Suwayomi
void showServerSourcePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ServerSourcePickerSheet(),
  );
}

class ServerSourcePickerSheet extends StatefulWidget {
  const ServerSourcePickerSheet({super.key});

  @override
  State<ServerSourcePickerSheet> createState() => _ServerSourcePickerSheetState();
}

class _ServerSourcePickerSheetState extends State<ServerSourcePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'all'; // 'all', 'id', 'en', 'cosplay'

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mangaProvider = context.watch<MangaProvider>();
    final isSafeSearch = mangaProvider.isSafeSearchEnabled;
    final allSources = mangaProvider.allSuwayomiSourcesRaw;
    final activeSources = mangaProvider.suwayomiSources;

    // Filter daftar sumber berdasarkan pencarian dan kategori tab
    final query = _searchController.text.trim().toLowerCase();
    final sourceListToUse = isSafeSearch ? activeSources : allSources;
    final filteredSources = sourceListToUse.where((s) {
      // Filter kategori
      if (_selectedCategory == 'id' && s.lang.toLowerCase() != 'id') return false;
      if (_selectedCategory == 'en' && s.lang.toLowerCase() != 'en' && s.lang.toLowerCase() != 'eng') return false;
      if (_selectedCategory == 'cosplay' && !s.isCosplayOrGallery) {
        return false;
      }

      // Filter query pencarian
      if (query.isNotEmpty) {
        final matchesName = s.name.toLowerCase().contains(query);
        final matchesDisplay = s.displayName.toLowerCase().contains(query);
        final matchesLang = s.lang.toLowerCase().contains(query);
        return matchesName || matchesDisplay || matchesLang;
      }
      return true;
    }).toList();

    final isCosplayLocked = isSafeSearch && _selectedCategory == 'cosplay';
    final totalCosplayCount = allSources.where((s) => s.isCosplayOrGallery).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle atas
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header judul & info jumlah sumber
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hub_rounded, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Server & Sumber Komik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${filteredSources.length} sumber tersedia (${allSources.length} total terpasang)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                tooltip: 'Tutup',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Search Box Input
          TextField(
            controller: _searchController,
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari sumber (Cosplay, Kiryuu, Fox, Indo...)...',
              hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter Kategori Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', '🌐 Semua (${isSafeSearch ? activeSources.length : allSources.length})'),
                const SizedBox(width: 8),
                _buildCategoryChip('id', '🇮🇩 Indonesia'),
                const SizedBox(width: 8),
                _buildCategoryChip('en', '🇬🇧 English'),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  'cosplay',
                  isSafeSearch
                      ? '🔒 Cosplay & Galeri'
                      : '📸 Cosplay & Galeri ($totalCosplayCount)',
                ),
              ],
            ),
          ),

          // Peringatan Safe Search jika aktif
          if (isSafeSearch) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9F1C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9F1C).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFFFF9F1C), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safe Search AKTIF: Tab Cosplay, Galeri & sumber 18+ dikunci.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFFFFD166),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showUnlockDialog(context, mangaProvider),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Buka Kunci',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // KOTAK SCROLL (SCROLL BOX) DENGAN SCROLLBAR
          Text(
            'Daftar Server / Sumber:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: isCosplayLocked
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_rounded, color: Colors.redAccent, size: 40),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Tab Cosplay & Galeri Terkunci',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tab Cosplay & Galeri (CosplayTele, Cossora Stream Video, Photos18, dll.) mengandung konten khusus dewasa (18+).\n\nSemua kategori Cosplay & Galeri baru terbuka saat Safe Search dimatikan (OFF).',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () => _showUnlockDialog(context, mangaProvider),
                              icon: const Icon(Icons.lock_open_rounded, size: 18),
                              label: const Text('Buka Kunci (Matikan Safe Search)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE63946),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredSources.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 36, color: Colors.white30),
                              const SizedBox(height: 8),
                              Text(
                                'Sumber tidak ditemukan',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                              ),
                              if (isSafeSearch) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showUnlockDialog(context, mangaProvider),
                                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                                  label: const Text('Buka Sumber Cosplay / 18+'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: filteredSources.length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.white.withOpacity(0.04),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final source = filteredSources[index];
                        final isCurrent = source.id == mangaProvider.suwayomiSourceId;
                        final isCosplayOrGallery = source.lang.toLowerCase() == 'all' ||
                            source.name.toLowerCase().contains('cosplay') ||
                            source.name.toLowerCase().contains('photo');

                        return InkWell(
                          onTap: () {
                            mangaProvider.setSuwayomiSource(source.id, source.name);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Server aktif: ${source.displayName}'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrent ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isCurrent
                                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.4))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Icon Sumber
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isCosplayOrGallery
                                        ? const Color(0xFF9D4EDD).withOpacity(0.18)
                                        : (source.isDedicatedNsfw
                                            ? Colors.redAccent.withOpacity(0.18)
                                            : AppTheme.primaryColor.withOpacity(0.15)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isCosplayOrGallery
                                        ? Icons.photo_library_rounded
                                        : (source.isDedicatedNsfw
                                            ? Icons.warning_amber_rounded
                                            : Icons.menu_book_rounded),
                                    size: 16,
                                    color: isCosplayOrGallery
                                        ? const Color(0xFFC77DFF)
                                        : (source.isDedicatedNsfw
                                            ? const Color(0xFFFF6B6B)
                                            : AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Nama Sumber & Badges
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                          color: isCurrent ? AppTheme.primaryColor : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          _buildLangBadge(source.lang),
                                          if (source.isDedicatedNsfw) ...[
                                            const SizedBox(width: 5),
                                            _buildBadge('18+', Colors.redAccent),
                                          ],
                                          if (isCosplayOrGallery) ...[
                                            const SizedBox(width: 5),
                                            _buildBadge('COSPLAY / GALERI', const Color(0xFF9D4EDD)),
                                          ],
                                          if (source.name.toLowerCase().contains('cosplay')) ...[
                                            const SizedBox(width: 5),
                                            _buildBadge('VIDEO 🎬', const Color(0xFFE63946)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Checkmark tanda aktif
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, MangaProvider provider) {
    showDialog(
      context: context,
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
              'Buka Kunci Safe Search',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'Mematikan Safe Search akan membuka tab Cosplay, Galeri, dan seluruh sumber komik dewasa (18+).\n\nApakah Anda menyatakan bahwa Anda telah berusia 18 tahun atau lebih?',
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
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe Search dinonaktifkan. Tab Cosplay & Galeri telah terbuka!'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946)),
            child: const Text('Saya 18+ (Buka Kunci)'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLangBadge(String lang) {
    final l = lang.toUpperCase();
    Color bg;
    Color fg;
    if (l == 'ID') {
      bg = const Color(0xFFE63946).withOpacity(0.18);
      fg = const Color(0xFFFF6B6B);
    } else if (l == 'EN' || l == 'ENG') {
      bg = const Color(0xFF1D3557).withOpacity(0.3);
      fg = const Color(0xFF457B9D);
    } else {
      bg = const Color(0xFF7209B7).withOpacity(0.2);
      fg = const Color(0xFFB5179E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
