import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/manga_provider.dart';
import '../../widgets/manga_card.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = true;

  // Daftar genre lengkap beserta UUID resmi MangaDex
  static const Map<String, String> _popularGenres = {
    'Action': '391e0439-e38d-4e18-800e-6213080f3385',
    'Adventure': '87cc87cd-a395-47af-b27a-93258283bbc6',
    'Comedy': '4d32cc48-9f00-4cca-9b5a-a839f0764984',
    'Drama': 'b9af3a63-f058-46de-a9a0-e0c13906197a',
    'Fantasy': 'cdc58593-ada3-4f6c-8e53-8d77757e1017',
    'Horror': 'cdad7e68-ccd9-4093-967a-97122a822b6e',
    'Isekai': 'ace04997-f6bd-4329-8b02-a5c04fa8218b',
    'Mystery': 'ee968100-4191-4968-93d3-f82d72be7e46',
    'Psychological': '3b60175c-a2d4-4660-bb58-f40a16373b84',
    'Romance': '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
    'Sci-Fi': '256c8bd9-4904-432d-8bbf-d8a4096e0729',
    'Slice of Life': 'e5301a23-ebd9-49dd-a0cb-2add944c7fe9',
    'Supernatural': 'eabc5b4c-6aff-42f3-b657-3e190adc484b',
    'Sports': '69964a64-2f90-4d33-beeb-f3ed2f2050c9',
    'Ecchi': '97893a4c-12af-4dac-b6be-0dffb3720f22',
    'Smut': 'fac73735-a1b4-4b47-a71d-f89aa7741d0b',
    'Harem': 'aafb99c1-7f60-43fa-b75f-fc9502ce29c7',
    'Gore': 'b29d6a3d-1569-4e7a-8ac5-983ac273e766',
    'Doujinshi': 'b13b2a48-c720-44a9-9c77-39c9979373fb',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<MangaProvider>().executeAdvancedSearch(_searchController.text);
    setState(() {
      _showFilters = false; // Ciutkan filter agar hasil pencarian terlihat jelas
    });
  }

  @override
  Widget build(BuildContext context) {
    final mangaProvider = context.watch<MangaProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Pencarian Lengkap',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off_rounded : Icons.tune_rounded,
              color: AppTheme.primaryColor,
            ),
            tooltip: _showFilters ? 'Sembunyikan Filter' : 'Buka Filter',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar
            _buildSearchBar(),
            const SizedBox(height: 12),

            // 2. Expandable Filter Panel
            if (_showFilters) ...[
              _buildFilterSection(mangaProvider),
              const SizedBox(height: 16),
            ],

            // 3. Search Summary Bar & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hasil Pencarian (${mangaProvider.advancedSearchResults.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (!_showFilters)
                  TextButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryColor),
                    label: const Text('Ubah Filter', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                    onPressed: () => setState(() => _showFilters = true),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Results Grid or Loading
            if (mangaProvider.isAdvancedSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            else if (mangaProvider.advancedSearchResults.isEmpty)
              _buildEmptyState()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: mangaProvider.advancedSearchResults.length,
                itemBuilder: (context, index) {
                  return MangaCard(manga: mangaProvider.advancedSearchResults[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
        onSubmitted: (_) => _triggerSearch(),
        decoration: InputDecoration(
          hintText: 'Ketik judul, karakter, atau kosongkan...',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor),
            onPressed: _triggerSearch,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterSection(MangaProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Tipe Komik
          _buildFilterLabel('Tipe Komik:'),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('Semua', 'all', provider.advComicType, (v) => provider.setAdvComicType(v)),
              _buildChoiceChip('🇰🇷 Manhwa', 'manhwa', provider.advComicType, (v) => provider.setAdvComicType(v)),
              _buildChoiceChip('🇯🇵 Manga', 'manga', provider.advComicType, (v) => provider.setAdvComicType(v)),
              _buildChoiceChip('🇨🇳 Manhua', 'manhua', provider.advComicType, (v) => provider.setAdvComicType(v)),
            ],
          ),
          const SizedBox(height: 14),

          // B. Status Komik (Ongoing / Completed)
          _buildFilterLabel('Status Rilis:'),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('Semua Status', 'all', provider.advStatus, (v) => provider.setAdvStatus(v)),
              _buildChoiceChip('⚡ Ongoing', 'ongoing', provider.advStatus, (v) => provider.setAdvStatus(v)),
              _buildChoiceChip('✓ Completed', 'completed', provider.advStatus, (v) => provider.setAdvStatus(v)),
            ],
          ),
          const SizedBox(height: 14),

          // C. Bahasa Terjemahan
          _buildFilterLabel('Bahasa Terjemahan:'),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('🇮🇩 Indonesia', 'id', provider.advLanguage, (v) => provider.setAdvLanguage(v)),
              _buildChoiceChip('🇬🇧 English', 'en', provider.advLanguage, (v) => provider.setAdvLanguage(v)),
              _buildChoiceChip('🌐 Semua', 'all', provider.advLanguage, (v) => provider.setAdvLanguage(v)),
            ],
          ),
          const SizedBox(height: 14),

          // D. Filter Klasifikasi Konten (Content Rating)
          if (!provider.isSafeSearchEnabled) ...[
            _buildFilterLabel('Klasifikasi Konten (Safe Search Nonaktif):'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRatingFilterChip(provider, 'safe', '🟢 Safe'),
                _buildRatingFilterChip(provider, 'suggestive', '🟡 Suggestive'),
                _buildRatingFilterChip(provider, 'erotica', '🟠 Erotica'),
                _buildRatingFilterChip(provider, 'pornographic', '🔴 18+ Pornographic'),
              ],
            ),
          ],

          // E. Pilihan Genre (Multi-select termasuk Ecchi, Smut, Gore, Doujinshi)
          _buildFilterLabel('Pilih Genre (Bisa Lebih Dari Satu):'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _popularGenres.entries.map((entry) {
              final isSelected = provider.advSelectedGenreIds.contains(entry.value);
              final isMatureTag = ['Ecchi', 'Smut', 'Gore', 'Doujinshi', 'Harem'].contains(entry.key);

              return FilterChip(
                label: Text(entry.key),
                selected: isSelected,
                onSelected: (_) => provider.toggleAdvGenre(entry.value),
                selectedColor: isMatureTag
                    ? Colors.redAccent.withOpacity(0.35)
                    : AppTheme.primaryColor.withOpacity(0.3),
                checkmarkColor: isMatureTag ? Colors.redAccent : AppTheme.primaryColor,
                backgroundColor: AppTheme.cardColor,
                labelStyle: GoogleFonts.plusJakartaSans(
                  color: isSelected
                      ? Colors.white
                      : (isMatureTag ? Colors.redAccent.withOpacity(0.8) : AppTheme.textSecondary),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? (isMatureTag ? Colors.redAccent : AppTheme.primaryColor)
                      : (isMatureTag ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.06)),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Terapkan & Reset
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.resetAdvFilters();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset Filter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _triggerSearch,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Terapkan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRatingFilterChip(MangaProvider provider, String rating, String label) {
    final isSelected = provider.advSelectedRatings.contains(rating);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.toggleAdvRating(rating),
      selectedColor: rating == 'pornographic' || rating == 'erotica'
          ? Colors.redAccent.withOpacity(0.3)
          : AppTheme.primaryColor.withOpacity(0.3),
      checkmarkColor: rating == 'pornographic' || rating == 'erotica' ? Colors.redAccent : AppTheme.primaryColor,
      backgroundColor: AppTheme.cardColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.cardColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.06),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.manage_search_rounded, size: 54, color: AppTheme.textSecondary),
            const SizedBox(height: 14),
            Text(
              'Gunakan filter di atas dan klik "Terapkan" untuk menemukan komik!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
