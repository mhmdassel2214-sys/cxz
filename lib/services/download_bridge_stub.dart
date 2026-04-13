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
  static Stream<DownloadBridgeUpdate> get updates => const Stream.empty();

  static Future<void> initialize() async {}

  static Future<DownloadBridgeEnqueueResult> enqueue({
    required String url,
    required String title,
    required String fileName,
    required String localPath,
    required String videoUrl,
  }) async {
    return DownloadBridgeEnqueueResult(
      taskId: videoUrl,
      fileName: fileName,
      localPath: localPath,
    );
  }

  static Future<void> cancel(String taskId) async {}
}
