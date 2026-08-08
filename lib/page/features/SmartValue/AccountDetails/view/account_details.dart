import 'package:finway/page/wallet/widgets/wallet_account_details_panel.dart';
import 'package:finway/page/wallet/widgets/wallet_flip_card.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/custom_base_widget.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controller/account_details_controller.dart';

class AccountDetails extends StatelessWidget {
  AccountDetails({super.key});

  final AccountDetailsController controller = Get.put(AccountDetailsController());

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: 'Account Details',
      body: RefreshIndicator(
        color: AppThemeData.primary200,
        onRefresh: () async {
          controller.resetCardState();
          final acNo = controller.accountNumber;
          if (acNo.isNotEmpty && acNo != 'N/A') {
            await controller.getAccountDetails(acNo);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Value Card',
                style: TextStyle(
                  color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                  fontSize: 18,
                  fontFamily: AppThemeData.semiBold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the card to flip and view more details',
                style: TextStyle(
                  color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              WalletFlipCard(controller: controller),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      isDark: isDark,
                      icon: Icons.flip_camera_android_rounded,
                      label: 'Flip Card',
                      filled: false,
                      onTap: controller.flipCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      isDark: isDark,
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      filled: true,
                      onTap: () {
                        controller.resetCardState();
                        final acNo = controller.accountNumber;
                        if (acNo.isNotEmpty && acNo != 'N/A') {
                          controller.getAccountDetails(acNo);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              WalletAccountDetailsPanel(controller: controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? AppThemeData.primary200 : (isDark ? AppThemeData.surface50Dark : AppThemeData.primary50),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : AppThemeData.primary200),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled ? Colors.white : AppThemeData.primary200,
                    fontFamily: AppThemeData.semiBold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
