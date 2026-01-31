import 'package:old_man_browser/models/categoris.dart';
import 'package:old_man_browser/models/country.dart';

import 'episode.dart';

class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final String videoUrl;
  final String description;
  final int? year;
  final String? type;
  final String? lang;
  final List<Country> country;
  final List<Categoris> categories;
  final List<String> genres;
  final List<EpisodeServer> episodes;

  const Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.videoUrl,
    required this.description,
    required this.country,
    required this.categories,
    required this.genres,
    this.year,
    this.type,
    this.lang,
    this.episodes = const [],
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    final genresRaw = json['genres'];
    final genres = (genresRaw is List)
        ? genresRaw.map((e) => e.toString()).toList()
        : <String>[];

    final episodesRaw = json['episodes'];
    final episodes = (episodesRaw is List)
        ? episodesRaw
              .whereType<Map>()
              .map((e) => EpisodeServer.fromJson(e.cast<String, dynamic>()))
              .toList()
        : <EpisodeServer>[];

    return Movie(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      posterUrl: (json['posterUrl'] ?? '').toString(),
      videoUrl: (json['videoUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse('${json['year']}'),
      type: json['type']?.toString(),
      lang: json['lang']?.toString(),
      country: (json['country'] as List? ?? [])
          .map<Country>((e) => Country.fromJson(e))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map<Categoris>((e) => Categoris.fromJson(e))
          .toList(),
      genres: genres,
      episodes: episodes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'videoUrl': videoUrl,
      'description': description,
      'year': year,
      'type': type,
      'lang': lang,
      'country': country.map((e) => e.toJson()).toList(),
      'categories': categories.map((e) => e.toJson()).toList(),
      'genres': genres,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}
