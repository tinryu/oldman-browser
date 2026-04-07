class Video {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String channelId;
  final String channelTitle;
  final String publishedAt;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.channelId,
    required this.channelTitle,
    required this.publishedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];
    final idData = json['id'];

    // For search results, the video ID is nested in an 'id' object
    // For video list/detail results, it's just 'id'
    String videoId = '';
    if (idData is Map) {
      videoId = idData['videoId'] ?? '';
    } else if (idData is String) {
      videoId = idData;
    }

    return Video(
      id: videoId,
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? '',
      channelId: snippet['channelId'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      publishedAt: snippet['publishedAt'] ?? '',
    );
  }
}
