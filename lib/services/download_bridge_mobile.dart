import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

class DownloadBridgeUpdate {
  final String taskId;
  final String videoUrl;
  final String status;
  final double progress;
  final String localPath;
  final String errorMessage;

  const DownloadBridgeUpdate({
    required this.taskId,
    required this.videoUrl,
    required this.status,
    this.progress = 0,
    this.localPath = '',
    this.errorMessage = '',
  });
}

class DownloadBridgeEnqueueResult {
  final String taskId;
  final String fileName;
  final String localPath;

  const DownloadBridgeEnqueueResult({
    required this.taskId,
    required this.fileName,
    required this.localPath,
  });
}

class DownloadBridge {
  static final StreamController<DownloadBridgeUpdate> _controller =
      StreamController<DownloadBridgeUpdate>.broadcast();
  static bool _initialized = false;

  static Stream<DownloadBridgeUpdate> get updates => _controller.stream;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FileDownloader().configure(
      globalConfig: [
        (Config.requestTimeout, const Duration(hours: 2)),
      ],
    );

    FileDownloader()
        .registerCallbacks()
        .configureNotification(
          running: const TaskNotification(
            'جاري التحميل',
            '{displayName} • {progress}',
          ),
          complete: const TaskNotification(
            'اكتمل التحميل',
            '{displayName}',
          ),
          error: const TaskNotification(
            'فشل التحميل',
            '{displayName}',
          ),
          paused: const TaskNotification(
            'تم إيقاف التحميل',
            '{displayName}',
          ),
          canceled: const TaskNotification(
            'تم إلغاء التحميل',
            '{displayName}',
          ),
          progressBar: true,
          tapOpensFile: false,
        );

    FileDownloader().updates.listen((update) {
      switch (update) {
        case TaskStatusUpdate():
          _controller.add(
            DownloadBridgeUpdate(
              taskId: update.task.taskId,
              videoUrl: update.task.metaData,
              status: update.status.name,
              progress: 0,
              localPath: '',
              errorMessage: update.exception?.description ?? '',
            ),
          );
        case TaskProgressUpdate():
          _controller.add(
            DownloadBridgeUpdate(
              taskId: update.task.taskId,
              videoUrl: update.task.metaData,
              status: 'running',
              progress: update.progress,
              localPath: '',
            ),
          );
      }
    });

    await FileDownloader().start();
  }

  static Future<DownloadBridgeEnqueueResult> enqueue({
    required String url,
    required String title,
    required String fileName,
    required String localPath,
    required String videoUrl,
  }) async {
    final task = DownloadTask(
      url: url,
      filename: fileName,
      displayName: title,
      metaData: videoUrl,
      directory: 'offline_media',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 2,
    );

    await FileDownloader().enqueue(task);

    return DownloadBridgeEnqueueResult(
      taskId: task.taskId,
      fileName: fileName,
      localPath: localPath,
    );
  }

  static Future<void> cancel(String taskId) async {
    await FileDownloader().cancelTasksWithIds([taskId]);
  }
}
