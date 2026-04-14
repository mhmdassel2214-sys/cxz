import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/as_logo.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onAttachScrollToTop});

  final void Function(VoidCallback action)? onAttachScrollToTop;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const String appDownloadUrl = 'http://asmovies-watch.pages.dev/';
  static const String telegramUrl = 'https://t.me/asmovies_mo';
  static const String appVersion = '1.0.0';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAttachScrollToTop?.call(scrollToTop);
    });
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 550), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF111827),
        content: Text('تعذر فتح الرابط'),
      ),
    );
  }

  void _shareApp() {
    final text = '''
🔥 AsMovies

🎬 أفضل تطبيق لمشاهدة الأفلام والمسلسلات

📥 حمّله الآن:
$appDownloadUrl
''';

    Share.share(text);
  }

  void _showPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B0E17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'سياسة الاستخدام',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'تطبيق AsMovies يوفر واجهة سهلة لتنظيم ومشاهدة الأفلام والمسلسلات. يرجى استخدام التطبيق بطريقة قانونية واحترام حقوق الملكية الخاصة بالمحتوى.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: Colors.white70, height: 1.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 650;
              final horizontal = isWide ? 24.0 : 16.0;
              final titleSize = isWide ? 24.0 : 22.0;
              final bodySize = isWide ? 15.0 : 14.0;

              return ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 110),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF11151E), Color(0xFF0A0D14)],
                      ),
                      border: Border.all(color: const Color(0xFF1B2133)),
                    ),
                    child: Column(
                      children: [
                        const AsLogo(size: 86, compact: true),
                        const SizedBox(height: 14),
                        Text(
                          'AsMovies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'مشاهدة أحدث الأفلام والمسلسلات بسهولة',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, height: 1.6, fontSize: bodySize),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                icon: Icons.movie_creation_outlined,
                                title: 'مكتبة أفلام',
                                subtitle: 'تحديث مستمر',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _MiniStat(
                                icon: Icons.play_circle_outline,
                                title: 'مشغل سريع',
                                subtitle: 'تشغيل سلس',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ActionTile(
                    icon: Icons.share_rounded,
                    color: const Color(0xFFE3BA4E),
                    title: 'مشاركة التطبيق',
                    subtitle: 'شارك التطبيق مع أصدقائك',
                    onTap: _shareApp,
                  ),
                  _ActionTile(
                    icon: Icons.telegram_rounded,
                    color: const Color(0xFF45A9FF),
                    title: 'قناة تيليجرام',
                    subtitle: 'تابع آخر التحديثات',
                    onTap: () => _openLink(context, telegramUrl),
                  ),
                  _ActionTile(
                    icon: Icons.language_rounded,
                    color: const Color(0xFF7EE787),
                    title: 'تحميل التطبيق',
                    subtitle: appDownloadUrl,
                    onTap: () => _openLink(context, appDownloadUrl),
                  ),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    color: const Color(0xFFFF8A65),
                    title: 'سياسة الاستخدام',
                    subtitle: 'قراءة شروط الاستخدام',
                    onTap: () => _showPolicy(context),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E17),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFF1B2133)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عن التطبيق',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'AsMovies هو تطبيق لمشاهدة الأفلام والمسلسلات بواجهة بسيطة وسريعة. يوفر تجربة مشاهدة مريحة مع مشغل فيديو سريع وتنظيم واضح للمحتوى.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.7,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Color(0xFFE3BA4E), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'الإصدار الحالي: 1.0.0',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1B2133)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white38, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MiniStat({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1B2133)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE3BA4E)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
