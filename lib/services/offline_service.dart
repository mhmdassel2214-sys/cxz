import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineItem {
  final String title;
  final String image;
  final String videoUrl;
  final String type;
  final String status;
  final double progress;
  final String localPath;
  final String errorMessage;
  final int downloadedBytes;
  final int totalBytes;

  const OfflineItem({
    required this.title,
    required this.image,
    required this.videoUrl,
    required this.type,
    this.status = 'queued',
    this.progress = 0,
    this.localPath = '',
    this.errorMessage = '',
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  bool get isDownloading => status == 'downloading';
  bool get isDownloaded => status == 'downloaded' && localPath.isNotEmpty;
  bool get isStreamOnly => status == 'stream_only';
  bool get hasError => status == 'failed';

  OfflineItem copyWith({
    String? title,
    String? image,
    String? videoUrl,
    String? type,
    String? status,
    double? progress,
    String? localPath,
    String? errorMessage,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return OfflineItem(
      title: title ?? this.title,
      image: image ?? this.image,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'image': image,
        'videoUrl': videoUrl,
        'type': type,
        'status': status,
        'progress': progress,
        'localPath': localPath,
        'errorMessage': errorMessage,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
      };

  factory OfflineItem.fromJson(Map<String, dynamic> json) {
    return OfflineItem(
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'queued',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      localPath: json['localPath'] ?? '',
      errorMessage: json['errorMessage'] ?? '',
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class OfflineService {
  static const String _key = 'offline_items';
  static final StreamController<List<OfflineItem>> _streamController =
      StreamController<List<OfflineItem>>.broadcast();
  static final Map<String, bool> _cancelFlags = {};

  static Stream<List<OfflineItem>> watchItems() async* {
    yield await getItems();
    yield* _streamController.stream;
  }

  static bool isDirectDownloadable(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.mp4') ||
        lower.contains('.mkv') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.avi');
  }

  static Future<List<OfflineItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => OfflineItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> _saveItems(List<OfflineItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    _streamController.add(items);
  }

  static Future<OfflineItem> addItem(OfflineItem item) async {
    final items = await getItems();
    final existingIndex = items.indexWhere((e) => e.videoUrl == item.videoUrl);
    if (existingIndex != -1) {
      final existing = items[existingIndex];
      if (existing.isDownloaded || existing.isDownloading || existing.isStreamOnly) {
        _streamController.add(items);
        return existing;
      }
      items.removeAt(existingIndex);
    }

    if (!isDirectDownloadable(item.videoUrl)) {
      final streamItem = item.copyWith(status: 'stream_only', progress: 0);
      items.insert(0, streamItem);
      await _saveItems(items);
      return streamItem;
    }

    final queuedItem = item.copyWith(status: 'downloading', progress: 0);
    items.insert(0, queuedItem);
    await _saveItems(items);
    unawaited(_downloadFile(queuedItem));
    return queuedItem;
  }

  static Future<void> _downloadFile(OfflineItem item) async {
    final uri = Uri.tryParse(item.videoUrl);
    if (uri == null) {
      await _markFailed(item.videoUrl, 'الرابط غير صالح');
      return;
    }

    http.Client? client;
    IOSink? sink;
    File? file;

    try {
      _cancelFlags[item.videoUrl] = false;
      client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('فشل التحميل: ${response.statusCode}');
      }

      final dir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory('${dir.path}/offline_media');
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      final fileName = _buildFileName(item.videoUrl, item.title);
      file = File('${offlineDir.path}/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
      sink = file.openWrite();

      final total = response.contentLength ?? 0;
      var received = 0;
      var lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

      await for (final chunk in response.stream) {
        if (_cancelFlags[item.videoUrl] == true) {
          throw FileSystemException('cancelled');
        }
        sink.add(chunk);
        received += chunk.length;

        final now = DateTime.now();
        final shouldEmit = now.difference(lastEmit).inMilliseconds > 250;
        if (shouldEmit || (total > 0 && received >= total)) {
          lastEmit = now;
          await _updateItem(
            item.videoUrl,
            (current) => current.copyWith(
              status: 'downloading',
              progress: total > 0 ? (received / total).clamp(0, 1) : current.progress,
              downloadedBytes: received,
              totalBytes: total,
              errorMessage: '',
            ),
          );
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      await _updateItem(
        item.videoUrl,
        (current) => current.copyWith(
          status: 'downloaded',
          progress: 1,
          localPath: file!.path,
          downloadedBytes: received,
          totalBytes: total,
          errorMessage: '',
        ),
      );
    } catch (e) {
      if ('$e'.contains('cancelled')) {
        try {
          await sink?.close();
        } catch (_) {}
        if (file != null && await file.exists()) {
          await file.delete();
        }
        final items = await getItems();
        items.removeWhere((element) => element.videoUrl == item.videoUrl);
        await _saveItems(items);
      } else {
        try {
          await sink?.close();
        } catch (_) {}
        if (file != null && await file.exists()) {
          await file.delete();
        }
        await _markFailed(item.videoUrl, 'فشل التحميل');
      }
    } finally {
      client?.close();
      _cancelFlags.remove(item.videoUrl);
    }
  }

  static Future<void> _markFailed(String videoUrl, String message) async {
    await _updateItem(
      videoUrl,
      (current) => current.copyWith(
        status: 'failed',
        errorMessage: message,
      ),
    );
  }

  static Future<void> _updateItem(
    String videoUrl,
    OfflineItem Function(OfflineItem current) builder,
  ) async {
    final items = await getItems();
    final index = items.indexWhere((e) => e.videoUrl == videoUrl);
    if (index == -1) return;
    items[index] = builder(items[index]);
    await _saveItems(items);
  }

  static Future<void> removeItem(String videoUrl) async {
    _cancelFlags[videoUrl] = true;
    final items = await getItems();
    final index = items.indexWhere((e) => e.videoUrl == videoUrl);
    if (index == -1) return;
    final item = items[index];
    if (item.localPath.isNotEmpty) {
      final file = File(item.localPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    items.removeAt(index);
    await _saveItems(items);
  }

  static Future<void> clearAll() async {
    final items = await getItems();
    for (final item in items) {
      _cancelFlags[item.videoUrl] = true;
      if (item.localPath.isNotEmpty) {
        final file = File(item.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _streamController.add(const []);
  }

  static Future<String> resolvePlayableUrl(OfflineItem item) async {
    if (item.localPath.isNotEmpty) {
      final file = File(item.localPath);
      if (await file.exists()) {
        return file.path;
      }
    }
    return item.videoUrl;
  }

  static String _buildFileName(String url, String title) {
    final uri = Uri.tryParse(url);
    final ext = _extractExtension(url);
    final titlePart = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9ء-ي]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final tail = uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : 'video';
    final safeTail = tail.split('?').first.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '${titlePart.isEmpty ? safeTail : titlePart}_$stamp$ext';
  }

  static String _extractExtension(String url) {
    final lower = url.toLowerCase();
    for (final ext in ['.mp4', '.mkv', '.webm', '.mov', '.avi']) {
      if (lower.contains(ext)) return ext;
    }
    return '.mp4';
  }
}
