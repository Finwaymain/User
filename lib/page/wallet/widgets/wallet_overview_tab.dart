import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/features/AllServices/all_services_screen.dart';
import 'package:finway/page/features/SmartValue/AccountDetails/view/account_details.dart';
import 'package:finway/page/features/SmartValue/MyQR/view/my_qr_view.dart';
import 'package:finway/page/features/SmartValue/ScanAndTransfer/view/scanner_and_transfer_screen.dart';
import 'package:finway/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:finway/page/web_view_screen/web_view_screen.dart';
import 'package:finway/page/finance/finance_screen.dart';
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
          _buildLoansAndCreditSection(context, isDark),
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
                  if (walletController.hasPromo.value) ...[
                    const SizedBox(height: 10),
                    _walletBalanceCard(
                      isDark,
                      title: 'Promotions',
                      subtitle: '₹${walletController.promoDiscountPerService.value.toStringAsFixed(0)} off • ${walletController.promoUsesRemaining.value} uses',
                      amount: walletController.promoBalance.value,
                      icon: Icons.confirmation_number_outlined,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                  ],
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

  Widget _buildLoansAndCreditSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loans & Credit',
              style: _sectionStyle(isDark),
            ),
            GestureDetector(
              onTap: () => _openLoanWebview(
                cardType: 'Loans & Credit',
                title: 'Loans & Credit',
                amount: 'Up to ₹5,00,000',
              ),
              child: const Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 1: 4 Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Interest Free Loan
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFDCFCE7),
                imageAsset: 'assets/images/loan_interest_free.png',
                title: 'Interest Free\nLoan',
                subtitle: 'Upto ₹2,00,000',
                subtitleColor: const Color(0xFF16A34A),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFF16A34A),
                onTap: () => _openLoanWebview(
                  cardType: 'Interest Free Loan',
                  title: 'Interest Free Loan',
                  amount: '₹2,00,000',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Card 2: 0 CIBIL Loan
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFDBEAFE),
                imageAsset: 'assets/images/loan_zero_cibil.png',
                title: '0 CIBIL\nLoan',
                subtitle: 'Upto ₹5,00,000',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFF2563EB),
                onTap: () => _openLoanWebview(
                  cardType: '0 CIBIL Loan',
                  title: '0 CIBIL Loan',
                  amount: '₹5,00,000',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Card 3: Low CIBIL Loan
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFED7AA),
                imageAsset: 'assets/images/loan_low_cibil.png',
                title: 'Low CIBIL\nLoan',
                subtitle: 'Fast Approval',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFFEA580C),
                onTap: () => _openLoanWebview(
                  cardType: 'Low CIBIL Loan',
                  title: 'Low CIBIL Loan',
                  amount: 'Fast Approval',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Card 4: CIBIL Score Check
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFEDE9FE),
                imageAsset: 'assets/images/loan_cibil_check.png',
                title: 'CIBIL\nScore Check',
                subtitle: 'Free & Instant',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Check Now',
                buttonColor: const Color(0xFF6366F1),
                onTap: () => _openAffiliateUrl(
                  'https://EasyPe.o18a.com/c?o=21966472&m=26892&a=761563&sub_aff_id={replace_it}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: 4 Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 5: Novio FD Credit Card
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFDCFCE7),
                imageAsset: 'assets/images/loan_novio_card.png',
                title: 'Novio FD\nCredit Card',
                subtitle: 'FD Backed\nEasy Approval',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFF16A34A),
                onTap: () => _openAffiliateUrl(
                  'https://EasyPe.o18a.com/c?o=21966470&m=26892&a=761563&sub_aff_id={replace_it}',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Card 6: SBI Credit Card
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFDBEAFE),
                imageAsset: 'assets/images/loan_sbi_card.png',
                title: 'SBI\nCredit Card',
                subtitle: 'Multiple Cards\nGreat Rewards',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFF2563EB),
                onTap: () => _openSbiCreditCardFlow(context),
              ),
            ),
            const SizedBox(width: 6),
            // Card 7: Personal Loan
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFFFF7ED),
                borderColor: const Color(0xFFFED7AA),
                imageAsset: 'assets/images/loan_personal_loan.png',
                title: 'Personal\nLoan',
                subtitle: 'Upto ₹50 Lakh',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFFEA580C),
                onTap: () => _openAffiliateUrl(
                  'https://EasyPe.o18a.com/c?o=21983875&m=26892&a=761563&sub_aff_id={replace_it}',
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Card 8: Business Loan
            Expanded(
              child: _gridLoanCard(
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFEDE9FE),
                imageAsset: 'assets/images/loan_business_loan.png',
                title: 'Business\nLoan',
                subtitle: 'Upto ₹1 Crore',
                subtitleColor: const Color(0xFF64748B),
                buttonText: 'Apply Now',
                buttonColor: const Color(0xFF6366F1),
                onTap: () => _openBusinessLoanAndPrivateFunding(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gridLoanCard({
    required Color bgColor,
    required Color borderColor,
    required String imageAsset,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              width: double.infinity,
              child: Center(
                child: Image.asset(
                  imageAsset,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 26,
              child: Text(
                title,
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 24,
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              height: 22,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 1),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAffiliateUrl(String template) {
    _requireLogin(() async {
      final user = Constant.getUserData().data;
      String phone = (user?.phone ?? '').trim();
      phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.length > 10) {
        phone = phone.substring(phone.length - 10);
      }
      if (phone.isEmpty) {
        phone = user?.id?.toString() ?? 'fiinway';
      }

      final targetUrl = template.replaceAll('{replace_it}', phone);
      final uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    });
  }

  void _openBusinessLoanAndPrivateFunding() {
    _requireLogin(() {
      final user = Constant.getUserData().data;
      final prenom = user?.prenom ?? '';
      final nom = user?.nom ?? '';
      final fullName = ('$prenom $nom').trim().isNotEmpty
          ? ('$prenom $nom').trim()
          : 'Valued Customer';
      final mobile = user?.phone ?? '';
      final pocketNumber = user?.acNo ?? '';

      final queryParams = {
        'phone': mobile,
        'mobile': mobile,
        'name': fullName,
        'pocket_number': pocketNumber,
        'user_type': 'customer',
        'hide_header': '1',
      };

      final uri = Uri.parse("https://api.fiinway.com/finance/large-funding/intro")
          .replace(queryParameters: queryParams);

      Get.to(() => FinanceScreen(initialUrl: uri.toString(), isTab: false));
    });
  }

  void _openSbiCreditCardFlow(BuildContext context) {
    _requireLogin(() {
      final user = Constant.getUserData().data;
      final prenom = user?.prenom ?? '';
      final nom = user?.nom ?? '';
      final fullName = ('$prenom $nom').trim().isNotEmpty
          ? ('$prenom $nom').trim()
          : '';
      final mobile = user?.phone ?? '';
      final email = user?.email ?? '';

      final nameController = TextEditingController(text: fullName);
      final phoneController = TextEditingController(text: mobile);
      final emailController = TextEditingController(text: email);
      final refCodeController = TextEditingController();

      bool isSubmitting = false;

      Get.bottomSheet(
        StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/images/loan_sbi_card.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SBI Credit Card Application',
                                style: TextStyle(
                                  fontFamily: AppThemeData.bold,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Fill details to proceed to official SBI Card portal',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name as per PAN',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Mobile Number *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit mobile number',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Email Address (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Referral Code (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: refCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter referral code if any',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final enteredName = nameController.text.trim();
                                final enteredPhone = phoneController.text.trim();
                                if (enteredName.isEmpty) {
                                  Get.snackbar('Required', 'Please enter your Full Name',
                                      snackPosition: SnackPosition.BOTTOM);
                                  return;
                                }
                                if (enteredPhone.isEmpty || enteredPhone.length < 10) {
                                  Get.snackbar('Required', 'Please enter a valid 10-digit mobile number',
                                      snackPosition: SnackPosition.BOTTOM);
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);

                                String redirectUrl =
                                    'https://EasyPe.o18a.com/c?o=21983875&m=26892&a=761563&sub_aff_id=$enteredPhone';

                                try {
                                  final response = await http.post(
                                    Uri.parse('https://api.fiinway.com/api/v1/finance/affiliate-lead'),
                                    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
                                    body: jsonEncode({
                                      'name': enteredName,
                                      'phone': enteredPhone,
                                      'email': emailController.text.trim(),
                                      'referral_code': refCodeController.text.trim(),
                                      'lender_name': 'SBI Credit Card',
                                    }),
                                  );
                                  if (response.statusCode == 200) {
                                    final data = jsonDecode(response.body);
                                    if (data['redirect_url'] != null && data['redirect_url'].toString().isNotEmpty) {
                                      redirectUrl = data['redirect_url'].toString();
                                    }
                                  }
                                } catch (_) {}

                                if (Get.isBottomSheetOpen == true) {
                                  Get.back();
                                }

                                final uri = Uri.parse(redirectUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  await launchUrl(uri);
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Proceed to SBI Card ›',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        isScrollControlled: true,
      );
    });
  }

  void _openLoanWebview({
    required String cardType,
    required String title,
    required String amount,
  }) {
    _requireLogin(() {
      final user = Constant.getUserData().data;
      final prenom = user?.prenom ?? '';
      final nom = user?.nom ?? '';
      final fullName = ('$prenom $nom').trim().isNotEmpty
          ? ('$prenom $nom').trim()
          : 'Valued Customer';
      final mobile = user?.phone ?? '';
      final pocketNumber = user?.acNo ?? '';

      final queryParams = {
        'card_type': cardType,
        'title': title,
        'amount': amount,
        'name': fullName,
        'phone': mobile,
        'mobile': mobile,
        'pocket_number': pocketNumber,
        'user_type': 'customer',
        'hide_header': '1',
      };

      String subPath = '';
      if (cardType == '0 CIBIL Loan' || cardType == 'Interest Free Loan') {
        subPath = '/zero-cibil/intro';
      } else if (cardType == 'Low CIBIL Loan') {
        subPath = '/cash-loan/apply';
      }

      final uri = Uri.parse("https://api.fiinway.com/finance$subPath")
          .replace(queryParameters: queryParams);

      Get.to(() => FinanceScreen(initialUrl: uri.toString(), isTab: false));
    });
  }
}
