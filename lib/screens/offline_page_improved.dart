
import 'package:flutter/material.dart';
import '../services/offline_service.dart';
import 'player_screen.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  late Future<List<OfflineItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = OfflineService.getItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = OfflineService.getItems();
    });
  }

  Future<void> _deleteItem(String videoUrl) async {
    await OfflineService.removeItem(videoUrl);
    await _refresh();
  }

  Future<void> _deleteAll() async {
    await OfflineService.clearAll();
    await _refresh();
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
          title: const Text(
            'الأوفلاين',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: _deleteAll,
            )
          ],
        ),
        body: FutureBuilder<List<OfflineItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD5B13E)),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.download_done_rounded, size: 80, color: Colors.white24),
                    SizedBox(height: 20),
                    Text(
                      'لا يوجد محتوى أوفلاين',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFFD5B13E),
              backgroundColor: const Color(0xFF0B0E17),
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = items[i];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E17),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF1B2133)),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.image,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 54,
                            height: 54,
                            color: const Color(0xFF111827),
                            child: const Icon(Icons.movie, color: Colors.white54),
                          ),
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        item.type,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Color(0xFFD5B13E),
                              size: 30,
                            ),
                            onPressed: () async {
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
                              if (mounted) _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteItem(item.videoUrl),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
