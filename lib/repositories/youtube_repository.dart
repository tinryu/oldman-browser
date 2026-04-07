import '../models/yt/video.dart';
import '../models/yt/video_statistics.dart';
import '../models/yt/search_result.dart';
import '../services/youtube_api_service.dart';

class YoutubeRepository {
  final YoutubeApiService _apiService;

  YoutubeRepository(this._apiService);

  Future<SearchResult> searchVideos(String query, {String? pageToken}) async {
    final data = await _apiService.searchVideos(query, pageToken: pageToken);
    final List<dynamic> items = data['items'];
    final List<Video> videos = items
        .map((item) => Video.fromJson(item))
        .toList();
    final String nextPageToken = data['nextPageToken'] ?? '';
    return SearchResult(videos: videos, nextPageToken: nextPageToken);
  }

  Future<VideoStatistics?> getVideoStatistics(String videoId) async {
    final data = await _apiService.getVideoDetails(videoId);
    final List<dynamic> items = data['items'];
    if (items.isNotEmpty) {
      return VideoStatistics.fromJson(items.first['statistics']);
    }
    return null;
  }

  Future<List<Video>> getRelatedVideos(Video video) async {
    final data = await _apiService.getRelatedVideos(video.title);
    final List<dynamic> items = data['items'];
    return items.map((item) => Video.fromJson(item)).toList();
  }
}
