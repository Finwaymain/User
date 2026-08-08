import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:finway/service/api.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/page/wallet/wallet_screen.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({super.key});

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> {
  bool isLoading = true;
  String totalReferrals = '0';
  String appInstalled = '0';
  String registered = '0';
  String activeUsers = '0';
  String walletBalance = '₹0.00';
  String verified = '0';
  String activeBusiness = '0';
  String activeServices = '0';
  String totalTransactions = '0';
  List<Map<String, dynamic>> recentUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchReferralHistory();
  }

  Future<void> _fetchReferralHistory() async {
    try {
      final userId = Preferences.getInt(Preferences.userId);
      final response = await http.get(
        Uri.parse('${API.referralHistory}?user_id=$userId'),
        headers: API.header,
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['success'] == 'success' && resData['data'] != null) {
          final data = resData['data'];
          final stats = data['stats'] ?? {};
          final summary = data['summary'] ?? {};
          final users = data['recent_users'] as List<dynamic>? ?? [];

          if (mounted) {
            setState(() {
              totalReferrals = stats['total_referrals']?.toString() ?? '0';
              appInstalled = (summary['app_installed'] ?? stats['app_installed'] ?? 0).toString();
              registered = (summary['registered'] ?? stats['registered'] ?? 0).toString();
              activeUsers = stats['active_users']?.toString() ?? '0';
              walletBalance = stats['wallet_balance']?.toString() ?? '₹0.00';
              verified = (summary['verified'] ?? stats['verified'] ?? 0).toString();
              activeBusiness = (summary['active_business'] ?? stats['active_business'] ?? 0).toString();
              activeServices = (summary['active_services'] ?? stats['active_services'] ?? 0).toString();
              totalTransactions = (summary['total_transactions'] ?? stats['total_transactions'] ?? 0).toString();
              recentUsers = users.map((user) => Map<String, dynamic>.from(user as Map)).toList();
              isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching referral history: $e');
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _summaryStats => [
        {'label': 'App Installed', 'value': appInstalled, 'icon': Icons.install_mobile_rounded},
        {'label': 'Registered', 'value': registered, 'icon': Icons.person_rounded},
        {'label': 'Verified', 'value': verified, 'icon': Icons.verified_user_rounded},
        {'label': 'Active Business', 'value': activeBusiness, 'icon': Icons.business_center_rounded},
        {'label': 'Active Services', 'value': activeServices, 'icon': Icons.home_repair_service_rounded},
        {'label': 'Total Transactions', 'value': totalTransactions, 'icon': Icons.receipt_long_rounded},
      ];

  IconData _iconForCategory(String category, String type) {
    final value = category.toLowerCase();
    if (value.contains('food') || value.contains('restaurant')) return Icons.restaurant_rounded;
    if (value.contains('home') || value.contains('service')) return Icons.home_rounded;
    if (value.contains('cab') || value.contains('driver') || value.contains('transport')) {
      return Icons.local_taxi_rounded;
    }
    if (type == 'customer') return Icons.person_rounded;
    return Icons.business_center_rounded;
  }

  Color _colorForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('food') || value.contains('restaurant')) return const Color(0xFFF97316);
    if (value.contains('home') || value.contains('service')) return AppThemeData.primary200;
    return AppThemeData.primary300;
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
          'Referral History'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : AppThemeData.grey900,
            fontFamily: AppThemeData.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchReferralHistory,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Your Referral Stats'.tr, isDark),
                      const SizedBox(height: 12),
                      _buildStatsRow(isDark),
                      const SizedBox(height: 20),
                      _sectionTitle('Your Earnings'.tr, isDark),
                      const SizedBox(height: 12),
                      _buildEarningsCard(isDark),
                      const SizedBox(height: 20),
                      _sectionTitle('Business Referral Summary'.tr, isDark),
                      const SizedBox(height: 12),
                      _buildSummaryGrid(isDark),
                      const SizedBox(height: 20),
                      _sectionTitle('Business Users - Recent'.tr, isDark),
                      const SizedBox(height: 12),
                      _buildRecentUsersList(isDark),
                    ],
                  ),
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
          Expanded(child: _statCard(stats[i], isDark)),
        ],
      ],
    );
  }

  Widget _statCard(Map<String, dynamic> stat, bool isDark) {
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

  Widget _buildEarningsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.primary50.withValues(alpha: 0.15) : AppThemeData.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFF97316), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referral Smart Value Balance'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  walletBalance,
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.primary200,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.to(() => WalletScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary200,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(
              'View History'.tr,
              style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.semiBold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _summaryStats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final stat = _summaryStats[index];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppThemeData.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stat['icon'] as IconData, color: AppThemeData.primary200, size: 16),
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
                    fontSize: 9,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentUsersList(bool isDark) {
    if (recentUsers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 42, color: AppThemeData.grey400),
            const SizedBox(height: 10),
            Text(
              'No referral users yet'.tr,
              style: TextStyle(
                fontSize: 14,
                fontFamily: AppThemeData.medium,
                color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
      ),
      child: Column(
        children: [
          for (int i = 0; i < recentUsers.length; i++) ...[
            if (i > 0) Divider(height: 1, color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey200),
            _recentUserTile(recentUsers[i], isDark),
          ],
        ],
      ),
    );
  }

  Widget _recentUserTile(Map<String, dynamic> user, bool isDark) {
    final category = user['category']?.toString() ?? 'Customer';
    final type = user['type']?.toString() ?? 'customer';
    final icon = _iconForCategory(category, type);
    final iconColor = _colorForCategory(category);
    final status = user['status']?.toString() ?? 'Pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name']?.toString() ?? 'User',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? AppThemeData.grey500Dark : AppThemeData.grey500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemeData.primary50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.tr,
              style: TextStyle(
                fontSize: 11,
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.primary200,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            user['amount']?.toString() ?? '₹0.00',
            style: TextStyle(
              fontSize: 14,
              fontFamily: AppThemeData.bold,
              color: isDark ? AppThemeData.grey900Dark : AppThemeData.grey900,
            ),
          ),
        ],
      ),
    );
  }
}
