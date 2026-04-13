import 'package:flutter/material.dart';

import 'screens/movies_page.dart';
import 'screens/player_screen.dart';
import 'screens/series_details.dart';
import 'screens/series_page.dart';
import 'services/api_service.dart';
import 'services/continue_watching_service.dart';
import 'services/offline_service.dart';
import 'widgets/as_logo.dart';
import 'widgets/series_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onAttachScrollToTop});

  final void Function(VoidCallback action)? onAttachScrollToTop;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<MovieItem>> moviesFuture;
  late Future<List<SeriesItem>> seriesFuture;
  late Future<List<ContinueWatchingItem>> continueWatchingFuture;

  final ScrollController _homeScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchText = ValueNotifier('');
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAttachScrollToTop?.call(scrollToTop);
    });
  }

  void _loadData() {
    moviesFuture = ApiService.fetchMovies();
    seriesFuture = ApiService.fetchSeries();
    continueWatchingFuture = ContinueWatchingService.getItems();
  }

  void scrollToTop() {
    if (!_homeScrollController.hasClients) return;
    _homeScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    _searchController.dispose();
    _searchText.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(_loadData);
    await Future.wait([moviesFuture, seriesFuture, continueWatchingFuture]);
  }

  List<MovieItem> _filterMovies(List<MovieItem> movies, String query) {
    if (query.trim().isEmpty) return movies;
    final q = query.toLowerCase();
    return movies.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.badge.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  List<SeriesItem> _filterSeries(List<SeriesItem> series, String query) {
    if (query.trim().isEmpty) return series;
    final q = query.toLowerCase();
    return series.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.badge.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  bool _isRecentlyAdded(String date) {
    if (date.isEmpty) return false;
    try {
      final itemDate = DateTime.parse(date);
      final now = DateTime.now();
      return now.difference(itemDate).inDays <= 1;
    } catch (_) {
      return false;
    }
  }

  List<_MixedPosterItem> _mixedFromMovies(List<MovieItem> movies) {
    return movies
        .map(
          (m) => _MixedPosterItem(
            title: m.title,
            image: m.image,
            date: m.date,
            badge: m.badge,
            isNew: m.isNew,
            subtitle: m.category.isNotEmpty ? m.category : 'فيلم',
            onTap: () => _openMovie(m),
          ),
        )
        .toList();
  }

  List<_MixedPosterItem> _mixedFromSeries(List<SeriesItem> series) {
    return series
        .map(
          (s) => _MixedPosterItem(
            title: s.title,
            image: s.image,
            date: s.date,
            badge: s.badge,
            isNew: s.isNew,
            subtitle: s.category.isNotEmpty ? s.category : 'مسلسل',
            onTap: () => _openSeries(s),
          ),
        )
        .toList();
  }

  List<_MixedPosterItem> _getTopMixed({
    required List<MovieItem> movies,
    required List<SeriesItem> series,
  }) {
    final items = <_MixedPosterItem>[
      ..._mixedFromMovies(movies.where((e) => e.isTop).toList()),
      ..._mixedFromSeries(series.where((e) => e.isTop).toList()),
    ];

    if (items.isEmpty) {
      items.addAll(_mixedFromMovies(movies.take(6).toList()));
      items.addAll(_mixedFromSeries(series.take(6).toList()));
    }

    return items.take(10).toList();
  }

  _HeroContent? _pickHero(List<SeriesItem> series, List<MovieItem> movies) {
    SeriesItem? featuredSeries;
    MovieItem? featuredMovie;

    try {
      featuredSeries = series.firstWhere((e) => e.isFeatured);
    } catch (_) {}

    try {
      featuredMovie = movies.firstWhere((e) => e.isFeatured);
    } catch (_) {}

    if (featuredSeries != null) {
      return _HeroContent(
        title: featuredSeries.title,
        image: featuredSeries.image,
        subtitle: featuredSeries.description.isNotEmpty
            ? featuredSeries.description
            : 'أحدث الحلقات متوفرة الآن بجودة ممتازة.',
        tag: featuredSeries.badge.isNotEmpty ? featuredSeries.badge : 'حصري',
        meta: featuredSeries.category.isEmpty ? 'مسلسل' : featuredSeries.category,
        onPlay: () => _openSeries(featuredSeries!),
        onDownload: featuredSeries.episodes.isEmpty
            ? null
            : () => _saveOffline(
                  title: featuredSeries!.title,
                  image: featuredSeries.image,
                  videoUrl: featuredSeries.episodes.first.videoUrl,
                  type: 'مسلسل',
                ),
      );
    }

    if (featuredMovie != null) {
      return _HeroContent(
        title: featuredMovie.title,
        image: featuredMovie.image,
        subtitle: featuredMovie.description.isNotEmpty
            ? featuredMovie.description
            : 'فيلم مميز متوفر الآن للمشاهدة.',
        tag: featuredMovie.badge.isNotEmpty ? featuredMovie.badge : 'مميز',
        meta: featuredMovie.category.isEmpty ? 'فيلم' : featuredMovie.category,
        onPlay: () => _openMovie(featuredMovie!),
        onDownload: () => _saveOffline(
          title: featuredMovie!.title,
          image: featuredMovie.image,
          videoUrl: featuredMovie.videoUrl,
          type: 'فيلم',
        ),
      );
    }

    if (series.isNotEmpty) {
      final item = series.first;
      return _HeroContent(
        title: item.title,
        image: item.image,
        subtitle:
            item.description.isNotEmpty ? item.description : 'أحدث الحلقات متوفرة الآن.',
        tag: item.badge.isNotEmpty ? item.badge : 'HD',
        meta: item.category.isEmpty ? 'مسلسل' : item.category,
        onPlay: () => _openSeries(item),
        onDownload: item.episodes.isEmpty
            ? null
            : () => _saveOffline(
                  title: item.title,
                  image: item.image,
                  videoUrl: item.episodes.first.videoUrl,
                  type: 'مسلسل',
                ),
      );
    }

    if (movies.isNotEmpty) {
      final item = movies.first;
      return _HeroContent(
        title: item.title,
        image: item.image,
        subtitle: item.description.isNotEmpty ? item.description : 'فيلم جديد بانتظارك.',
        tag: item.badge.isNotEmpty ? item.badge : 'HD',
        meta: item.category.isEmpty ? 'فيلم' : item.category,
        onPlay: () => _openMovie(item),
        onDownload: () => _saveOffline(
          title: item.title,
          image: item.image,
          videoUrl: item.videoUrl,
          type: 'فيلم',
        ),
      );
    }

    return null;
  }

  void _openSeries(SeriesItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeriesDetailsPage(series: item)),
    ).then((_) {
      if (mounted) {
        setState(() {
          continueWatchingFuture = ContinueWatchingService.getItems();
        });
      }
    });
  }

  void _openMovie(MovieItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B0F18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  item.image,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 190,
                    width: double.infinity,
                    color: const Color(0xFF111827),
                    child: const Icon(Icons.movie, color: Colors.white54, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.category.isEmpty ? 'فيلم' : item.category,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _saveOffline(
                          title: item.title,
                          image: item.image,
                          videoUrl: item.videoUrl,
                          type: 'فيلم',
                        );
                        if (mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text(
                        'تنزيل أوفلاين',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2E3648)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              title: item.title,
                              videoUrl: item.videoUrl,
                              image: item.image,
                              type: 'فيلم',
                            ),
                          ),
                        );
                        if (!mounted) return;
                        setState(() {
                          continueWatchingFuture = ContinueWatchingService.getItems();
                        });
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text(
                        'تشغيل',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B13E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveOffline({
    required String title,
    required String image,
    required String videoUrl,
    required String type,
  }) async {
    final saved = await OfflineService.addItem(
      OfflineItem(title: title, image: image, videoUrl: videoUrl, type: type),
    );

    if (!mounted) return;
    final message = saved.isDownloading
        ? 'بدأ التنزيل وسيظهر تقدمه في صفحة الأوفلاين'
        : saved.isDownloaded
            ? 'العنصر موجود مسبقًا في الأوفلاين'
            : saved.isStreamOnly
                ? 'هذا الرابط بث فقط ويمكن مشاهدته أونلاين'
                : 'تمت الإضافة إلى الأوفلاين';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF121722),
        content: Text(message),
      ),
    );
  }

  Widget _buildSearchResults(List<SeriesItem> series, List<MovieItem> movies) {
    final allResults = <_MixedPosterItem>[
      ..._mixedFromSeries(series),
      ..._mixedFromMovies(movies),
    ];

    if (allResults.isEmpty) {
      return ListView(
        controller: _homeScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: const [
          SizedBox(height: 48),
          _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'لا توجد نتائج',
            subtitle: 'جرّب اسمًا آخر أو ابحث باسم أقصر.',
          ),
        ],
      );
    }

    return GridView.builder(
      controller: _homeScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
      itemCount: allResults.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, i) {
        final item = allResults[i];
        return GestureDetector(
          onTap: item.onTap,
          child: _PosterTile(
            title: item.title,
            subtitle: item.subtitle,
            image: item.image,
            showNewBadge: item.isNew || _isRecentlyAdded(item.date),
            badge: item.badge,
          ),
        );
      },
    );
  }

  Widget _buildHomeSections({
    required List<SeriesItem> series,
    required List<MovieItem> movies,
    required List<ContinueWatchingItem> continueWatching,
  }) {
    final hero = _pickHero(series, movies);
    final topItems = _getTopMixed(movies: movies, series: series);
    final homeSeries = series.take(10).toList();
    final homeMovies = movies.take(10).toList();

    return ListView(
      controller: _homeScrollController,
      cacheExtent: 1200,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 42),
      children: [
        if (hero != null) _HeroBanner(content: hero),
        const SizedBox(height: 22),
        if (continueWatching.isNotEmpty) ...[
          const _SectionHeader(
            title: 'أكمل المشاهدة',
            subtitle: 'ارجع من حيث توقفت',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 256,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: continueWatching.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final item = continueWatching[i];
                final progress = item.durationSeconds > 0
                    ? item.positionSeconds / item.durationSeconds
                    : 0.0;
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(
                          title: item.title,
                          videoUrl: item.videoUrl,
                          image: item.image,
                          type: item.type,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    setState(() {
                      continueWatchingFuture = ContinueWatchingService.getItems();
                    });
                  },
                  child: _ContinueWatchingCard(item: item, progress: progress),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        if (topItems.isNotEmpty) ...[
          const _SectionHeader(
            title: 'المضاف حديثا ',
            subtitle: 'اكتشف أحدث الأفلام والمسلسلات المضافة إلى المكتبة',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 226,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: topItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final item = topItems[i];
                return GestureDetector(
                  onTap: item.onTap,
                  child: _PosterTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    image: item.image,
                    badge: item.badge,
                    showNewBadge: item.isNew,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        if (series.isNotEmpty) ...[
          _SectionHeader(
            title: 'المسلسلات',
            subtitle: 'تابع المواسم والحلقات بسهولة',
            actionText: 'عرض الكل',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SeriesPage()),
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: homeSeries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final item = homeSeries[i];
                return SizedBox(
                  width: 182,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openSeries(item),
                        child: SeriesCard(series: item),
                      ),
                      if (item.isNew || _isRecentlyAdded(item.date))
                        const Positioned(
                          top: 8,
                          left: 8,
                          child: _SmallBadge(
                            text: 'جديد',
                            color: Colors.redAccent,
                            textColor: Colors.white,
                          ),
                        ),
                      if (item.badge.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _SmallBadge(
                            text: item.badge,
                            color: const Color(0xFFD5B13E),
                            textColor: Colors.black,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
        ],
        if (movies.isNotEmpty) ...[
          _SectionHeader(
            title: 'الأفلام',
            subtitle: 'أحدث الترشيحات للمشاهدة الليلة',
            actionText: 'عرض الكل',
            onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoviesPage()),
              );
            },
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: homeMovies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final item = homeMovies[i];
                return SizedBox(
                  width: 182,
                  child: _MoviePosterCard(
                    title: item.title,
                    subtitle: item.category.isNotEmpty ? item.category : 'فيلم',
                    image: item.image,
                    showNewBadge: item.isNew || _isRecentlyAdded(item.date),
                    badge: item.badge,
                    onTap: () => _openMovie(item),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (series.isEmpty && movies.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 70),
            child: _EmptyState(
              icon: Icons.movie_filter_outlined,
              title: 'لا يوجد محتوى الآن',
              subtitle: 'أضف بيانات جديدة إلى JSON وسيظهر المحتوى هنا مباشرة.',
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: SafeArea(
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([seriesFuture, moviesFuture, continueWatchingFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _HomeLoadingView();
              }

              if (snapshot.hasError) {
                return _ErrorView(
                  error: '${snapshot.error}',
                  onRetry: () {
                    setState(_loadData);
                  },
                );
              }

              final rawSeries = snapshot.data![0] as List<SeriesItem>;
              final rawMovies = snapshot.data![1] as List<MovieItem>;
              final continueWatching = snapshot.data![2] as List<ContinueWatchingItem>;

              return ValueListenableBuilder<String>(
                valueListenable: _searchText,
                builder: (context, query, _) {
                  final series = _filterSeries(rawSeries, query);
                  final movies = _filterMovies(rawMovies, query);

                  return RefreshIndicator(
                    color: const Color(0xFFD5B13E),
                    backgroundColor: const Color(0xFF0B0E17),
                    onRefresh: _refreshData,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            children: [
                              const _HeaderBar(),
                              const SizedBox(height: 16),
                              _SearchBar(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                showClear: query.isNotEmpty,
                                onChanged: (value) => _searchText.value = value,
                                onClear: () {
                                  _searchController.clear();
                                  _searchText.value = '';
                                  _searchFocusNode.requestFocus();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: query.trim().isNotEmpty
                              ? _buildSearchResults(series, movies)
                              : _buildHomeSections(
                                  series: series,
                                  movies: movies,
                                  continueWatching: continueWatching,
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MixedPosterItem {
  final String title;
  final String image;
  final String date;
  final String badge;
  final bool isNew;
  final String subtitle;
  final VoidCallback onTap;

  _MixedPosterItem({
    required this.title,
    required this.image,
    required this.date,
    required this.badge,
    required this.isNew,
    required this.subtitle,
    required this.onTap,
  });
}

class _HeroContent {
  final String title;
  final String image;
  final String subtitle;
  final String tag;
  final String meta;
  final VoidCallback onPlay;
  final VoidCallback? onDownload;

  const _HeroContent({
    required this.title,
    required this.image,
    required this.subtitle,
    required this.tag,
    required this.meta,
    required this.onPlay,
    this.onDownload,
  });
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF121725), Color(0xFF0A0D15)],
        ),
        border: Border.all(color: const Color(0xFF20283A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const AsLogo(size: 50, compact: true, glow: false),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AsMovies',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'أفضل مكان لمشاهدة الأفلام والمسلسلات',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1018),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF20283A)),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final bool showClear;
  final FocusNode? focusNode;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.showClear = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF0C1018),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2233)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.15),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'ابحث عن فيلم أو مسلسل أو تصنيف...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
          suffixIcon: showClear
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final _HeroContent content;

  const _HeroBanner({required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 286,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                content.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF111827),
                  child: const Icon(Icons.movie, color: Colors.white54, size: 40),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(.12),
                      Colors.black.withOpacity(.25),
                      Colors.black.withOpacity(.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _SmallBadge(
                text: content.tag,
                color: const Color(0xFFD5B13E),
                textColor: Colors.black,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    content.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.subtitle,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content.meta,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (content.onDownload != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: content.onDownload,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('أوفلاين', style: TextStyle(fontWeight: FontWeight.w900)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF273043)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: content.onPlay,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('شاهد الآن', style: TextStyle(fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD5B13E),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText = '',
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actionText.isNotEmpty)
          GestureDetector(
            onTap: onActionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0D1018),
                border: Border.all(color: const Color(0xFF1B2130)),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Container(
          width: 4,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFD5B13E),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _PosterTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final bool showNewBadge;
  final String badge;

  const _PosterTile({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.showNewBadge,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0E17),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1A2030)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.24),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF111827),
                          child: const Icon(Icons.movie, color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(.68),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (badge.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _SmallBadge(
                        text: badge,
                        color: const Color(0xFFD5B13E),
                        textColor: Colors.black,
                      ),
                    ),
                  if (showNewBadge)
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: _SmallBadge(
                        text: 'جديد',
                        color: Colors.redAccent,
                        textColor: Colors.white,
                      ),
                    ),
                  const Positioned(
                    bottom: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFD5B13E),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final ContinueWatchingItem item;
  final double progress;

  const _ContinueWatchingCard({required this.item, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0B0E17),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1A2030)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF111827),
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  color: Colors.white54,
                                  size: 42,
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF111827),
                              child: const Icon(
                                Icons.play_circle_outline,
                                color: Colors.white54,
                                size: 42,
                              ),
                            ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(.7)],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFD5B13E),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            item.type,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFD5B13E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoviePosterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final bool showNewBadge;
  final String badge;
  final VoidCallback onTap;

  const _MoviePosterCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.showNewBadge,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF1B2133)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: const Icon(Icons.movie, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(.58),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _SmallBadge(
                    text: badge.isNotEmpty ? badge : 'HD',
                    color: const Color(0xFFD5B13E),
                    textColor: Colors.black,
                  ),
                ),
                if (showNewBadge)
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: _SmallBadge(
                      text: 'جديد',
                      color: Colors.redAccent,
                      textColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('مشاهدة', style: TextStyle(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFD5B13E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _SmallBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1018),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1018),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 286,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1018),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: CircularProgressIndicator(color: Color(0xFFD5B13E)),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFF101521),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل الصفحة الرئيسية',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, height: 1.5),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD5B13E),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF101521),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: const Color(0xFFD5B13E), size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.5),
          ),
        ],
      ),
    );
  }
}
