import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import 'package:old_man_browser/models/country.dart';

import '../config/app_config.dart';
import '../models/movie.dart';
import '../models/categoris.dart';
import '../models/episode.dart';

class MovieResponse {
  final List<Movie> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int totalItemsPerPage;

  MovieResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.totalItemsPerPage,
  });

  bool get hasReachedMax {
    // Calculation based on total items
    final isLastPageByTotal = (currentPage * totalItemsPerPage) >= totalItems;

    final reached = isLastPageByTotal;

    debugPrint(
      'Pagination Check: Current Page $currentPage. Reached Max: $reached',
    );
    return reached;
  }
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Categoris>> fetchCategories() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.categoriesPath}');
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load categories (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);

    // OPhim categories: { data: { items: [ { _id, name, slug }, ... ] } }
    if (decoded is Map && decoded['data'] is Map) {
      final data = (decoded['data'] as Map).cast<String, dynamic>();
      final items = data['items'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => Categoris.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false);
      }
    }

    // Generic categories: top-level list
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Categoris.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }

    throw ApiException(
      'Categories endpoint must return {data:{items:[]}} or a JSON array',
    );
  }

  Future<List<Movie>> fetchMovieSearchById(String id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.searchPath}/$id');
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load movie (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);

    final items = _extractMovieList(decoded);
    return items.map(_movieFromAnyJson).toList(growable: false);
  }

  Future<Movie> fetchMovieById(String id) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.movieDetailPath}/$id',
    );
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load movie (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);

    // OPhim detail: { data: { APP_DOMAIN_CDN_IMAGE, item: { ... episodes ... } } }
    if (decoded is Map &&
        decoded['data'] is Map &&
        (decoded['data'] as Map)['item'] is Map) {
      return _movieFromOphimDetail(decoded.cast<String, dynamic>());
    }

    if (decoded is! Map) {
      throw ApiException('Movie details endpoint must return a JSON object');
    }
    return _movieFromAnyJson(decoded.cast<String, dynamic>());
  }

  Future<MovieResponse> fetchMovieCategoryById(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.categoriesPath}/$id?page=$page&limit=$limit',
    );
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load movies (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    final items = _extractMovieList(decoded);

    // Unified logic to extract pagination info for OPhim API
    final pagination =
        (decoded is Map &&
            decoded['data'] is Map &&
            decoded['data']['params'] is Map &&
            decoded['data']['params']['pagination'] is Map)
        ? decoded['data']['params']['pagination'] as Map
        : (decoded is Map && decoded['pagination'] is Map)
        ? decoded['pagination'] as Map
        : null;

    final totalP = pagination != null
        ? (pagination['totalPages'] ?? pagination['total_pages'] ?? 1)
        : 1;
    final totalI = pagination != null
        ? (pagination['totalItems'] ??
              pagination['total_items'] ??
              items.length)
        : items.length;
    final totalIPP = pagination != null
        ? (pagination['totalItemsPerPage'] ??
              pagination['total_items_per_page'] ??
              items.length)
        : items.length;

    return MovieResponse(
      items: items.map(_movieFromAnyJson).toList(growable: false),
      currentPage: page,
      totalPages: totalP is int ? totalP : int.tryParse(totalP.toString()) ?? 1,
      totalItems: totalI is int
          ? totalI
          : int.tryParse(totalI.toString()) ?? items.length,
      totalItemsPerPage: totalIPP is int
          ? totalIPP
          : int.tryParse(totalIPP.toString()) ?? items.length,
    );
  }

  Future<MovieResponse> fetchMovies({int page = 1, int limit = 20}) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.moviesPath}?page=$page&limit=$limit',
    );
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load movies (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    final items = _extractMovieList(decoded);

    // Unified logic to extract pagination info for OPhim API
    final pagination =
        (decoded is Map &&
            decoded['data'] is Map &&
            decoded['data']['params'] is Map &&
            decoded['data']['params']['pagination'] is Map)
        ? decoded['data']['params']['pagination'] as Map
        : (decoded is Map && decoded['pagination'] is Map)
        ? decoded['pagination'] as Map
        : null;

    final totalP = pagination != null
        ? (pagination['totalPages'] ?? pagination['total_pages'] ?? 1)
        : 1;
    final totalI = pagination != null
        ? (pagination['totalItems'] ??
              pagination['total_items'] ??
              items.length)
        : items.length;
    final totalIPP = pagination != null
        ? (pagination['totalItemsPerPage'] ??
              pagination['total_items_per_page'] ??
              items.length)
        : items.length;

    return MovieResponse(
      items: items.map(_movieFromAnyJson).toList(growable: false),
      currentPage: page,
      totalPages: totalP is int ? totalP : int.tryParse(totalP.toString()) ?? 1,
      totalItems: totalI is int
          ? totalI
          : int.tryParse(totalI.toString()) ?? items.length,
      totalItemsPerPage: totalIPP is int
          ? totalIPP
          : int.tryParse(totalIPP.toString()) ?? items.length,
    );
  }

  Future<List<Movie>> fetchMovieBySlug(String slug) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.listAllsPath}/$slug',
    );
    final res = await _client.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('Failed to load movie (${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);

    final items = _extractMovieList(decoded);
    return items.map(_movieFromAnyJson).toList(growable: false);
  }
}

// Exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

