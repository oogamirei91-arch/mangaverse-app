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

  /// Cek apakah sumber merupakan sumber khusus konten dewasa murni (Hentai/18+)
  bool get isDedicatedNsfw {
    final lower = name.toLowerCase();
    return lower.contains('hentai') ||
        lower.contains('doujin') ||
        lower.contains('18') ||
        lower.contains('crot') ||
        lower.contains('babes') ||
        lower.contains('femjoy') ||
        lower.contains('cosplay');
  }

  String get displayName => isDedicatedNsfw
      ? '$name (${lang.toUpperCase()}) [18+]'
      : '$name (${lang.toUpperCase()})';
}
