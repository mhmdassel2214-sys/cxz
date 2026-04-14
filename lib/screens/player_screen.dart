import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/continue_watching_service.dart';
import '../services/api_service.dart';

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
  late final Player _player;
  late final VideoController _videoController;

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

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _buffer = Duration.zero;
  bool _isPlaying = false;
  double _volume = 100.0;
  double _fakeBrightness = 50.0;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _bufferSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _completedSub;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _setupPlayer();
    _enterFullscreenMode();
  }

  Future<void> _setupPlayer() async {
    try {
      await _disposeSubscriptions();

      _playingSub = _player.stream.playing.listen((playing) {
        if (!mounted) return;
        setState(() => _isPlaying = playing);
      });

      _bufferingSub = _player.stream.buffering.listen((buffering) {
        if (!mounted) return;
        setState(() => _isBuffering = buffering);
      });

      _positionSub = _player.stream.position.listen((position) {
        if (!mounted) return;
        setState(() => _position = position);
      });

      _durationSub = _player.stream.duration.listen((duration) {
        if (!mounted) return;
        setState(() => _duration = duration);
      });

      _bufferSub = _player.stream.buffer.listen((buffer) {
        if (!mounted) return;
        setState(() => _buffer = buffer);
      });

      _errorSub = _player.stream.error.listen((error) {
        if (!mounted) return;
        setState(() {
          _errorText = error;
          _isBuffering = false;
        });
      });

      _completedSub = _player.stream.completed.listen((completed) async {
        if (!mounted || !completed) return;
        setState(() {
          _isPlaying = false;
        });
      });

      await _player.setRate(_playbackSpeed);
      await _player.setVolume(_volume);
      await _player.open(Media(widget.videoUrl));

      setState(() {
        _isInitialized = true;
        _isBuffering = false;
        _errorText = null;
      });

      await _restoreSavedPosition();
      await _player.play();

      _startProgressSaving();
      _startAutoHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'تعذر تشغيل الفيديو';
        _isInitialized = false;
        _isBuffering = false;
      });
    }
  }

  Future<void> _disposeSubscriptions() async {
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _bufferSub?.cancel();
    await _errorSub?.cancel();
    await _completedSub?.cancel();

    _playingSub = null;
    _bufferingSub = null;
    _positionSub = null;
    _durationSub = null;
    _bufferSub = null;
    _errorSub = null;
    _completedSub = null;
  }

  Future<void> _restoreSavedPosition() async {
    if (_restoredPosition) return;

    final savedSeconds =
        await ContinueWatchingService.getSavedPosition(widget.videoUrl);

    if (savedSeconds > 5) {
      final target = Duration(seconds: savedSeconds);
      final safeTarget = target > _duration ? _duration : target;
      await _player.seek(safeTarget);
    }

    _restoredPosition = true;
  }

  void _startProgressSaving() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isInitialized) return;

      await ContinueWatchingService.saveProgress(
        title: widget.title,
        image: widget.image,
        videoUrl: widget.videoUrl,
        type: widget.type,
        positionSeconds: _position.inSeconds,
        durationSeconds: _duration.inSeconds,
      );
    });
  }

  void _startAutoHideTimer() {
    _hideTimer?.cancel();

    if (_isLocked) return;

    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _isLocked) return;

      if (_isPlaying) {
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
      await _player.stop();
    } catch (_) {}

    setState(() {
      _isInitialized = false;
      _isBuffering = true;
      _errorText = null;
      _restoredPosition = false;
      _seekIndicator = '';
      _gestureOverlayText = '';
      _position = Duration.zero;
      _duration = Duration.zero;
      _buffer = Duration.zero;
      _isPlaying = false;
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

    final target = _position + const Duration(seconds: 10);
    final safeTarget = target > _duration ? _duration : target;

    await _player.seek(safeTarget);
    _showSeekMessage('⏩ 10s');
    _startAutoHideTimer();
  }

  Future<void> _seekBackward() async {
    if (!_isInitialized) return;

    final target = _position - const Duration(seconds: 10);
    final safeTarget = target < Duration.zero ? Duration.zero : target;

    await _player.seek(safeTarget);
    _showSeekMessage('⏪ 10s');
    _startAutoHideTimer();
  }

  Future<void> _togglePlayPause() async {
    if (!_isInitialized) return;

    final isEnded = _duration > Duration.zero && _position >= _duration;

    if (isEnded) {
      await _player.seek(Duration.zero);
      await _player.play();
    } else if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }

    _startAutoHideTimer();
  }

  Future<void> _changePlaybackSpeed(double speed) async {
    if (!_isInitialized) return;
    _playbackSpeed = speed;
    await _player.setRate(speed);
    _showGestureOverlay(
      'السرعة ${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 0 : 1)}x',
    );
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
      final nextVolume = (_volume - delta / 3).clamp(0.0, 100.0);
      _volume = nextVolume;
      _player.setVolume(_volume);
      _showGestureOverlay('🔊 ${_volume.round()}%');
    } else {
      _fakeBrightness = (_fakeBrightness - delta / 3).clamp(0.0, 100.0);
      _showGestureOverlay('☀️ ${_fakeBrightness.round()}%');
    }
  }

  bool get _hasEpisodes =>
      widget.episodes != null &&
      widget.currentIndex != null &&
      widget.seriesTitle != null;

  bool get _hasPreviousEpisode => _hasEpisodes && widget.currentIndex! > 0;

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

  double _progressValue() {
    if (_duration.inMilliseconds <= 0) return 0;
    return _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble();
  }

  double _bufferValue() {
    if (_duration.inMilliseconds <= 0) return 0;
    return _buffer.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble();
  }

  Future<void> _onSeekChanged(double value) async {
    final target = Duration(milliseconds: value.round());
    await _player.seek(target);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();
    _seekIndicatorTimer?.cancel();
    _gestureOverlayTimer?.cancel();

    if (_isInitialized) {
      ContinueWatchingService.saveProgress(
        title: widget.title,
        image: widget.image,
        videoUrl: widget.videoUrl,
        type: widget.type,
        positionSeconds: _position.inSeconds,
        durationSeconds: _duration.inSeconds,
      );
    }

    _disposeSubscriptions();
    _player.dispose();
    _exitFullscreenMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnded =
        _isInitialized && _duration > Duration.zero && _position >= _duration;

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
                        ? Video(
                            controller: _videoController,
                            controls: (state) => const SizedBox.shrink(),
                            fit: BoxFit.contain,
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
                                  margin:
                                      const EdgeInsetsDirectional.only(end: 4),
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
                                    icon: const Icon(
                                      Icons.speed_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '${_playbackSpeed.toStringAsFixed(_playbackSpeed.truncateToDouble() == _playbackSpeed ? 0 : 1)}x',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.34),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
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
                                      : (_isPlaying
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
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 0,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                          overlayRadius: 0,
                                        ),
                                        activeTrackColor:
                                            Colors.white.withOpacity(.20),
                                        inactiveTrackColor:
                                            Colors.white.withOpacity(.10),
                                      ),
                                      child: Slider(
                                        value: _bufferValue().clamp(
                                          0,
                                          _duration.inMilliseconds.toDouble() <= 0
                                              ? 1
                                              : _duration.inMilliseconds.toDouble(),
                                        ),
                                        max: _duration.inMilliseconds.toDouble() <= 0
                                            ? 1
                                            : _duration.inMilliseconds.toDouble(),
                                        onChanged: (_) {},
                                      ),
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbColor: const Color(0xFFD5B13E),
                                        activeTrackColor:
                                            const Color(0xFFD5B13E),
                                        inactiveTrackColor:
                                            Colors.transparent,
                                      ),
                                      child: Slider(
                                        value: _progressValue().clamp(
                                          0,
                                          _duration.inMilliseconds.toDouble() <= 0
                                              ? 1
                                              : _duration.inMilliseconds.toDouble(),
                                        ),
                                        max: _duration.inMilliseconds.toDouble() <= 0
                                            ? 1
                                            : _duration.inMilliseconds.toDouble(),
                                        onChanged: (value) => _onSeekChanged(value),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDuration(_duration),
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