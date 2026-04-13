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

  late final List<Widget> _pages = [
    HomePage(
      onAttachScrollToTop: (action) {
        _scrollHomeToTop = action;
      },
    ),
    SeriesPage(
      onAttachScrollToTop: (action) {
        _scrollSeriesToTop = action;
      },
    ),
    MoviesPage(
      onAttachScrollToTop: (action) {
        _scrollMoviesToTop = action;
      },
    ),
    const OfflinePage(),
    const ProfilePage(),
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

  void _onTapNav(int index) {
    if (index == _currentIndex) {
      switch (index) {
        case 0:
          _scrollHomeToTop?.call();
          return;
        case 1:
          _scrollSeriesToTop?.call();
          return;
        case 2:
          _scrollMoviesToTop?.call();
          return;
      }
    }

    setState(() => _currentIndex = index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0:
          _scrollHomeToTop?.call();
          break;
        case 1:
          _scrollSeriesToTop?.call();
          break;
        case 2:
          _scrollMoviesToTop?.call();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xE60A0D14),
              borderRadius: BorderRadius.circular(30),
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0xFFD5B13E), Color(0xFFF0D37A)],
                            )
                          : null,
                      color: active ? null : Colors.transparent,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _onTapNav(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: active ? Colors.black : Colors.white70,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: active ? Colors.black : Colors.white70,
                                fontSize: 11,
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
