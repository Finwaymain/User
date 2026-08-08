import 'package:finway/constant/constant.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/model/transaction_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletTransactionsTab extends StatelessWidget {
  const WalletTransactionsTab({super.key, required this.controller});

  final WalletController controller;

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return Obx(() {
      if (controller.isLoading.value && controller.walletList.isEmpty) {
        return Center(child: CircularProgressIndicator(color: AppThemeData.primary200));
      }

      if (controller.walletList.isEmpty) {
        return Center(child: Constant.emptyView(context, "Transaction not found.", false));
      }

      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: controller.walletList.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: themeChange.getThem() ? AppThemeData.grey300Dark : AppThemeData.grey300,
        ),
        itemBuilder: (context, index) {
          return _transactionTile(context, controller.walletList[index], themeChange.getThem());
        },
      );
    });
  }

  Widget _transactionTile(BuildContext context, TransactionData data, bool isDark) {
    final isCredit = data.deductionType.toString() == "1";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppThemeData.success50
                  : (isDark ? AppThemeData.error50 : AppThemeData.error50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              isCredit ? "assets/icons/ic_up_arrow.svg" : "assets/icons/ic_down_arrow.svg",
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                isCredit ? AppThemeData.success300 : AppThemeData.error200,
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCredit
                        ? "${"Wallet Top-up via".tr} ${data.paymentMethod ?? ''}"
                        : "Payment for Trip".tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.creer.toString(),
                    style: TextStyle(
                      fontFamily: AppThemeData.regular,
                      color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            isCredit
                ? "+${Constant().amountShow(amount: data.amount.toString())}"
                : "-${Constant().amountShow(amount: data.amount.toString())}",
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              fontSize: 15,
              color: isCredit ? AppThemeData.success300 : AppThemeData.error200,
            ),
          ),
        ],
      ),
    );
  }
}
