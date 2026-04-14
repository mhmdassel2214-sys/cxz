import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SeriesCard extends StatelessWidget {
  final SeriesItem series;

  const SeriesCard({
    super.key,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1B2133)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
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
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      series.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: const Icon(Icons.tv_rounded, color: Colors.white54),
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
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(.55),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(
              series.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${series.category} · تقييم ${series.rating}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'عرض',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFFD5B13E),
                  disabledForegroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
