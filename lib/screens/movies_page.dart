import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/connectivity_signal.dart';
import '../services/offline_service.dart';
import 'player_screen.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key, this.onAttachScrollToTop});

  final void Function(VoidCallback action)? onAttachScrollToTop;

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  late Future<List<MovieItem>> moviesFuture;
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  StreamSubscription<bool>? _connectionSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    moviesFuture = ApiService.fetchMovies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAttachScrollToTop?.call(scrollToTop);
    });
    _connectionSubscription = ConnectivitySignal.onlineStream.stream.listen((isOnline) {
      if (!mounted || !isOnline) return;
      setState(() => moviesFuture = ApiService.fetchMovies());
    });
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MovieItem> _filterMovies(List<MovieItem> movies) {
    if (searchText.trim().isEmpty) return movies;
    return movies.where((movie) {
      final q = searchText.toLowerCase();
      return movie.title.toLowerCase().contains(q) ||
          movie.category.toLowerCase().contains(q) ||
          movie.description.toLowerCase().contains(q);
    }).toList();
  }

  List<MovieItem> _getRecentMovies(List<MovieItem> movies) {
    final sorted = [...movies];
    sorted.sort((a, b) {
      try {
        return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
      } catch (_) {
        return b.date.compareTo(a.date);
      }
    });
    return sorted.take(10).toList();
  }

  Map<String, List<MovieItem>> _groupMoviesByCategory(List<MovieItem> movies) {
    final Map<String, List<MovieItem>> grouped = {};
    for (final movie in movies) {
      final category = movie.category.trim().isEmpty ? 'أفلام متنوعة' : movie.category.trim();
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(movie);
    }
    return grouped;
  }

  bool _isRecentlyAdded(String date) {
    if (date.isEmpty) return false;
    try {
      final itemDate = DateTime.parse(date);
      final now = DateTime.now();
      return now.difference(itemDate).inDays <= 3;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  void _openMovie(MovieItem movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: movie.title,
          videoUrl: movie.videoUrl,
          image: movie.image,
          type: 'فيلم',
        ),
      ),
    );
  }

  Future<void> _saveOffline(MovieItem movie) async {
    final saved = await OfflineService.addItem(
      OfflineItem(title: movie.title, image: movie.image, videoUrl: movie.videoUrl, type: 'فيلم'),
    );

    if (!mounted) return;
    final message = saved.isDownloading
        ? 'بدأ تنزيل الفيلم وسيظهر تقدّم التحميل في الأوفلاين'
        : saved.isDownloaded
            ? 'الفيلم موجود مسبقًا في الأوفلاين'
            : saved.isStreamOnly
                ? 'هذا الرابط بث فقط ويمكن مشاهدته أونلاين'
                : 'تمت إضافة الفيلم إلى الأوفلاين';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF05060A),
          elevation: 0,
          centerTitle: true,
          title: const Text('الأفلام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1018),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1A2233)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => searchText = value),
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ابحث عن فيلم...',
                    hintStyle: TextStyle(color: Colors.white38),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MovieItem>>(
                future: moviesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFD5B13E)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'صار خطأ في تحميل الأفلام\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  final movies = _filterMovies(snapshot.data ?? []);
                  final recentMovies = _getRecentMovies(movies);
                  final groupedMovies = _groupMoviesByCategory(movies);

                  if (movies.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد أفلام',
                        style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFD5B13E),
                    backgroundColor: const Color(0xFF0B0E17),
                    onRefresh: () async => setState(() => moviesFuture = ApiService.fetchMovies()),
                    child: ListView(
                      controller: _scrollController,
                      cacheExtent: 1000,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      children: [
                        if (recentMovies.isNotEmpty) ...[
                          const _SectionHeader(title: 'المضاف حديثًا', actionText: 'اسحب'),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 250,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              itemCount: recentMovies.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final movie = recentMovies[i];
                                return _WideMovieCard(
                                  movie: movie,
                                  showNewBadge: movie.isNew || _isRecentlyAdded(movie.date),
                                  onTap: () => _openMovie(movie),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 26),
                        ],
                        ...groupedMovies.entries.map((entry) {
                          final category = entry.key;
                          final categoryMovies = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: category, actionText: ''),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categoryMovies.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.60,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                ),
                                itemBuilder: (_, i) {
                                  final movie = categoryMovies[i];
                                  return _MovieCard(
                                    movie: movie,
                                    formattedDate: _formatDate(movie.date),
                                    showNewBadge: movie.isNew || _isRecentlyAdded(movie.date),
                                    onPlay: () => _openMovie(movie),
                                    onDownload: () => _saveOffline(movie),
                                  );
                                },
                              ),
                              const SizedBox(height: 26),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
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
  final String actionText;
  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (actionText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF0D1018),
              border: Border.all(color: const Color(0xFF1B2130)),
            ),
            child: Text(actionText, style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        const Spacer(),
        Container(width: 36, height: 3, decoration: BoxDecoration(color: const Color(0xFFD5B13E), borderRadius: BorderRadius.circular(20))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19)),
      ],
    );
  }
}

class _WideMovieCard extends StatelessWidget {
  final MovieItem movie;
  final bool showNewBadge;
  final VoidCallback onTap;
  const _WideMovieCard({required this.movie, required this.showNewBadge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF1B2133)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          movie.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF111827),
                            child: const Icon(Icons.movie, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(.7)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _SmallBadge(
                        text: movie.badge.isNotEmpty ? movie.badge : 'HD',
                        color: const Color(0xFFD5B13E),
                        textColor: Colors.black,
                      ),
                    ),
                    if (showNewBadge)
                      const Positioned(
                        top: 10,
                        right: 10,
                        child: _SmallBadge(text: 'جديد', color: Colors.redAccent, textColor: Colors.white),
                      ),
                    const Positioned(
                      bottom: 10,
                      right: 10,
                      child: CircleAvatar(radius: 19, backgroundColor: Color(0xFFD5B13E), child: Icon(Icons.play_arrow_rounded, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 4),
            Text('${movie.category} · تقييم ${movie.rating}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final MovieItem movie;
  final String formattedDate;
  final bool showNewBadge;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  const _MovieCard({required this.movie, required this.formattedDate, required this.showNewBadge, required this.onPlay, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1B2133)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      movie.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: const Icon(Icons.movie, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.transparent, Colors.black.withOpacity(.55)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _SmallBadge(
                    text: movie.badge.isNotEmpty ? movie.badge : 'HD',
                    color: const Color(0xFFD5B13E),
                    textColor: Colors.black,
                  ),
                ),
                if (showNewBadge)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: _SmallBadge(text: 'جديد', color: Colors.redAccent, textColor: Colors.white),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${movie.category} · تقييم ${movie.rating}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          if (formattedDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ),
          if (movie.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                movie.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: const Text('تنزيل', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF283044)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded, size: 17),
                    label: const Text('مشاهدة', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFD5B13E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
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
  const _SmallBadge({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}
