import 'package:flutter/material.dart';

import '../home_page.dart';
import '../services/update_service.dart';
import 'movies_page.dart';
import 'offline_page.dart';
import 'profile_page.dart';
import 'series_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  VoidCallback? _scrollHomeToTop;
  VoidCallback? _scrollSeriesToTop;
  VoidCallback? _scrollMoviesToTop;
  VoidCallback? _scrollOfflineToTop;
  VoidCallback? _scrollProfileToTop;

  late final List<Widget> _pages = [
    HomePage(onAttachScrollToTop: (action) => _scrollHomeToTop = action),
    SeriesPage(onAttachScrollToTop: (action) => _scrollSeriesToTop = action),
    MoviesPage(onAttachScrollToTop: (action) => _scrollMoviesToTop = action),
    OfflinePage(onAttachScrollToTop: (action) => _scrollOfflineToTop = action),
    ProfilePage(onAttachScrollToTop: (action) => _scrollProfileToTop = action),
  ];

  static const _tabs = <_NavItem>[
    _NavItem('الرئيسية', Icons.home_rounded),
    _NavItem('المسلسلات', Icons.tv_rounded),
    _NavItem('الأفلام', Icons.movie_creation_rounded),
    _NavItem('الأوفلاين', Icons.download_done_rounded),
    _NavItem('البروفايل', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        UpdateService.checkForUpdate(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      UpdateService.checkForUpdate(context);
    }
  }

  VoidCallback? _scrollCallbackForIndex(int index) {
    switch (index) {
      case 0:
        return _scrollHomeToTop;
      case 1:
        return _scrollSeriesToTop;
      case 2:
        return _scrollMoviesToTop;
      case 3:
        return _scrollOfflineToTop;
      case 4:
        return _scrollProfileToTop;
    }
    return null;
  }

  void _onTapNav(int index) {
    if (index == _currentIndex) {
      _scrollCallbackForIndex(index)?.call();
      return;
    }

    setState(() => _currentIndex = index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCallbackForIndex(index)?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 360 ? 8.0 : width < 430 ? 10.0 : 14.0;
    final outerBottom = width < 360 ? 8.0 : 12.0;
    final navPadding = width < 360 ? 6.0 : 8.0;
    final iconSize = width < 360 ? 22.0 : 24.0;
    final labelSize = width < 360 ? 10.0 : 11.0;
    final itemRadius = width < 360 ? 18.0 : 22.0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0B10),
                    const Color(0xFF05060A),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          IndexedStack(index: _currentIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, outerBottom),
          child: Container(
            padding: EdgeInsets.all(navPadding),
            decoration: BoxDecoration(
              color: const Color(0xE60A0D14),
              borderRadius: BorderRadius.circular(width < 360 ? 24 : 30),
              border: Border.all(color: const Color(0xFF1B2233)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.35),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final item = _tabs[index];
                final active = index == _currentIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: EdgeInsets.symmetric(horizontal: width < 360 ? 2 : 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(itemRadius),
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFFD5B13E), Color(0xFFF0D37A)],
                            )
                          : null,
                      color: active ? null : Colors.transparent,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(itemRadius),
                      onTap: () => _onTapNav(index),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: width < 360 ? 10 : 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              duration: const Duration(milliseconds: 220),
                              scale: active ? 1.06 : 1.0,
                              child: Icon(
                                item.icon,
                                color: active ? Colors.black : Colors.white70,
                                size: iconSize,
                              ),
                            ),
                            SizedBox(height: width < 360 ? 4 : 6),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: active ? Colors.black : Colors.white70,
                                fontSize: labelSize,
                                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem(this.label, this.icon);
}
