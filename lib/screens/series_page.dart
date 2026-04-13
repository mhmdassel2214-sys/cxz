import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/connectivity_signal.dart';
import 'series_details.dart';

class SeriesPage extends StatefulWidget {
  const SeriesPage({super.key, this.onAttachScrollToTop});

  final void Function(VoidCallback action)? onAttachScrollToTop;

  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  late Future<List<SeriesItem>> seriesFuture;
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  StreamSubscription<bool>? _connectionSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    seriesFuture = ApiService.fetchSeries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAttachScrollToTop?.call(scrollToTop);
    });
    _connectionSubscription = ConnectivitySignal.onlineStream.stream.listen((isOnline) {
      if (!mounted || !isOnline) return;
      _refreshSeries();
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SeriesItem> _filterSeries(List<SeriesItem> series) {
    if (searchText.trim().isEmpty) return series;
    final q = searchText.toLowerCase().trim();
    return series.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.badge.toLowerCase().contains(q) ||
          item.rating.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.date.toLowerCase().contains(q);
    }).toList();
  }

  List<SeriesItem> _getRecentSeries(List<SeriesItem> series) {
    final sorted = [...series];
    sorted.sort((a, b) {
      try {
        return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
      } catch (_) {
        return b.date.compareTo(a.date);
      }
    });
    return sorted.take(10).toList();
  }

  Map<String, List<SeriesItem>> _groupSeriesByCategory(List<SeriesItem> series) {
    final Map<String, List<SeriesItem>> grouped = {};
    for (final item in series) {
      final category = item.category.trim().isEmpty ? 'مسلسلات متنوعة' : item.category.trim();
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }
    return grouped;
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

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  void _openSeries(SeriesItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesDetailsPage(series: item)));
  }

  Future<void> _refreshSeries() async => setState(() => seriesFuture = ApiService.fetchSeries());

  int _gridCrossAxisCount(double width) => width >= 900 ? 4 : width >= 650 ? 3 : 2;

  double _wideCardWidth(double width) => width >= 900 ? 260 : width >= 650 ? 230 : 210;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 360 ? 12.0 : 14.0;
    final searchHeight = width < 360 ? 48.0 : 52.0;
    final recentHeight = width >= 650 ? 340.0 : 310.0;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF05060A),
          elevation: 0,
          centerTitle: true,
          title: const Text('المسلسلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 14),
              child: Container(
                height: searchHeight,
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ابحث عن مسلسل...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    contentPadding: EdgeInsets.symmetric(horizontal: width < 360 ? 12 : 14, vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SeriesItem>>(
                future: seriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFD5B13E)));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('صار خطأ في تحميل المسلسلات\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  }

                  final series = _filterSeries(snapshot.data ?? []);
                  final recentSeries = _getRecentSeries(series);
                  final groupedSeries = _groupSeriesByCategory(series);

                  if (series.isEmpty) {
                    return const Center(
                      child: Text('لا توجد مسلسلات', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w700)),
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFFD5B13E),
                    backgroundColor: const Color(0xFF0B0E17),
                    onRefresh: _refreshSeries,
                    child: ListView(
                      controller: _scrollController,
                      cacheExtent: 1000,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
                      children: [
                        if (recentSeries.isNotEmpty) ...[
                          const _SectionHeader(title: 'المضاف حديثًا'),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: recentHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              itemCount: recentSeries.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final item = recentSeries[i];
                                return _WideSeriesCard(
                                  series: item,
                                  formattedDate: _formatDate(item.date),
                                  showNewBadge: item.isNew || _isRecentlyAdded(item.date),
                                  onTap: () => _openSeries(item),
                                  width: _wideCardWidth(width),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        ...groupedSeries.entries.map((entry) {
                          final categoryTitle = entry.key;
                          final categorySeries = entry.value.take(12).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: categoryTitle),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categorySeries.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _gridCrossAxisCount(width),
                                  childAspectRatio: width >= 650 ? 0.68 : 0.60,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                ),
                                itemBuilder: (_, i) {
                                  final item = categorySeries[i];
                                  return _SeriesCard(
                                    series: item,
                                    formattedDate: _formatDate(item.date),
                                    showNewBadge: item.isNew || _isRecentlyAdded(item.date),
                                    onTap: () => _openSeries(item),
                                  );
                                },
                              ),
                              const SizedBox(height: 22),
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900));
  }
}

class _SeriesCard extends StatelessWidget {
  final SeriesItem series;
  final String formattedDate;
  final bool showNewBadge;
  final VoidCallback onTap;
  const _SeriesCard({required this.series, required this.formattedDate, required this.showNewBadge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E17),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1B2133)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      series.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF121826),
                        child: const Icon(Icons.tv_rounded, color: Colors.white38, size: 42),
                      ),
                    ),
                    if (showNewBadge)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(12)),
                          child: const Text('جديد', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
              child: Text(series.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${series.category} · تقييم ${series.rating}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
              child: Row(
                children: [
                  if (series.badge.trim().isNotEmpty)
                    Text(series.badge, style: const TextStyle(color: Color(0xFFD5B13E), fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (formattedDate.isNotEmpty)
                    Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideSeriesCard extends StatelessWidget {
  final SeriesItem series;
  final String formattedDate;
  final bool showNewBadge;
  final VoidCallback onTap;
  final double width;
  const _WideSeriesCard({required this.series, required this.formattedDate, required this.showNewBadge, required this.onTap, required this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E17),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1B2133)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      series.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF121826),
                        child: const Icon(Icons.tv_rounded, color: Colors.white38, size: 48),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('عرض', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                    if (showNewBadge)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(12)),
                          child: const Text('جديد', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Text(series.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(series.category.trim().isEmpty ? 'مسلسل' : series.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD5B13E), fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Text('تقييم ${series.rating}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const Spacer(),
                  if (formattedDate.isNotEmpty)
                    Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
