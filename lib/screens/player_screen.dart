import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/continue_watching_service.dart';
import '../services/api_service.dart';
import '../services/player_video_source_stub.dart'
    if (dart.library.io) '../services/player_video_source_io.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String videoUrl;
  final String image;
  final String type;
  final List<EpisodeItem>? episodes;
  final int? currentIndex;
  final String? seriesTitle;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.videoUrl,
    this.image = '',
    this.type = 'video',
    this.episodes,
    this.currentIndex,
    this.seriesTitle,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _showControls = true;
  bool _isBuffering = true;
  bool _isLocked = false;
  String? _errorText;

  Timer? _hideTimer;
  Timer? _progressTimer;
  Timer? _seekIndicatorTimer;
  Timer? _gestureOverlayTimer;

  bool _restoredPosition = false;
  String _seekIndicator = '';
  String _gestureOverlayText = '';
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
    _enterFullscreenMode();
  }

  Future<void> _setupPlayer() async {
    try {
      _controller = buildVideoController(widget.videoUrl);
      await _controller.initialize();
      _controller.addListener(_videoListener);
      await _controller.setLooping(false);
      await _controller.setPlaybackSpeed(_playbackSpeed);
      await _controller.play();

      setState(() {
        _isInitialized = true;
        _isBuffering = false;
        _errorText = null;
      });

      await _restoreSavedPosition();
      _startProgressSaving();
      _startAutoHideTimer();
    } catch (e) {
      setState(() {
        _errorText = 'تعذر تشغيل الفيديو';
        _isInitialized = false;
        _isBuffering = false;
      });
    }
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isInitialized) return;

    final value = _controller.value;

    if (_isBuffering != value.isBuffering) {
      setState(() => _isBuffering = value.isBuffering);
    }

    if (value.hasError && _errorText == null) {
      setState(() {
        _errorText = value.errorDescription ?? 'حدث خطأ أثناء تشغيل الفيديو';
      });
    }

    if (mounted && !_isLocked) {
      setState(() {});
    }
  }

  Future<void> _restoreSavedPosition() async {
    if (_restoredPosition) return;

    final savedSeconds =
        await ContinueWatchingService.getSavedPosition(widget.videoUrl);

    if (savedSeconds > 5 && _isInitialized) {
      final duration = _controller.value.duration;
      final target = Duration(seconds: savedSeconds);
      await _controller.seekTo(target > duration ? duration : target);
    }

    _restoredPosition = true;
  }

  void _startProgressSaving() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isInitialized) return;

      final value = _controller.value;

      await ContinueWatchingService.saveProgress(
        title: widget.title,
        image: widget.image,
        videoUrl: widget.videoUrl,
        type: widget.type,
        positionSeconds: value.position.inSeconds,
        durationSeconds: value.duration.inSeconds,
      );
    });
  }

  void _startAutoHideTimer() {
    _hideTimer?.cancel();

    if (_isLocked) return;

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _isLocked) return;

      if (_controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLocked) return;

    setState(() => _showControls = !_showControls);

    if (_showControls) {
      _startAutoHideTimer();
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false;
      } else {
        _showControls = true;
      }
    });

    if (!_isLocked) {
      _startAutoHideTimer();
    }
  }

  Future<void> _retryPlayer() async {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    _gestureOverlayTimer?.cancel();

    try {
      await _controller.pause();
      await _controller.dispose();
    } catch (_) {}

    setState(() {
      _isInitialized = false;
      _isBuffering = true;
      _errorText = null;
      _restoredPosition = false;
      _seekIndicator = '';
      _gestureOverlayText = '';
    });

    await _setupPlayer();
  }

  void _showSeekMessage(String text) {
    _seekIndicatorTimer?.cancel();

    setState(() {
      _seekIndicator = text;
    });

    _seekIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _seekIndicator = '';
      });
    });
  }

  void _showGestureOverlay(String text) {
    _gestureOverlayTimer?.cancel();

    setState(() {
      _gestureOverlayText = text;
    });

    _gestureOverlayTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _gestureOverlayText = '';
      });
    });
  }

  Future<void> _seekForward() async {
    if (!_isInitialized) return;

    final current = _controller.value.position;
    final duration = _controller.value.duration;
    final target = current + const Duration(seconds: 10);

    await _controller.seekTo(target > duration ? duration : target);
    _showSeekMessage('⏩ 10s');
    _startAutoHideTimer();
  }

  Future<void> _seekBackward() async {
    if (!_isInitialized) return;

    final current = _controller.value.position;
    final target = current - const Duration(seconds: 10);

    await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
    _showSeekMessage('⏪ 10s');
    _startAutoHideTimer();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;

    if (_controller.value.position >= _controller.value.duration) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
    } else if (_controller.value.isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }

    setState(() {});
    _startAutoHideTimer();
  }



  Future<void> _changePlaybackSpeed(double speed) async {
    if (!_isInitialized) return;
    _playbackSpeed = speed;
    await _controller.setPlaybackSpeed(speed);
    _showGestureOverlay('السرعة ${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 1)}x');
    if (mounted) setState(() {});
    _startAutoHideTimer();
  }

  Future<void> _showSpeedSheet() async {
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF0B0E17),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'سرعة التشغيل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...speeds.map((speed) {
                  final active = speed == _playbackSpeed;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: active
                          ? const Color(0xFFD5B13E).withOpacity(.12)
                          : Colors.white.withOpacity(.03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: active
                              ? const Color(0xFFD5B13E)
                              : const Color(0xFF1B2133),
                        ),
                      ),
                      title: Text(
                        '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 2)}x',
                        style: TextStyle(
                          color: active ? const Color(0xFFD5B13E) : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, speed),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await _changePlaybackSpeed(selected);
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_isLocked) return;

    final width = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;

    if (dx < width / 2) {
      _seekBackward();
    } else {
      _seekForward();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isLocked || !_showControls) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.localPosition.dx;
    final delta = details.delta.dy;

    if (dx > screenWidth / 2) {
      final currentVolume = _controller.value.volume;
      final nextVolume = (currentVolume - delta / 300).clamp(0.0, 1.0);
      _controller.setVolume(nextVolume);
      _showGestureOverlay('🔊 ${(nextVolume * 100).round()}%');
    } else {
      final brightnessLevel = ((0.5 - delta / 300).clamp(0.0, 1.0));
      _showGestureOverlay('☀️ ${(brightnessLevel * 100).round()}%');
    }
  }

  bool get _hasEpisodes =>
      widget.episodes != null && widget.currentIndex != null && widget.seriesTitle != null;

  bool get _hasPreviousEpisode =>
      _hasEpisodes && widget.currentIndex! > 0;

  bool get _hasNextEpisode =>
      _hasEpisodes && widget.currentIndex! < widget.episodes!.length - 1;

  void _openEpisodeAt(int newIndex) {
    if (!_hasEpisodes) return;
    final episode = widget.episodes![newIndex];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: '${widget.seriesTitle} - ${episode.title}',
          videoUrl: episode.videoUrl,
          image: widget.image,
          type: 'حلقة',
          episodes: widget.episodes,
          currentIndex: newIndex,
          seriesTitle: widget.seriesTitle,
        ),
      ),
    );
  }

  void _nextEpisode() {
    if (_hasNextEpisode) {
      _openEpisodeAt(widget.currentIndex! + 1);
    }
  }

  void _previousEpisode() {
    if (_hasPreviousEpisode) {
      _openEpisodeAt(widget.currentIndex! - 1);
    }
  }

  void _enterFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    _gestureOverlayTimer?.cancel();

    if (_isInitialized) {
      final value = _controller.value;
      ContinueWatchingService.saveProgress(
        title: widget.title,
        image: widget.image,
        videoUrl: widget.videoUrl,
        type: widget.type,
        positionSeconds: value.position.inSeconds,
        durationSeconds: value.duration.inSeconds,
      );
    }

    try {
      _controller.removeListener(_videoListener);
      _controller.dispose();
    } catch (_) {}

    _exitFullscreenMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnded = _isInitialized &&
        _controller.value.duration > Duration.zero &&
        _controller.value.position >= _controller.value.duration;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: _handleDoubleTap,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          child: Stack(
            children: [
              Positioned.fill(
                child: _errorText != null
                    ? _ErrorView(
                        errorText: _errorText!,
                        onRetry: _retryPlayer,
                      )
                    : _isInitialized
                        ? FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _controller.value.size.width,
                              height: _controller.value.size.height,
                              child: VideoPlayer(_controller),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFD5B13E),
                            ),
                          ),
              ),

              if (_isBuffering && _errorText == null)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD5B13E),
                    ),
                  ),
                ),

              if (_seekIndicator.isNotEmpty && _errorText == null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _seekIndicator,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

              if (_gestureOverlayText.isNotEmpty && _errorText == null)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _gestureOverlayText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_errorText == null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 180,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(.72),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_errorText == null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 220,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(.78),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_showControls && !_isLocked && _errorText == null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(.28),
                    child: Column(
                      children: [
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsetsDirectional.only(end: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: _showSpeedSheet,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(76, 42),
                                    ),
                                    icon: const Icon(Icons.speed_rounded, size: 18),
                                    label: Text(
                                      '${_playbackSpeed.toStringAsFixed(_playbackSpeed.truncateToDouble() == _playbackSpeed ? 0 : 1)}x',
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _toggleLock,
                                  icon: const Icon(
                                    Icons.lock_open_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_isInitialized)
                          Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.34),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_hasPreviousEpisode)
                              IconButton(
                                onPressed: _previousEpisode,
                                iconSize: 34,
                                color: Colors.white,
                                icon: const Icon(Icons.skip_previous_rounded),
                              ),
                            IconButton(
                              onPressed: _seekBackward,
                              iconSize: 42,
                              color: Colors.white,
                              icon: const Icon(Icons.replay_10_rounded),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFFD5B13E),
                              child: IconButton(
                                onPressed: _togglePlayPause,
                                iconSize: 34,
                                color: Colors.black,
                                icon: Icon(
                                  isEnded
                                      ? Icons.replay_rounded
                                      : (_controller.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: _seekForward,
                              iconSize: 42,
                              color: Colors.white,
                              icon: const Icon(Icons.forward_10_rounded),
                            ),
                            if (_hasNextEpisode)
                              IconButton(
                                onPressed: _nextEpisode,
                                iconSize: 34,
                                color: Colors.white,
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                          ],
                        ),
                        const Spacer(),
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  colors: VideoProgressColors(
                                    playedColor: const Color(0xFFD5B13E),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(
                                        _controller.value.position,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(
                                        _controller.value.duration,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_isLocked && _errorText == null)
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 12,
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _toggleLock,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.45),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (kIsWeb && _showControls)
                const Positioned(
                  bottom: 18,
                  left: 18,
                  child: SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String errorText;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.errorText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD5B13E),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
