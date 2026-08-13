import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:finway/constant/constant.dart';

import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_history_screen.dart';

class ServicePaymentSuccessScreen extends StatelessWidget {
  final int bookingId;
  final double amountPaid;
  final String paymentMethod;

  const ServicePaymentSuccessScreen({
    super.key,
    required this.bookingId,
    required this.amountPaid,
    required this.paymentMethod,
  });

  String _money(double value) => '${Constant.currency ?? ''}${value.toStringAsFixed(0)}';

  String get _methodLabel {
    switch (paymentMethod.toLowerCase()) {
      case 'wallet':
        return 'Wallet'.tr;
      case 'upi':
        return 'UPI'.tr;
      default:
        return 'Cash / Other'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppThemeData.success300.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle_rounded, color: AppThemeData.success300, size: 56),
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment Successful!'.tr,
                  style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 24, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your home service payment has been completed.'.tr,
                  style: TextStyle(fontSize: 14, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Amount Paid'.tr, _money(amountPaid), isDarkMode, bold: true),
                      _detailRow('Payment Method'.tr, _methodLabel, isDarkMode),
                      _detailRow('Booking ID'.tr, '#$bookingId', isDarkMode),
                    ],
                  ),
                ),
                const Spacer(),
                ButtonThem.buildButton(
                  context,
                  title: 'View Booking History'.tr,
                  btnColor: AppThemeData.primary200,
                  radius: 12,
                  onPress: () {
                    Get.offAll(() => const ServiceHistoryScreen(initialTab: 2));
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.offAll(() => const MainDashboard()),
                  child: Text('Back to Home'.tr, style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.semiBold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDarkMode, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500))),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 18 : 13,
              fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold,
              color: bold ? AppThemeData.primary200 : (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
          ),
        ],
      ),
    );
  }
}
