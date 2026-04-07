import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../config/app_config.dart';

class YoutubeApiService {
  late final Dio _dio;

  YoutubeApiService({String? customKey}) {
    final apiKey = (customKey != null && customKey.isNotEmpty)
        ? customKey
        : dotenv.env['YOUTUBE_API_KEY'];
    
    print('Using API Key: ${apiKey != null ? "${apiKey.substring(0, 4)}..." : "null"}');
    
    if (apiKey == null || apiKey.isEmpty) {
      print('WARNING: YOUTUBE_API_KEY is null or empty');
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.youtubeBaseUrl,
        headers: {
          if (apiKey != null && apiKey.isNotEmpty) 'X-goog-api-key': apiKey,
          if (apiKey != null && apiKey.startsWith('ya29.'))
            'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (apiKey != null && !apiKey.startsWith('ya29.')) {
            options.queryParameters['key'] = apiKey;
          }
          return handler.next(options);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, error: true, requestHeader: true),
    );
  }

  Future<Map<String, dynamic>> searchVideos(
    String query, {
    String? pageToken,
  }) async {
    final Map<String, dynamic> params = {
      'part': 'snippet',
      'maxResults': 20,
      'q': query,
      'type': 'video',
    };

    if (pageToken != null && pageToken.isNotEmpty) {
      params['pageToken'] = pageToken;
    }

    final response = await _dio.get('/search', queryParameters: params);
    return response.data;
  }

  Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    final response = await _dio.get(
      '/videos',
      queryParameters: {'part': 'statistics,snippet', 'id': videoId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getRelatedVideos(String query) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': 10,
      },
    );
    return response.data;
  }

  Future<String?> getVideoStreamUrl(String videoId) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.muxed.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      print('Error extracting stream: $e');
      return null;
    } finally {
      yt.close();
    }
  }
}
