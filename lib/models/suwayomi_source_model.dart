class SuwayomiSourceModel {
  final String id;
  final String name;
  final String lang;
  final String? iconUrl;
  final bool supportsLatest;
  final bool isNsfw;

  SuwayomiSourceModel({
    required this.id,
    required this.name,
    required this.lang,
    this.iconUrl,
    this.supportsLatest = true,
    this.isNsfw = false,
  });

  factory SuwayomiSourceModel.fromJson(Map<String, dynamic> json) {
    return SuwayomiSourceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sumber Tak Bernama',
      lang: json['lang']?.toString() ?? 'all',
      iconUrl: json['iconUrl']?.toString(),
      supportsLatest: json['supportsLatest'] as bool? ?? true,
      isNsfw: (json['isNsfw'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lang': lang,
    'iconUrl': iconUrl,
    'supportsLatest': supportsLatest,
    'isNsfw': isNsfw,
  };

  /// Cek apakah sumber merupakan Cosplay / Galeri Foto
  bool get isCosplayOrGallery {
    final lower = name.toLowerCase();
    return lang.toLowerCase() == 'all' ||
        lower.contains('cosplay') ||
        lower.contains('photo') ||
        lower.contains('babes') ||
        lower.contains('femjoy') ||
        lower.contains('playmate');
  }

  /// Pengecekan sumber umum (Bukan sumber NSFW murni)
  bool get isGeneralComicSource {
    final lower = name.toLowerCase();
    return lower.contains('komikindo') ||
        lower.contains('kiryuu') ||
        lower.contains('west') ||
        lower.contains('mangawest') ||
        lower.contains('mangafox') ||
        lower.contains('mangabat') ||
        lower.contains('komikcast') ||
        lower.contains('mangadex') ||
        lower.contains('batoto');
  }

  /// Cek apakah sumber merupakan sumber khusus konten dewasa murni (Hentai/18+/Cosplay/Galeri)
  bool get isDedicatedNsfw {
    if (isGeneralComicSource) return false;
    final lower = name.toLowerCase();
    return lower.contains('hentai') ||
        lower.contains('doujin') ||
        lower.contains('3hentai') ||
        lower.contains('hentaifox') ||
        lower.contains('asmhentai') ||
        lower.contains('nhentai') ||
        lower.contains('manga18.me') ||
        lower.contains('manhwa18') ||
        lower.contains('manhwa.cc') ||
        lower.contains('crot') ||
        lower.contains('babes') ||
        lower.contains('femjoy') ||
        lower.contains('playmate') ||
        lower.contains('xxx') ||
        isCosplayOrGallery;
  }

  // --- REKOMENDASI SUMBER UTAMA (FEATURED SOURCES) ---
  bool get isMangaWest => name.toLowerCase().contains('west') || name.toLowerCase().contains('mangawest');
  bool get isKomikindo => name.toLowerCase().contains('komikindo');
  bool get isKiryuu => name.toLowerCase().contains('kiryuu');
  bool get isMangaFox => name.toLowerCase().contains('mangafox') || name.toLowerCase().contains('fanfox');
  bool get isMangabat => name.toLowerCase().contains('mangabat');
  bool get isManhwaCc => name.toLowerCase().contains('manhwa18') || name.toLowerCase().contains('manhwa.cc');

  bool get isFeaturedId => lang.toLowerCase() == 'id' && (isMangaWest || isKomikindo || isKiryuu);
  bool get isFeaturedEn => (lang.toLowerCase() == 'en' || lang.toLowerCase() == 'all') && (isMangaFox || isMangabat || isManhwaCc);
  bool get isFeatured => isFeaturedId || isFeaturedEn;

  int get priorityOrder {
    if (isMangaWest) return 1;
    if (isKomikindo) return 2;
    if (isKiryuu) return 3;
    if (isMangaFox) return 11;
    if (isMangabat) return 12;
    if (isManhwaCc) return 13;
    if (isCosplayOrGallery) return 80;
    return 50;
  }

  String get displayName {
    if (isMangaWest) {
      return 'MangaWest (ID)';
    }
    if (isManhwaCc) {
      return 'Manhwa.cc (EN)';
    }
    if (isCosplayOrGallery) {
      return '$name (${lang.toUpperCase()}) [Cosplay/Galeri]';
    }
    if (isDedicatedNsfw) {
      return '$name (${lang.toUpperCase()}) [18+]';
    }
    return '$name (${lang.toUpperCase()})';
  }
}

