import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContinueWatchingItem {
  final String id;
  final String title;
  final String image;
  final String videoUrl;
  final String type;
  final int positionSeconds;
  final int durationSeconds;
  final String updatedAt;

  ContinueWatchingItem({
    required this.id,
    required this.title,
    required this.image,
    required this.videoUrl,
    required this.type,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'videoUrl': videoUrl,
      'type': type,
      'positionSeconds': positionSeconds,
      'durationSeconds': durationSeconds,
      'updatedAt': updatedAt,
    };
  }

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    return ContinueWatchingItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      type: json['type'] ?? '',
      positionSeconds: json['positionSeconds'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class ContinueWatchingService {
  static const String _key = 'continue_watching_items';

  static Future<List<ContinueWatchingItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List;
    final items = decoded
        .map((e) => ContinueWatchingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  static Future<void> saveProgress({
    required String title,
    required String image,
    required String videoUrl,
    required String type,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    if (durationSeconds <= 0) return;
    if (positionSeconds <= 5) return;

    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    final watchedRatio = positionSeconds / durationSeconds;

    if (watchedRatio >= 0.95) {
      items.removeWhere((e) => e.videoUrl == videoUrl);
      await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
      return;
    }

    final item = ContinueWatchingItem(
      id: videoUrl,
      title: title,
      image: image,
      videoUrl: videoUrl,
      type: type,
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      updatedAt: DateTime.now().toIso8601String(),
    );

    items.removeWhere((e) => e.videoUrl == videoUrl);
    items.insert(0, item);

    await prefs.setString(
      _key,
      jsonEncode(items.take(20).map((e) => e.toJson()).toList()),
    );
  }

  static Future<int> getSavedPosition(String videoUrl) async {
    final items = await getItems();
    for (final item in items) {
      if (item.videoUrl == videoUrl) return item.positionSeconds;
    }
    return 0;
  }

  static Future<void> removeItem(String videoUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    items.removeWhere((e) => e.videoUrl == videoUrl);
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }
}
