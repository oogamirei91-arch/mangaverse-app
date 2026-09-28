class SuwayomiSourceModel {
  final String id;
  final String name;
  final String lang;
  final String? iconUrl;
  final bool supportsLatest;

  SuwayomiSourceModel({
    required this.id,
    required this.name,
    required this.lang,
    this.iconUrl,
    this.supportsLatest = true,
  });

  factory SuwayomiSourceModel.fromJson(Map<String, dynamic> json) {
    return SuwayomiSourceModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sumber Tak Bernama',
      lang: json['lang']?.toString() ?? 'all',
      iconUrl: json['iconUrl']?.toString(),
      supportsLatest: json['supportsLatest'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lang': lang,
    'iconUrl': iconUrl,
    'supportsLatest': supportsLatest,
  };

  String get displayName => '$name (${lang.toUpperCase()})';
}
