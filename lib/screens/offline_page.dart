import 'package:flutter/material.dart';

import '../services/offline_service.dart';
import 'player_screen.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  Future<void> _removeItem(OfflineItem item) async {
    await OfflineService.removeItem(item.videoUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10151F),
        content: Text(item.isDownloading
            ? 'تم إلغاء تنزيل ${item.title}'
            : 'تم حذف ${item.title} من الأوفلاين'),
      ),
    );
  }

  Future<void> _clearAll() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0B0E17),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text(
              'حذف كل المحتوى',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'سيتم حذف كل ما حفظته في صفحة الأوفلاين وإلغاء أي تنزيل جارٍ. هل تريد المتابعة؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;
    await OfflineService.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10151F),
        content: Text('تم حذف كل العناصر من الأوفلاين'),
      ),
    );
  }

  Future<void> _openItem(OfflineItem item) async {
    if (item.isDownloading) return;
    final url = await OfflineService.resolvePlayableUrl(item);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          title: item.title,
          videoUrl: url,
          image: item.image,
          type: item.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF05060A),
        body: SafeArea(
          child: StreamBuilder<List<OfflineItem>>(
            stream: OfflineService.watchItems(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <OfflineItem>[];
              final downloading = items.where((e) => e.isDownloading).length;
              final ready = items.where((e) => e.isDownloaded).length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(26),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10141D), Color(0xFF0B0E17)],
                              ),
                              border: Border.all(color: const Color(0xFF1B2133)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3BA4E).withOpacity(.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.download_done_rounded,
                                    color: Color(0xFFE3BA4E),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'المشاهدة بدون إنترنت',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        downloading > 0
                                            ? 'جاهز $ready · جاري تحميل $downloading'
                                            : '${items.length} عنصر محفوظ عندك الآن',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (items.isNotEmpty)
                                  IconButton(
                                    onPressed: _clearAll,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withOpacity(.12),
                                      foregroundColor: Colors.redAccent,
                                    ),
                                    icon: const Icon(Icons.delete_sweep_rounded),
                                  ),
                              ],
                            ),
                          ),
                          if (!snapshot.hasData)
                            const Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE3BA4E)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.hasData)
                    items.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 94,
                                      height: 94,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B0E17),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(color: const Color(0xFF1B2133)),
                                      ),
                                      child: const Icon(
                                        Icons.cloud_download_outlined,
                                        color: Color(0xFFE3BA4E),
                                        size: 42,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'ما عندك شيء محفوظ حاليًا',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'لما تضيف أفلام أو حلقات للأوفلاين رح تظهر هنا مع تقدم التحميل بشكل مباشر.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 14,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                            sliver: SliverList.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _OfflineCard(
                                    item: item,
                                    onPlay: () => _openItem(item),
                                    onDelete: () => _removeItem(item),
                                  ),
                                );
                              },
                            ),
                          ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  final OfflineItem item;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _OfflineCard({
    required this.item,
    required this.onPlay,
    required this.onDelete,
  });

  String get _statusText {
    if (item.isDownloaded) return 'مكتمل · جاهز بدون نت';
    if (item.isDownloading) return 'جاري التحميل... ${_percentText(item.progress)}';
    if (item.isStreamOnly) return 'بث فقط · لا يمكن تنزيله';
    if (item.hasError) return item.errorMessage.isEmpty ? 'فشل التحميل' : item.errorMessage;
    return 'بانتظار التحميل';
  }

  static String _percentText(double value) => '${(value * 100).clamp(0, 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final playEnabled = item.isDownloaded || item.isStreamOnly;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1B2133)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: playEnabled ? onPlay : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 120,
                  child: Image.network(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF121826),
                      child: const Icon(Icons.movie_rounded, color: Colors.white54, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3BA4E).withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.type,
                            style: const TextStyle(
                              color: Color(0xFFE3BA4E),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: item.hasError
                                  ? Colors.redAccent
                                  : item.isDownloaded
                                      ? const Color(0xFF7EE081)
                                      : item.isStreamOnly
                                          ? Colors.white70
                                          : const Color(0xFFE3BA4E),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.isDownloading) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: item.progress <= 0 ? null : item.progress,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE3BA4E)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: playEnabled ? const Color(0xFFE3BA4E) : Colors.white10,
                              foregroundColor: playEnabled ? Colors.black : Colors.white60,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: playEnabled ? onPlay : null,
                            icon: Icon(item.isStreamOnly ? Icons.wifi_tethering_rounded : Icons.play_arrow_rounded),
                            label: Text(item.isStreamOnly ? 'مشاهدة أونلاين' : item.isDownloading ? 'جاري التحميل' : 'تشغيل'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: onDelete,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            backgroundColor: Colors.white10,
                            foregroundColor: item.isDownloading ? Colors.redAccent : Colors.white70,
                          ),
                          icon: Icon(item.isDownloading ? Icons.close_rounded : Icons.delete_outline_rounded),
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
    );
  }
}
