class CosplayVideoModel {
  final String id;
  final String title;
  final String embedUrl;
  final String? masterM3u8;
  final String? url480p;
  final String? url720p;
  final String? url1080p;
  final String? thumbnailUrl;

  CosplayVideoModel({
    required this.id,
    required this.title,
    required this.embedUrl,
    this.masterM3u8,
    this.url480p,
    this.url720p,
    this.url1080p,
    this.thumbnailUrl,
  });

  /// Mendapatkan URL stream berdasarkan kualitas yang dipilih (480p, 720p, 1024p/1080p, atau auto)
  String getUrlForQuality(String quality) {
    switch (quality.toLowerCase()) {
      case '480p':
        return url480p ?? masterM3u8 ?? embedUrl;
      case '720p':
        return url720p ?? masterM3u8 ?? embedUrl;
      case '1024p':
      case '1080p':
        return url1080p ?? masterM3u8 ?? embedUrl;
      case 'auto':
      default:
        return masterM3u8 ?? embedUrl;
    }
  }

  /// Mendapatkan daftar kualitas yang tersedia
  List<String> get availableQualities {
    final list = <String>['Auto'];
    if (url480p != null) list.add('480p');
    if (url720p != null) list.add('720p');
    if (url1080p != null) list.add('1024p');
    return list;
  }
}
