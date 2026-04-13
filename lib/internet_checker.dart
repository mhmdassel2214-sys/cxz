import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'services/connectivity_signal.dart';
import 'widgets/connection_banner.dart';

class InternetChecker extends StatefulWidget {
  final Widget child;

  const InternetChecker({super.key, required this.child});

  @override
  State<InternetChecker> createState() => _InternetCheckerState();
}

class _InternetCheckerState extends State<InternetChecker> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _restoredTimer;
  Timer? _offlinePollTimer;

  bool _isOffline = false;
  bool _showRestored = false;
  bool _isChecking = false;
  bool _lastKnownOnline = true;

  @override
  void initState() {
    super.initState();
    _initConnectivityWatcher();
  }

  Future<void> _initConnectivityWatcher() async {
    await _refreshConnectionState(showRestoredWhenBack: false);

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      await _refreshConnectionState(showRestoredWhenBack: true);
    });
  }

  void _startOfflinePolling() {
    _offlinePollTimer?.cancel();
    _offlinePollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _refreshConnectionState(showRestoredWhenBack: true);
    });
  }

  void _stopOfflinePolling() {
    _offlinePollTimer?.cancel();
    _offlinePollTimer = null;
  }

  Future<void> _refreshConnectionState({required bool showRestoredWhenBack}) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasConnectionType = connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );

      final isActuallyOnline = hasConnectionType && await _hasRealInternet();

      if (!mounted) return;

      if (!isActuallyOnline) {
        _restoredTimer?.cancel();
        _startOfflinePolling();
        ConnectivitySignal.setOnline(false);
        setState(() {
          _isOffline = true;
          _showRestored = false;
          _lastKnownOnline = false;
        });
        return;
      }

      _stopOfflinePolling();
      ConnectivitySignal.setOnline(true);
      final wasOffline = !_lastKnownOnline;
      setState(() {
        _isOffline = false;
        _lastKnownOnline = true;
        _showRestored = showRestoredWhenBack && wasOffline;
      });

      if (showRestoredWhenBack && wasOffline) {
        _restoredTimer?.cancel();
        _restoredTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _showRestored = false);
        });
      }
    } catch (_) {
      if (!mounted) return;
      _startOfflinePolling();
      ConnectivitySignal.setOnline(false);
      setState(() {
        _isOffline = true;
        _showRestored = false;
        _lastKnownOnline = false;
      });
    } finally {
      _isChecking = false;
    }
  }

  Future<bool> _hasRealInternet() async {
    final targets = <Uri>[
      Uri.parse(
        'https://asmovies-watch.pages.dev/version.json?ping=1&t=${DateTime.now().millisecondsSinceEpoch}',
      ),
      Uri.parse('https://www.gstatic.com/generate_204'),
      Uri.parse('https://clients3.google.com/generate_204'),
    ];

    for (final target in targets) {
      try {
        final response = await http.get(target, headers: const {
          'cache-control': 'no-cache',
          'pragma': 'no-cache',
        }).timeout(const Duration(seconds: 4));
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    _offlinePollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: ConnectionBanner(
              isOffline: _isOffline,
              showRestored: _showRestored,
              onRetry: () => _refreshConnectionState(showRestoredWhenBack: true),
            ),
          ),
        ),
        if (_isOffline)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _OfflineFloatingCard(
              onRetry: () => _refreshConnectionState(showRestoredWhenBack: true),
            ),
          ),
      ],
    );
  }
}

class _OfflineFloatingCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _OfflineFloatingCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC0B0F18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7A2230)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.34),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'الاتصال مفصول الآن',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'سنفحص الشبكة تلقائيًا كل ثوانٍ قليلة، ويمكنك أيضًا إعادة الفحص الآن.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD5B13E),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'إعادة الفحص',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.portable_wifi_off_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
