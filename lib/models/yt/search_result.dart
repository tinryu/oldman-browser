import 'video.dart';

class SearchResult {
  final List<Video> videos;
  final String nextPageToken;

  SearchResult({required this.videos, required this.nextPageToken});
}
