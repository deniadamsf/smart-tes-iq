import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class VersionCheckService {
  static const MethodChannel _channel =
      MethodChannel('com.cellanomadigital.smart_tes_iq/app_info');

  static const String _versionUrl =
      'https://smarttesiq.cellanoma.my.id/public/app_version.php';

  static const String _defaultStoreUrl =
      'https://play.google.com/store/apps/details?id=com.cellanomadigital.smart_tes_iq';

  // Fallback jika MethodChannel gagal dipanggil
  static const String _fallbackVersionName = '2.3.6';
  static const int _fallbackVersionCode = 20;

  static bool _isDialogShowing = false;

  /// Mengambil versi aplikasi saat ini langsung dari PackageManager Android.
  static Future<Map<String, dynamic>> _getCurrentVersion() async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>('getAppVersion');
      if (res != null) {
        return {
          'versionName': (res['versionName'] ?? _fallbackVersionName).toString(),
          'versionCode': int.tryParse('${res['versionCode']}') ?? _fallbackVersionCode,
        };
      }
    } catch (e) {
      debugPrint('[VersionCheckService] Fallback version info: $e');
    }
    return {
      'versionName': _fallbackVersionName,
      'versionCode': _fallbackVersionCode,
    };
  }

  /// Membandingkan dua string versi semantik (contoh: "2.3.4" < "2.3.5").
  /// Mengembalikan true jika [current] lebih rendah dari [minimum].
  static bool _isVersionLower(String current, String minimum) {
    final currParts = current
        .split('+').first
        .split('.')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .toList();
    final minParts = minimum
        .split('+').first
        .split('.')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .toList();

    final maxLen = currParts.length > minParts.length ? currParts.length : minParts.length;
    for (int i = 0; i < maxLen; i++) {
      final c = i < currParts.length ? currParts[i] : 0;
      final m = i < minParts.length ? minParts[i] : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }

  /// Mengecek versi minimal ke server hosting dan menampilkan dialog Force Update
  /// apabila versi aplikasi pengguna masih di bawah batas minimal.
  static Future<void> checkAndEnforceUpdate(BuildContext context) async {
    if (_isDialogShowing) return;

    try {
      final current = await _getCurrentVersion();
      final String currentVersionName = current['versionName'] as String;
      final int currentVersionCode = current['versionCode'] as int;

      final uri = Uri.parse(
        '$_versionUrl?t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final String minVersion = (data['min_version'] ?? currentVersionName).toString();
      final int minBuildNumber =
          int.tryParse('${data['min_build_number'] ?? 0}') ?? 0;
      final bool forceUpdate = data['force_update'] != false;
      final String storeUrl =
          (data['store_url'] ?? _defaultStoreUrl).toString().trim();

      final bool needsUpdate = _isVersionLower(currentVersionName, minVersion) ||
          (minBuildNumber > 0 && currentVersionCode < minBuildNumber);

      if (!needsUpdate) return;
      if (!context.mounted) return;

      final bool isEn = context.locale.languageCode == 'en';
      final String message = isEn
          ? (data['message_en'] ??
                  'A new version of Smart Tes IQ is available. Please update the app to continue.')
              .toString()
          : (data['message_id'] ??
                  'Versi terbaru Smart Tes IQ telah tersedia. Silakan perbarui aplikasi untuk melanjutkan.')
              .toString();

      _showUpdateDialog(
        context: context,
        currentVersion: currentVersionName,
        minVersion: minVersion,
        message: message,
        storeUrl: storeUrl.isEmpty ? _defaultStoreUrl : storeUrl,
        forceUpdate: forceUpdate,
        isEn: isEn,
      );
    } catch (e) {
      debugPrint('[VersionCheckService] Gagal cek versi: $e');
    }
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String minVersion,
    required String message,
    required String storeUrl,
    required bool forceUpdate,
    required bool isEn,
  }) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !forceUpdate,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 36,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isEn ? 'Update Required' : 'Pembaruan Tersedia',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'v$currentVersion  ➔  v$minVersion',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(storeUrl);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        isEn ? 'Update Now on Play Store' : 'Update Sekarang di Play Store',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (!forceUpdate) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _isDialogShowing = false;
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        isEn ? 'Later' : 'Nanti Saja',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}
