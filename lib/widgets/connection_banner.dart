import 'package:flutter/material.dart';

class ConnectionBanner extends StatelessWidget {
  final bool isOffline;
  final bool showRestored;
  final VoidCallback? onRetry;

  const ConnectionBanner({
    super.key,
    required this.isOffline,
    required this.showRestored,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final visible = isOffline || showRestored;

    final Color bgColor = isOffline
        ? const Color(0xEE1A1016)
        : const Color(0xEE102015);
    final Color borderColor = isOffline
        ? const Color(0xFF8E2E3E)
        : const Color(0xFF1F7A4C);
    final IconData icon = isOffline
        ? Icons.wifi_off_rounded
        : Icons.check_circle_rounded;
    final String title = isOffline
        ? 'لا يوجد اتصال بالإنترنت'
        : 'تم استعادة الاتصال';
    final String subtitle = isOffline
        ? 'قد يتوقف التحميل وتحديث البيانات مؤقتًا'
        : 'التطبيق عاد للعمل بشكل طبيعي';

    return AnimatedSlide(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, -1.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                if (isOffline && onRetry != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 10),
                    child: TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD5B13E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'فحص الآن',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
