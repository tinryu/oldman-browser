class EpisodeServer {
  final String serverName;
  final bool isAi;
  final List<EpisodeSource> serverData;

  const EpisodeServer({
    required this.serverName,
    required this.isAi,
    required this.serverData,
  });

  factory EpisodeServer.fromJson(Map<String, dynamic> json) {
    final raw = json['server_data'];
    final serverData = (raw is List)
        ? raw
            .whereType<Map>()
            .map((e) => EpisodeSource.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <EpisodeSource>[];

    return EpisodeServer(
      serverName: (json['server_name'] ?? '').toString(),
      isAi: json['is_ai'] == true,
      serverData: serverData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_name': serverName,
      'is_ai': isAi,
      'server_data': serverData.map((e) => e.toJson()).toList(),
    };
  }
}

class EpisodeSource {
  final String name;
  final String slug;
  final String filename;
  final String linkEmbed;
  final String linkM3u8;

  const EpisodeSource({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkEmbed,
    required this.linkM3u8,
  });

  factory EpisodeSource.fromJson(Map<String, dynamic> json) {
    return EpisodeSource(
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      filename: (json['filename'] ?? '').toString(),
      linkEmbed: (json['link_embed'] ?? '').toString(),
      linkM3u8: (json['link_m3u8'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'filename': filename,
      'link_embed': linkEmbed,
      'link_m3u8': linkM3u8,
    };
  }

  String get bestUrl => linkM3u8.trim().isNotEmpty ? linkM3u8 : linkEmbed;
}
