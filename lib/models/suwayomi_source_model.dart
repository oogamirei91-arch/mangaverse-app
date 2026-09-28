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
        lower.contains('femjoy');
  }

  /// Cek apakah sumber merupakan sumber khusus konten dewasa murni (Hentai/18+/Cosplay/Galeri)
  bool get isDedicatedNsfw {
    if (isNsfw) return true;
    final lower = name.toLowerCase();
    return lower.contains('hentai') ||
        lower.contains('doujin') ||
        lower.contains('18') ||
        lower.contains('crot') ||
        lower.contains('babes') ||
        lower.contains('femjoy') ||
        lower.contains('cosplay') ||
        lower.contains('ero') ||
        isCosplayOrGallery;
  }

  String get displayName {
    if (isCosplayOrGallery) {
      return '$name (${lang.toUpperCase()}) [Cosplay/Galeri]';
    }
    if (isDedicatedNsfw) {
      return '$name (${lang.toUpperCase()}) [18+]';
    }
    return '$name (${lang.toUpperCase()})';
  }
}
