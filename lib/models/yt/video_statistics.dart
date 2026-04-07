class VideoStatistics {
  final String viewCount;
  final String likeCount;
  final String commentCount;

  VideoStatistics({
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
  });

  factory VideoStatistics.fromJson(Map<String, dynamic> json) {
    return VideoStatistics(
      viewCount: json['viewCount'] ?? '0',
      likeCount: json['likeCount'] ?? '0',
      commentCount: json['commentCount'] ?? '0',
    );
  }
}
