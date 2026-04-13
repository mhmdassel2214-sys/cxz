import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

const AndroidNotificationChannel kAsMoviesNotificationChannel =
    AndroidNotificationChannel(
  'asmovies_notifications',
  'AsMovies Notifications',
  description: 'Notifications for new movies and episodes.',
  importance: Importance.high,
);

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get instance => _plugin;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_asmovies');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(kAsMoviesNotificationChannel);
  }

  static Future<void> showRichNotification({
    required int id,
    required String? title,
    required String? body,
    String? imageUrl,
  }) async {
    if (kIsWeb) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        kAsMoviesNotificationChannel.id,
        kAsMoviesNotificationChannel.name,
        channelDescription: kAsMoviesNotificationChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_stat_asmovies',
        styleInformation: await _buildStyleInformation(imageUrl),
      ),
    );

    await _plugin.show(id, title, body, details);
  }

  static Future<StyleInformation?> _buildStyleInformation(String? imageUrl) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return const BigTextStyleInformation('');
    }

    try {
      final imageBytes = await _downloadBytes(imageUrl);
      if (imageBytes == null || imageBytes.isEmpty) {
        return const BigTextStyleInformation('');
      }

      final bigPicture = ByteArrayAndroidBitmap(imageBytes);
      return BigPictureStyleInformation(
        bigPicture,
        largeIcon: bigPicture,
        hideExpandedLargeIcon: false,
      );
    } catch (_) {
      return const BigTextStyleInformation('');
    }
  }

  static Future<Uint8List?> _downloadBytes(String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl), headers: const {
            'cache-control': 'no-cache',
          })
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
