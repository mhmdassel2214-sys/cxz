import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController buildVideoController(String source) {
  if (source.startsWith('/')) {
    return VideoPlayerController.file(File(source));
  }

  return VideoPlayerController.networkUrl(Uri.parse(source));
}
