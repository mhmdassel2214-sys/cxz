import 'package:flutter/material.dart';

import 'player_screen.dart';
import '../services/api_service.dart';
import '../services/offline_service.dart';

class SeriesDetailsPage extends StatefulWidget {
  final SeriesItem series;

  const SeriesDetailsPage({
    super.key,
    required this.series,
  });

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage> {
  late int _selectedSeasonIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedSeasonIndex = 0;
    _pageController = PageController(viewportFraction: .9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<SeasonItem> get _seasons => widget.series.seasons;

  SeasonItem get _selectedSeason {
    if (_seasons.isEmpty) {
      return SeasonItem(
        season: 1,
        seasonName: 'الموسم 1',
        episodes: const [],
      );
    }
    final safeIndex = _selectedSeasonIndex.clamp(0, _seasons.length - 1);
    return _seasons[safeIndex];
  }

  Future<void> _openEpisode(EpisodeItem episode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: '${widget.series.title} - ${episode.title}',
          videoUrl: episode.videoUrl,
          image: widget.series.image,
          type: 'مسلسل',
        ),
      ),
    );
  }

  Future<void> _downloadEpisode(EpisodeItem episode) async {
    final saved = await OfflineService.addItem(
      OfflineItem(
        title: '${widget.series.title} - ${episode.title}',
        image: widget.series.image,
        videoUrl: episode.videoUrl,
        type: 'مسلسل',
      ),
    );

    if (!mounted) return;

    final message = saved.isDownloading
        ? 'بدأ تنزيل الحلقة وسيظهر التقدم في الأوفلاين'
        : saved.isDownloaded
            ? 'الحلقة موجودة مسبقًا في الأوفلاين'
            : saved.isStreamOnly
                ? 'هذا الرابط بث فقط ويمكن مشاهدته أونلاين'
                : 'تمت إضافة الحلقة إلى الأوفلاين';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF121722),
        content: Text(message),
      ),
    );
  }

  Future<void> _downloadSeason() async {
    final episodes = _selectedSeason.episodes;
    if (episodes.isEmpty) return;

    int started = 0;
    int existing = 0;
    int streamOnly = 0;

    for (final episode in episodes) {
      final saved = await OfflineService.addItem(
        OfflineItem(
          title: '${widget.series.title} - ${episode.title}',
          image: widget.series.image,
          videoUrl: episode.videoUrl,
          type: 'مسلسل',
        ),
      );

      if (saved.isDownloading) {
        started++;
      } else if (saved.isDownloaded) {
        existing++;
      } else if (saved.isStreamOnly) {
        streamOnly++;
      }
    }

    if (!mounted) return;

    final parts = <String>[];
    if (started > 0) parts.add('بدأ تنزيل $started حلقة');
    if (existing > 0) parts.add('$existing موجودة مسبقًا');
    if (streamOnly > 0) parts.add('$streamOnly بث فقط');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF121722),
        content: Text(parts.isEmpty ? 'لا توجد حلقات قابلة للتنزيل' : parts.join(' • ')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.series;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              backgroundColor: const Color(0xFF05060A),
              leading: _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: _GlassIconButton(
                    icon: Icons.download_rounded,
                    onTap: _selectedSeason.episodes.isEmpty ? null : _downloadSeason,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      series.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: const Icon(
                          Icons.live_tv_rounded,
                          color: Colors.white54,
                          size: 56,
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(.18),
                            Colors.black.withOpacity(.28),
                            Colors.black.withOpacity(.92),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 98,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (series.badge.isNotEmpty) ...[
                            _TopBadge(
                              text: series.badge,
                              color: const Color(0xFFD5B13E),
                              textColor: Colors.black,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (series.isNew)
                            const _TopBadge(
                              text: 'جديد',
                              color: Colors.redAccent,
                              textColor: Colors.white,
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            series.title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              _MetaChip(
                                icon: Icons.live_tv_rounded,
                                text: series.category.isNotEmpty ? series.category : 'مسلسل',
                              ),
                              _MetaChip(
                                icon: Icons.star_rounded,
                                text: series.rating.isNotEmpty ? series.rating : '—',
                              ),
                              _MetaChip(
                                icon: Icons.playlist_play_rounded,
                                text: '${series.totalEpisodes} حلقة',
                              ),
                              _MetaChip(
                                icon: Icons.layers_rounded,
                                text: '${series.seasons.length} موسم',
                              ),
                            ],
                          ),
                          if (series.description.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              series.description,
                              textAlign: TextAlign.right,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13.5,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              if (_selectedSeason.episodes.isNotEmpty) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _downloadSeason,
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text(
                                      'تنزيل الموسم',
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF2D3548)),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _selectedSeason.episodes.isEmpty
                                      ? null
                                      : () => _openEpisode(_selectedSeason.episodes.first),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text(
                                    'ابدأ المشاهدة',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD5B13E),
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.white12,
                                    disabledForegroundColor: Colors.white54,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_seasons.isNotEmpty) ...[
                      const _SectionTitle(
                        title: 'المواسم',
                        subtitle: 'اختر الموسم الذي تريد متابعته',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          itemCount: _seasons.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final season = _seasons[i];
                            final selected = i == _selectedSeasonIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedSeasonIndex = i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: selected ? const Color(0xFFD5B13E) : const Color(0xFF0C1018),
                                  border: Border.all(
                                    color: selected ? const Color(0xFFD5B13E) : const Color(0xFF1A2233),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.layers_rounded,
                                      size: 18,
                                      color: selected ? Colors.black : Colors.white70,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      season.seasonName,
                                      style: TextStyle(
                                        color: selected ? Colors.black : Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _SeasonSummaryCard(
                      seasonName: _selectedSeason.seasonName,
                      episodeCount: _selectedSeason.episodes.length,
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle(
                      title: 'الحلقات',
                      subtitle: 'اختار الحلقة وابدأ فورًا',
                    ),
                    const SizedBox(height: 14),
                    if (_selectedSeason.episodes.isEmpty)
                      const _EmptyEpisodesCard()
                    else
                      ListView.separated(
                        itemCount: _selectedSeason.episodes.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final episode = _selectedSeason.episodes[i];
                          return _EpisodeCard(
                            index: i + 1,
                            title: episode.title.isNotEmpty ? episode.title : 'الحلقة ${i + 1}',
                            image: series.image,
                            onPlay: () => _openEpisode(episode),
                            onDownload: () => _downloadEpisode(episode),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassIconButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.12)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const _TopBadge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFD5B13E), size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
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

class _SeasonSummaryCard extends StatelessWidget {
  final String seasonName;
  final int episodeCount;

  const _SeasonSummaryCard({
    required this.seasonName,
    required this.episodeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A2233)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x19D5B13E),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.movie_filter_rounded,
              color: Color(0xFFD5B13E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  seasonName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$episodeCount حلقة متاحة للمشاهدة',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

class _EpisodeCard extends StatelessWidget {
  final int index;
  final String title;
  final String image;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _EpisodeCard({
    required this.index,
    required this.title,
    required this.image,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A2233)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.16),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            child: Image.network(
              image,
              width: 118,
              height: 118,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 118,
                height: 118,
                color: const Color(0xFF111827),
                child: const Icon(Icons.live_tv_rounded, color: Colors.white54),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x19D5B13E),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Color(0xFFD5B13E),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Expanded(
                        flex: 4,
                        child: Text(
                          title,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'جاهزة للمشاهدة الآن أو التنزيل للأوفلاين',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text(
                            'تنزيل',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF2D3548)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text(
                            'تشغيل',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD5B13E),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ],
      ),
    );
  }
}

class _EmptyEpisodesCard extends StatelessWidget {
  const _EmptyEpisodesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1018),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A2233)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Color(0xFFD5B13E),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'لا توجد حلقات متوفرة الآن',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'أضف حلقات داخل JSON وستظهر هنا مباشرة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
