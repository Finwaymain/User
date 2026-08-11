import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'partner_webview_screen.dart';

class ReferralEarnScreen extends StatefulWidget {
  const ReferralEarnScreen({super.key});

  @override
  State<ReferralEarnScreen> createState() => _ReferralEarnScreenState();
}

class _ReferralEarnScreenState extends State<ReferralEarnScreen> {
  String referralCode = 'FIIN8829';
  String referralLink = 'https://fiinway.online/r/FIIN8829';
  String totalReferrals = '0';
  String walletBalance = '₹0.00';
  String activeUsers = '0';
  String appInstalled = '0';
  String registered = '0';

  @override
  void initState() {
    super.initState();
    _fetchReferralStats();
  }

  Future<void> _fetchReferralStats() async {
    try {
      final userId = Preferences.getInt(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.referralStats}?user_id=$userId'),
        headers: API.header,
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == 'success' && resData['data'] != null) {
          final data = resData['data'];
          if (data['aadhar_number'] != null && (data['aadhar_number'].toString()).isNotEmpty) {
            await Preferences.setString('user_aadhar_number', data['aadhar_number'].toString());
          }
          if (mounted) {
            setState(() {
              referralCode = data['referral_code'] ?? referralCode;
              referralLink = data['referral_link'] ?? referralLink;
              totalReferrals = data['total_referrals']?.toString() ?? totalReferrals;
              walletBalance = data['wallet_balance'] ?? walletBalance;
              activeUsers = data['active_users']?.toString() ?? activeUsers;
              appInstalled = data['app_installed']?.toString() ?? '0';
              registered = data['registered']?.toString() ?? '0';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
    }
  }

  void _openHistory() {
    Get.to(
      () => const PartnerWebViewScreen(
        title: 'Referral History',
        urlPath: 'referral-history',
      ),
      transition: Transition.rightToLeftWithFade,
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      '$label Copied',
      '$text copied to clipboard!',
      backgroundColor: AppThemeData.primary200,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Scaffold(
      backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppThemeData.grey900, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Partner Dashboard'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppThemeData.grey900,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 16),
              _buildReferralShareCard(isDark),
              const SizedBox(height: 20),
              _sectionTitle('Your Referral Stats'.tr, isDark),
              const SizedBox(height: 12),
              _buildStatsRow(isDark),
              const SizedBox(height: 16),
              _buildTotalReferralBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontFamily: AppThemeData.bold,
        color: isDark ? AppThemeData.grey900Dark : AppThemeData.primary200,
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppThemeData.primary200,
            AppThemeData.primary200.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.primary200.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Program'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontFamily: AppThemeData.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share. Connect. Earn Together'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralShareCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Referral Code'.tr,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.bold,
              color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          _buildCopyField(referralCode, isDark, center: true),
          const SizedBox(height: 14),
          Text(
            'Your Referral Link'.tr,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.bold,
              color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 8),
          _buildCopyField(referralLink, isDark),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(referralLink, 'Referral Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              label: Text(
                'Share Now'.tr,
                style: const TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyField(String text, bool isDark, {bool center = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppThemeData.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (!center)
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 12, fontFamily: AppThemeData.medium, color: AppThemeData.primary200),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (center)
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.bold,
                color: AppThemeData.primary200,
                letterSpacing: 1.5,
              ),
            ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _copyToClipboard(text, center ? 'Referral Code' : 'Referral Link'),
            child: Icon(Icons.copy_rounded, color: AppThemeData.primary200, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final stats = [
      {'label': 'Total Referrals', 'value': totalReferrals, 'icon': Icons.groups_rounded},
      {'label': 'App Installed', 'value': appInstalled, 'icon': Icons.install_mobile_rounded},
      {'label': 'Registered', 'value': registered, 'icon': Icons.how_to_reg_rounded},
      {'label': 'Active Users', 'value': activeUsers, 'icon': Icons.verified_rounded},
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildStatCard(stats[i], isDark)),
        ],
      ],
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemeData.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(stat['icon'] as IconData, color: AppThemeData.primary200, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            stat['value'] as String,
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.bold,
              color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (stat['label'] as String).tr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontFamily: AppThemeData.medium,
              color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalReferralBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Referrals'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalReferrals,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.primary200,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: Text(
              'History'.tr,
              style: const TextStyle(fontSize: 14, fontFamily: AppThemeData.semiBold),
            ),
          ),
        ],
      ),
    );
  }
}
