class VideoItem {
  final String title;
  final String url;
  final String? thumbnailUrl;

  VideoItem({required this.title, required this.url, this.thumbnailUrl});

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'url': url, 'thumbnailUrl': thumbnailUrl};
  }
}
