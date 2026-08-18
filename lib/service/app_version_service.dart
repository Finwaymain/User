import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../themes/constant_colors.dart';
import 'api.dart';

class AppVersionService {
  static bool _hasChecked = false;

  /// Check version on app start or manual trigger
  static Future<void> checkAppVersion({
    String appType = 'customer',
    bool forceCheck = false,
  }) async {
    if (_hasChecked && !forceCheck) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;
      final platform = Platform.isIOS ? 'ios' : 'android';

      final url = Uri.parse(
        '${API.checkAppVersion}?app_type=$appType&version=$installedVersion&platform=$platform',
      );

      final res = await http.get(url, headers: API.header);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == 'success' && body['data'] != null) {
          final data = body['data'];
          _hasChecked = true;

          final bool isMaintenance = data['is_maintenance'] == true;
          final bool forceUpdate = data['force_update'] == true;
          final bool optionalUpdate = data['optional_update'] == true;
          final String title = data['title']?.toString() ?? 'Update Available';
          final String message = data['message']?.toString() ??
              'A new version of the app is available on the Play Store. Please update now.';
          final String storeUrl = data['store_url']?.toString() ?? '';
          final String latestVersion = data['latest_version']?.toString() ?? installedVersion;
          final String maintenanceMsg = data['maintenance_message']?.toString() ??
              'Fiinway services are currently undergoing maintenance.';

          if (isMaintenance) {
            _showMaintenanceDialog(maintenanceMsg);
          } else if (forceUpdate && storeUrl.isNotEmpty) {
            _showForceUpdateDialog(
              title: title,
              message: message,
              storeUrl: storeUrl,
              installedVersion: installedVersion,
              latestVersion: latestVersion,
            );
          } else if (optionalUpdate && storeUrl.isNotEmpty) {
            _showOptionalUpdateDialog(
              title: title,
              message: message,
              storeUrl: storeUrl,
              installedVersion: installedVersion,
              latestVersion: latestVersion,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('AppVersionService check error: $e');
    }
  }

  /// Non-Dismissible Compulsory Update Screen
  static void _showForceUpdateDialog({
    required String title,
    required String message,
    required String storeUrl,
    required String installedVersion,
    required String latestVersion,
  }) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Rocket Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppThemeData.primary200, AppThemeData.primary300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.primary200.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.system_update_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: AppThemeData.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Version Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Installed: v$installedVersion  ➜  Latest: v$latestVersion',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.bold,
                      color: AppThemeData.primary200,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Message
                Text(
                  message.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Update Now Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _openStore(storeUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      shadowColor: AppThemeData.primary200.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shop_two_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Update from Play Store'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Optional Update Dialog
  static void _showOptionalUpdateDialog({
    required String title,
    required String message,
    required String storeUrl,
    required String installedVersion,
    required String latestVersion,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppThemeData.primary200.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.new_releases_outlined,
                    color: AppThemeData.primary200,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: AppThemeData.bold,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'v$latestVersion is available (You have v$installedVersion)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              Text(
                message.tr,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Maybe Later'.tr,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontFamily: AppThemeData.medium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _openStore(storeUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeData.primary200,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Update'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: AppThemeData.bold,
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
    );
  }

  /// Maintenance Mode Screen
  static void _showMaintenanceDialog(String message) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.build_rounded, color: Color(0xFFF59E0B), size: 36),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Under Maintenance'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: AppThemeData.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Launch Play Store URL in external browser / app store
  static Future<void> _openStore(String storeUrl) async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error'.tr, 'Could not open Play Store.'.tr);
      }
    } catch (e) {
      debugPrint('Error launching store URL: $e');
    }
  }
}
