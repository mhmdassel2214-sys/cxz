import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieItem {
  final String id;
  final String title;
  final String image;
  final String category;
  final String rating;
  final String videoUrl;
  final bool isNew;
  final bool isTop;
  final bool isFeatured;
  final String date;
  final String badge;
  final String description;

  MovieItem({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.rating,
    required this.videoUrl,
    required this.isNew,
    required this.isTop,
    required this.isFeatured,
    required this.date,
    required this.badge,
    required this.description,
  });

  factory MovieItem.fromJson(Map<String, dynamic> json) {
    return MovieItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      videoUrl: (json['videoUrl'] ?? json['url'])?.toString() ?? '',
      isNew: json['isNew'] == true,
      isTop: json['isTop'] == true,
      isFeatured: json['isFeatured'] == true,
      date: json['date']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class EpisodeItem {
  final String title;
  final String videoUrl;

  EpisodeItem({
    required this.title,
    required this.videoUrl,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      title: json['title']?.toString() ?? '',
      videoUrl: (json['videoUrl'] ?? json['url'])?.toString() ?? '',
    );
  }
}

class SeasonItem {
  final int season;
  final String seasonName;
  final List<EpisodeItem> episodes;

  SeasonItem({
    required this.season,
    required this.seasonName,
    required this.episodes,
  });

  factory SeasonItem.fromJson(Map<String, dynamic> json) {
    final rawSeason = json['season'];
    final parsedSeason = rawSeason is int
        ? rawSeason
        : int.tryParse(rawSeason?.toString() ?? '') ?? 1;

    return SeasonItem(
      season: parsedSeason,
      seasonName: json['seasonName']?.toString().trim().isNotEmpty == true
          ? json['seasonName'].toString().trim()
          : 'الموسم $parsedSeason',
      episodes: (json['episodes'] as List? ?? [])
          .whereType<Map>()
          .map((e) => EpisodeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SeriesItem {
  final String id;
  final String title;
  final String image;
  final String category;
  final String rating;
  final bool isNew;
  final bool isTop;
  final bool isFeatured;
  final String date;
  final String badge;
  final String description;
  final List<SeasonItem> seasons;

  SeriesItem({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.rating,
    required this.isNew,
    required this.isTop,
    required this.isFeatured,
    required this.date,
    required this.badge,
    required this.description,
    required this.seasons,
  });

  List<EpisodeItem> get episodes =>
      seasons.expand((season) => season.episodes).toList(growable: false);

  int get totalEpisodes =>
      seasons.fold(0, (sum, season) => sum + season.episodes.length);

  bool get hasSeasons => seasons.length > 1 ||
      (seasons.isNotEmpty &&
          !(seasons.first.season == 1 &&
              seasons.first.seasonName == 'الموسم 1'));

  factory SeriesItem.fromJson(Map<String, dynamic> json) {
    final seasonsJson = (json['seasons'] as List? ?? [])
        .whereType<Map>()
        .map((e) => SeasonItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final legacyEpisodes = (json['episodes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => EpisodeItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final normalizedSeasons = seasonsJson.isNotEmpty
        ? seasonsJson
        : [
            SeasonItem(
              season: 1,
              seasonName: 'الموسم 1',
              episodes: legacyEpisodes,
            ),
          ];

    return SeriesItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      rating: json['rating']?.toString() ?? '',
      isNew: json['isNew'] == true,
      isTop: json['isTop'] == true,
      isFeatured: json['isFeatured'] == true,
      date: json['date']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      seasons: normalizedSeasons,
    );
  }
}

class LiveChannel {
  final String title;
  final String url;
  final String category;
  final String image;

  LiveChannel({
    required this.title,
    required this.url,
    required this.category,
    required this.image,
  });

  factory LiveChannel.fromJson(Map<String, dynamic> json) {
    return LiveChannel(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }
}

class ApiService {
  static const String moviesUrl = 'https://asmovies-watch.pages.dev/movies.json';
  static const String seriesUrl = 'https://asmovies-watch.pages.dev/series.json';
  static const String liveUrl = 'https://asmovies-watch.pages.dev/live.json';

  static Future<List<MovieItem>> fetchMovies() async {
    final response = await http.get(Uri.parse(moviesUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['movies'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((e) => MovieItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('فشل تحميل الأفلام');
  }

  static Future<List<SeriesItem>> fetchSeries() async {
    final response = await http.get(Uri.parse(seriesUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['series'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((e) => SeriesItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('فشل تحميل المسلسلات');
  }

  static Future<List<LiveChannel>> fetchLiveChannels() async {
    final response = await http.get(Uri.parse(liveUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['channels'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((e) => LiveChannel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('فشل تحميل البث المباشر');
  }
}
