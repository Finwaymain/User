import 'package:finway/constant/constant.dart';
import 'package:finway/page/features/SmartValue/AccountDetails/controller/account_details_controller.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletAccountDetailsPanel extends StatelessWidget {
  const WalletAccountDetailsPanel({super.key, required this.controller});

  final AccountDetailsController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final hasProfile = controller.accountDetailsModel.value?.data != null ||
          Constant.getUserData().data != null;

      if (controller.isLoading.value && !hasProfile) {
        return const SizedBox.shrink();
      }

      final status = controller.accountDetailsModel.value?.data?.statut == 'yes'
          ? 'Active'
          : 'Inactive';

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: TextStyle(
                color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                fontSize: 17,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Mobile Number', controller.mobile, Icons.phone_outlined, isDark),
            _detailRow('Account Number', controller.accountNumber, Icons.vpn_key_outlined, isDark),
            _detailRow(
              'Balance',
              Constant().amountShow(amount: controller.amount),
              Icons.account_balance_wallet_outlined,
              isDark,
            ),
            _detailRow(
              'Earned Amount',
              Constant().amountShow(amount: controller.earnAmount),
              Icons.trending_up,
              isDark,
            ),
            _detailRow(
              'Valid From',
              controller.expDate,
              Icons.calendar_today_outlined,
              isDark,
            ),
            _detailRow('Card Status', status, Icons.verified_outlined, isDark, isStatus: true),
          ],
        ),
      );
    });
  }

  Widget _detailRow(String label, String value, IconData icon, bool isDark, {bool isStatus = false}) {
    final statusColor = value == 'Active' ? AppThemeData.success300 : AppThemeData.error200;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppThemeData.primary300Dark.withValues(alpha: 0.2)
                  : AppThemeData.primary50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? AppThemeData.primary200 : AppThemeData.primary300,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                    fontSize: 12,
                    fontFamily: AppThemeData.regular,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isStatus ? statusColor : (isDark ? AppThemeData.grey50Dark : AppThemeData.grey50),
                    fontSize: 15,
                    fontFamily: AppThemeData.medium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