List<Map<String, dynamic>> _extractMovieList(dynamic decoded) {
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }
  if (decoded is Map) {
    final data = decoded['data'];
    if (data is Map) {
      final items = data['items'];

      final cdn = data['APP_DOMAIN_CDN_IMAGE'];
      if (items is List) {
        return items.whereType<Map>().map((e) {
          final m = e.cast<String, dynamic>();
          // Carry the CDN base down to items so mapping can build poster URLs.
          return cdn == null
              ? m
              : <String, dynamic>{...m, 'APP_DOMAIN_CDN_IMAGE': cdn};
        }).toList();
      }
    }
  }

  throw ApiException(
    'Movies endpoint must return a JSON array OR {data:{items:[]}}',
  );
}

Movie _movieFromAnyJson(Map<String, dynamic> json) {
  // Heuristic: OPhim home item has `slug` + `thumb_url` and no `videoUrl`.
  if (json.containsKey('slug') && json.containsKey('thumb_url')) {
    return _movieFromOphimHomeItem(json);
  }
  // Generic movie mapping.
  return Movie.fromJson(json);
}

Movie _movieFromOphimHomeItem(Map<String, dynamic> json) {
  final cdn = _string(json['APP_DOMAIN_CDN_IMAGE']).isNotEmpty
      ? _string(json['APP_DOMAIN_CDN_IMAGE'])
      : 'https://img.ophim.live';

  // Home `items[]` doesn’t include APP_DOMAIN_CDN_IMAGE; we’ll resolve using the
  // known CDN base and standard upload path.
  final thumbFile = _string(json['thumb_url']);
  final poster = thumbFile.isEmpty
      ? ''
      : _resolveUrl(cdn, '/uploads/movies/$thumbFile');

  final categories = (json['category'] is List)
      ? (json['category'] as List)
      : const [];
  final genres = categories
      .whereType<Map>()
      .map((e) => _string(e['name']))
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);

  return Movie(
    id: _string(json['slug']).isNotEmpty
        ? _string(json['slug'])
        : _string(json['_id']),
    title: _string(json['name']).isNotEmpty
        ? _string(json['name'])
        : _string(json['origin_name']),
    posterUrl: poster,
    videoUrl: '',
    description: _string(json['origin_name']),
    year: _int(json['year']),
    type: _string(json['type']),
    lang: _string(json['lang']),
    country: (json['country'] as List? ?? [])
        .map<Country>((e) => Country.fromJson(e))
        .toList(),
    categories: (json['categories'] as List? ?? [])
        .map<Categoris>((e) => Categoris.fromJson(e))
        .toList(),
    genres: genres,
    episodes: const [],
    source: 'OPhim',
  );
}

Movie _movieFromOphimDetail(Map<String, dynamic> decoded) {
  final data = (decoded['data'] as Map).cast<String, dynamic>();
  final cdn = _string(data['APP_DOMAIN_CDN_IMAGE']).isNotEmpty
      ? _string(data['APP_DOMAIN_CDN_IMAGE'])
      : 'https://img.ophim.live';
  final item = (data['item'] as Map).cast<String, dynamic>();

  final thumbFile = _string(item['thumb_url']);
  final posterFile = _string(item['poster_url']);
  final poster = thumbFile.isNotEmpty
      ? _resolveUrl(cdn, '/uploads/movies/$thumbFile')
      : (posterFile.isNotEmpty
            ? _resolveUrl(cdn, '/uploads/movies/$posterFile')
            : '');

  final categories = (item['category'] is List)
      ? (item['category'] as List)
      : const [];
  final genres = categories
      .whereType<Map>()
      .map((e) => _string(e['name']))
      .where((s) => s.trim().isNotEmpty)
      .toList(growable: false);

  final contentRaw = _string(item['content']);
  final content = contentRaw.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  final episodes = _parseOphimEpisodes(item);
  final videoUrl = _firstPlayableUrlFromEpisodes(episodes);

  return Movie(
    id: _string(item['slug']).isNotEmpty
        ? _string(item['slug'])
        : _string(item['_id']),
    title: _string(item['name']).isNotEmpty
        ? _string(item['name'])
        : _string(item['origin_name']),
    posterUrl: poster,
    videoUrl: videoUrl,
    description: content.isNotEmpty ? content : _string(item['origin_name']),
    year: _int(item['year']),
    type: _string(item['type']),
    lang: _string(item['lang']),
    country: (item['country'] as List? ?? [])
        .map<Country>((e) => Country.fromJson(e))
        .toList(),
    categories: (item['categories'] as List? ?? [])
        .map<Categoris>((e) => Categoris.fromJson(e))
        .toList(),
    genres: genres,
    episodes: episodes,
    source: 'OPhim',
  );
}

List<EpisodeServer> _parseOphimEpisodes(Map<String, dynamic> item) {
  final raw = item['episodes'];
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => EpisodeServer.fromJson(e.cast<String, dynamic>()))
      .where((s) => s.serverData.isNotEmpty)
      .toList(growable: false);
}

String _firstPlayableUrlFromEpisodes(List<EpisodeServer> episodes) {
  if (episodes.isEmpty) return '';
  final firstServer = episodes.first;
  if (firstServer.serverData.isEmpty) return '';
  final first = firstServer.serverData.first;
  final url = first.bestUrl;
  return url;
}

String _string(dynamic v) => v == null ? '' : v.toString();
int? _int(dynamic v) => v is int ? v : int.tryParse(_string(v));

String _resolveUrl(String base, String path) {
  final b = Uri.parse(base);
  return b.resolve(path).toString();
}
