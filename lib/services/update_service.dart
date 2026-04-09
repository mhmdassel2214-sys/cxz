import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  UpdateService._();

  static const String versionJsonUrl =
      'https://asmovies-watch.pages.dev/version.json';

  static bool _dialogShown = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (_dialogShown || versionJsonUrl.trim().isEmpty) return;

    try {
      final uri = Uri.parse(versionJsonUrl).replace(
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await http.get(uri, headers: const {
        'cache-control': 'no-cache',
        'pragma': 'no-cache',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return;

      final latestVersion = (data['version'] ?? '').toString().trim();
      final latestBuild = int.tryParse((data['build'] ?? '0').toString()) ?? 0;
      final downloadUrl = (data['apk_url'] ??
              data['url'] ??
              data['downloadUrl'] ??
              data['apkUrl'] ??
              '')
          .toString()
          .trim();
      final forceUpdate = data['force_update'] == true || data['force'] == true;
      final headerTitle =
          (data['title'] ?? 'تحديث جديد جاهز الآن').toString().trim();
      final message = (data['message'] ??
              'أطلقنا إصدارًا أحدث من AsMovies بتحسينات على الاستقرار، الأداء، وتجربة الاستخدام.')
          .toString()
          .trim();
      final whatsNew = _extractWhatsNew(data);

      if (latestVersion.isEmpty || downloadUrl.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final currentBuild = int.tryParse(packageInfo.buildNumber.trim()) ?? 0;

      final hasUpdate = _isNewerVersion(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        latestBuild: latestBuild,
        currentBuild: currentBuild,
      );

      if (!hasUpdate && !forceUpdate) return;
      if (!context.mounted) return;

      _dialogShown = true;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: !forceUpdate,
        enableDrag: !forceUpdate,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => WillPopScope(
          onWillPop: () async => !forceUpdate,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _UpdateSheet(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              forceUpdate: forceUpdate,
              title: headerTitle,
              message: message,
              whatsNew: whatsNew,
              onUpdate: () async {
                await _openDownloadUrl(downloadUrl);
                if (sheetContext.mounted && Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              },
            ),
          ),
        ),
      );
    } catch (_) {
      // تجاهل الخطأ حتى لا يتعطل التطبيق
    } finally {
      _dialogShown = false;
    }
  }

  static List<String> _extractWhatsNew(Map<String, dynamic> data) {
    final raw = data['changelog'] ?? data['whatsNew'] ?? data['features'] ?? data['notes'];

    if (raw is List) {
      final list = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }

    return const [
      'تحسينات على السرعة والثبات داخل التطبيق',
      'تجربة أفضل عند التصفح وتشغيل المحتوى',
      'إصلاحات عامة لأخطاء ظهرت في النسخ السابقة',
    ];
  }

  static bool _isNewerVersion({
    required String latestVersion,
    required String currentVersion,
    required int latestBuild,
    required int currentBuild,
  }) {
    final latestParts = _normalizeVersion(latestVersion);
    final currentParts = _normalizeVersion(currentVersion);
    final maxLength = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (var i = 0; i < maxLength; i++) {
      final latestValue = i < latestParts.length ? latestParts[i] : 0;
      final currentValue = i < currentParts.length ? currentParts[i] : 0;

      if (latestValue > currentValue) return true;
      if (latestValue < currentValue) return false;
    }

    return latestBuild > currentBuild;
  }

  static List<int> _normalizeVersion(String version) {
    return version
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }

  static Future<void> _openDownloadUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _UpdateSheet extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final List<String> whatsNew;
  final Future<void> Function() onUpdate;

  const _UpdateSheet({
    required this.currentVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    required this.whatsNew,
    required this.onUpdate,
  });

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2A3144)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.40),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD5B13E), Color(0xFF9C7323)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.system_update_alt_rounded,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _VersionBadge(label: 'الإصدار الجديد', value: widget.latestVersion),
                  const SizedBox(width: 10),
                  _VersionBadge(label: 'نسختك الحالية', value: widget.currentVersion),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'ما الجديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...widget.whatsNew.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD5B13E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating
                      ? null
                      : () async {
                          setState(() => _isUpdating = true);
                          try {
                            await widget.onUpdate();
                          } finally {
                            if (mounted) setState(() => _isUpdating = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5B13E),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFF8F7840),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                        )
                      : const Text(
                          'تحديث الآن',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                ),
              ),
              if (!widget.forceUpdate) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF2A3144)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'لاحقًا',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final String value;

  const _VersionBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141A26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A3144)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
