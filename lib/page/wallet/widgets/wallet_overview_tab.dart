import 'package:finway/constant/constant.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/features/AllServices/all_services_screen.dart';
import 'package:finway/page/features/SmartValue/AccountDetails/view/account_details.dart';
import 'package:finway/page/features/SmartValue/MyQR/view/my_qr_view.dart';
import 'package:finway/page/features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import 'package:finway/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletOverviewTab extends StatelessWidget {
  const WalletOverviewTab({
    super.key,
    required this.walletController,
    required this.onTopUp,
  });

  final WalletController walletController;
  final VoidCallback onTopUp;

  void _requireLogin(VoidCallback action) {
    if (!Preferences.getBoolean(Preferences.isLogin)) {
      Get.to(() => const PhoneEntryScreen());
      return;
    }
    action();
  }

  Color _heading(bool isDark) => isDark ? AppThemeData.grey50Dark : AppThemeData.grey50;

  Color _body(bool isDark) => isDark ? AppThemeData.grey400Dark : AppThemeData.grey500;

  Color _cardBg(bool isDark) => isDark ? AppThemeData.grey100Dark : Colors.white;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Constant.getUserData().data;
    final plan = user?.consumerPlan;
    final planPoints = plan?.planPoints ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceHero(isDark),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text('Add Value'.tr, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          _buildAccountShortcut(isDark),
          const SizedBox(height: 22),
          Text('Quick Actions', style: _sectionStyle(isDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickAction(isDark, Icons.send_rounded, 'Transfer', () => _requireLogin(() => Get.to(() => ScannerAndTransferScreen()))),
              _quickAction(isDark, Icons.receipt_long_outlined, 'Pay Bills', () => _requireLogin(() => Get.to(() => const AllServicesScreen()))),
              _quickAction(isDark, Icons.qr_code_scanner_rounded, 'Scan', () => _requireLogin(() => Get.to(() => ScannerAndTransferScreen()))),
              _quickAction(isDark, Icons.qr_code_2_outlined, 'My QR', () => _requireLogin(() => Get.to(() => MyQRScreen()))),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Smart Value', style: _sectionStyle(isDark)),
              TextButton(
                onPressed: () => _requireLogin(() {
                  Get.to(() => const SubscriptionPlanScreen(isbackButton: true));
                }),
                child: Text(
                  'Upgrade Plan',
                  style: TextStyle(color: AppThemeData.primary200, fontFamily: AppThemeData.medium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => Column(
                children: [
                  _walletBalanceCard(
                    isDark,
                    title: 'Smart Value',
                    subtitle: 'Available balance',
                    amount: walletController.walletAmount.value,
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: [AppThemeData.primary200, AppThemeData.primary300],
                  ),
                  const SizedBox(height: 12),
                  _walletBalanceCard(
                    isDark,
                    title: 'Cashback Smart Value',
                    subtitle: 'Rewards & earnings',
                    amount: walletController.earnAmount.value,
                    icon: Icons.card_giftcard_rounded,
                    gradient: [AppThemeData.secondary200, AppThemeData.info200],
                  ),
                ],
              )),
          const SizedBox(height: 22),
          Text('My Benefits', style: _sectionStyle(isDark)),
          const SizedBox(height: 10),
          _benefitsCard(isDark, plan?.name, plan?.description, planPoints),
        ],
      ),
    );
  }

  Widget _buildBalanceHero(bool isDark) {
    return Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppThemeData.primary200, AppThemeData.primary300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppThemeData.primary200.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Smart Value Balance'.tr,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: AppThemeData.medium),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Constant().amountShowWithoutSymbol(amount: walletController.walletAmount.value.toString()),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cashback: ${Constant().amountShowWithoutSymbol(amount: walletController.earnAmount.value.toString())}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontFamily: AppThemeData.medium),
              ),
            ],
          ),
        ));
  }

  Widget _buildAccountShortcut(bool isDark) {
    return Material(
      color: _cardBg(isDark),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _requireLogin(() => Get.to(() => AccountDetails())),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.primary50 : AppThemeData.primary50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.credit_card_rounded, color: AppThemeData.primary200, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Card Details'.tr,
                      style: TextStyle(color: _heading(isDark), fontFamily: AppThemeData.semiBold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View Smart Value card and account info'.tr,
                      style: TextStyle(color: _body(isDark), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _body(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionStyle(bool isDark) {
    return TextStyle(color: _heading(isDark), fontSize: 17, fontFamily: AppThemeData.semiBold);
  }

  Widget _quickAction(bool isDark, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _cardBg(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey300),
              ),
              child: Icon(icon, color: AppThemeData.primary200, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: _body(isDark), fontSize: 11, fontFamily: AppThemeData.medium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefitsCard(bool isDark, String? planName, String? description, List<String> points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppThemeData.grey300Dark : AppThemeData.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (planName != null && planName.isNotEmpty)
            Text(planName, style: TextStyle(color: _heading(isDark), fontSize: 15, fontFamily: AppThemeData.semiBold)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description, style: TextStyle(color: _body(isDark), fontSize: 13)),
          ],
          if (points.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...points.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppThemeData.primary200),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point, style: TextStyle(color: _body(isDark), fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
          if ((planName == null || planName.isEmpty) && points.isEmpty && (description == null || description.isEmpty))
            Text('Subscribe to a plan to unlock wallet benefits.', style: TextStyle(color: _body(isDark), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _walletBalanceCard(
    bool isDark, {
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ],
            ),
          ),
          Text(
            Constant().amountShowWithoutSymbol(amount: amount.toString()),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
