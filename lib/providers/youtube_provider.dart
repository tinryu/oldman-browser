import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/youtube_repository.dart';
import '../services/youtube_api_service.dart';
import '../models/yt/video.dart';
import '../models/yt/video_statistics.dart';

class CustomKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setKey(String? key) => state = key;
}

final customApiKeyProvider = NotifierProvider<CustomKeyNotifier, String?>(CustomKeyNotifier.new);

final youtubeApiServiceProvider = Provider((ref) {
  final customKey = ref.watch(customApiKeyProvider);
  return YoutubeApiService(customKey: customKey);
});

final youtubeRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(youtubeApiServiceProvider);
  return YoutubeRepository(apiService);
});

// Search State
class SearchState {
  final List<Video> videos;
  final String query;
  final String nextPageToken;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  SearchState({
    this.videos = const [],
    this.query = '',
    this.nextPageToken = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  SearchState copyWith({
    List<Video>? videos,
    String? query,
    String? nextPageToken,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return SearchState(
      videos: videos ?? this.videos,
      query: query ?? this.query,
      nextPageToken: nextPageToken ?? this.nextPageToken,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  YoutubeRepository get _repository => ref.read(youtubeRepositoryProvider);

  Future<void> search(String query) async {
    print('Searching for: $query');
    if (query.isEmpty) return;

    state = state.copyWith(
      isLoading: true,
      query: query,
      videos: [],
      nextPageToken: '',
      error: null,
    );

    try {
      final result = await _repository.searchVideos(query);
      state = state.copyWith(
        videos: result.videos,
        nextPageToken: result.nextPageToken,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        state.nextPageToken.isEmpty ||
        state.query.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.searchVideos(
        state.query,
        pageToken: state.nextPageToken.isEmpty ? null : state.nextPageToken,
      );
      state = state.copyWith(
        videos: [...state.videos, ...result.videos],
        nextPageToken: result.nextPageToken,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

// Statistics and Related Videos Providers
final videoStatisticsProvider = FutureProvider.family<VideoStatistics?, String>(
  (ref, videoId) async {
    final repository = ref.watch(youtubeRepositoryProvider);
    return repository.getVideoStatistics(videoId);
  },
);

final relatedVideosProvider = FutureProvider.family<List<Video>, Video>((
  ref,
  video,
) async {
  final repository = ref.watch(youtubeRepositoryProvider);
  return repository.getRelatedVideos(video);
});
