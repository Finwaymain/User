import 'package:finway/constant/constant.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/model/transaction_model.dart';
import 'package:finway/page/wallet/utils/transaction_history_display.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletTransactionsTab extends StatelessWidget {
  const WalletTransactionsTab({
    super.key,
    required this.controller,
    this.onRefresh,
  });

  final WalletController controller;
  final Future<void> Function()? onRefresh;

  static const _filterOptions = <Map<String, dynamic>>[
    {'label': 'Last 7 Days', 'days': 7},
    {'label': 'Last 30 Days', 'days': 30},
    {'label': 'Last 90 Days', 'days': 90},
    {'label': 'All Time', 'days': 0},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<DarkThemeProvider>(context).getThem();

    return Obx(() {
      if (controller.isLoading.value && controller.walletList.isEmpty) {
        return Center(
          child: CircularProgressIndicator(color: AppThemeData.primary200),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterButton(context, isDark),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              color: AppThemeData.primary200,
              onRefresh: onRefresh ?? () async {},
              child: controller.walletList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.35,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions found'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: controller.walletList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _TransactionCard(
                          data: controller.walletList[index],
                          isDark: isDark,
                          onTap: () => _showReceiptSheet(context, controller.walletList[index], isDark),
                        );
                      },
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFilterButton(BuildContext context, bool isDark) {
    final selected = _filterOptions.firstWhere(
      (item) => item['days'] == controller.historyDaysFilter.value,
      orElse: () => _filterOptions[1],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<int>(
        onSelected: controller.setHistoryDaysFilter,
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => _filterOptions
            .map(
              (item) => PopupMenuItem<int>(
                value: item['days'] as int,
                child: Text(
                  (item['label'] as String).tr,
                  style: TextStyle(
                    fontFamily: controller.historyDaysFilter.value == item['days']
                        ? AppThemeData.semiBold
                        : AppThemeData.medium,
                  ),
                ),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey100Dark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppThemeData.grey300Dark : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 15,
                color: isDark ? AppThemeData.grey300Dark : const Color(0xFF1E1B4B),
              ),
              const SizedBox(width: 8),
              Text(
                (selected['label'] as String).tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 13,
                  color: isDark ? AppThemeData.grey50Dark : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark ? AppThemeData.grey400Dark : const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReceiptSheet(BuildContext context, TransactionData data, bool isDark) {
    final category = TransactionHistoryDisplay.categoryTitle(data);
    final counterparty = TransactionHistoryDisplay.counterpartyName(data);
    final status = TransactionHistoryDisplay.statusLabel(data);
    final amount = Constant().amountShow(amount: data.amount.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppThemeData.surface50Dark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppThemeData.grey300Dark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Receipt'.tr,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 18,
                      color: isDark ? AppThemeData.grey50Dark : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TransactionHistoryDisplay.statusBackground(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.tr,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 11,
                        color: TransactionHistoryDisplay.statusTextColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _receiptRow('Service'.tr, category, isDark),
              _receiptRow('Paid To / From'.tr, counterparty, isDark),
              _receiptRow('Amount'.tr, amount, isDark, isBold: true),
              _receiptRow('Date'.tr, TransactionHistoryDisplay.displayDate(data), isDark),
              if ((data.txnId ?? '').isNotEmpty) _receiptRow('Txn ID'.tr, data.txnId!, isDark),
              if ((data.description ?? '').isNotEmpty) _receiptRow('Description'.tr, data.description!, isDark),
              if ((data.paymentMethod ?? '').isNotEmpty) _receiptRow('Payment Method'.tr, data.paymentMethod!, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value, bool isDark, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                fontSize: 13,
                color: isDark ? AppThemeData.grey400Dark : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: isBold ? AppThemeData.bold : AppThemeData.medium,
                fontSize: 13.5,
                color: isDark ? AppThemeData.grey50Dark : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.data,
    required this.isDark,
    required this.onTap,
  });

  final TransactionData data;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = TransactionHistoryDisplay.categoryTitle(data);
    final counterparty = TransactionHistoryDisplay.counterpartyName(data);
    final displayDate = TransactionHistoryDisplay.displayDate(data);
    final status = TransactionHistoryDisplay.statusLabel(data);
    final iconType = TransactionHistoryDisplay.iconType(data);
    final iconColor = TransactionHistoryDisplay.iconColorFor(iconType);
    final iconBackground = TransactionHistoryDisplay.iconBackgroundFor(iconType);
    final amount = Constant().amountShow(amount: data.amount.toString());

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppThemeData.grey300Dark : const Color(0xFFF1F5F9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Pastel Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withOpacity(0.18) : iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      TransactionHistoryDisplay.iconFor(iconType),
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center: Details Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 14,
                          letterSpacing: -0.1,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        counterparty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 11.5,
                          color: isDark ? AppThemeData.grey400Dark : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayDate,
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          fontSize: 10.5,
                          color: isDark ? AppThemeData.grey500Dark : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right: Amount and Status Pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? TransactionHistoryDisplay.statusTextColor(status).withOpacity(0.16)
                            : TransactionHistoryDisplay.statusBackground(status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 10.5,
                          color: TransactionHistoryDisplay.statusTextColor(status),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 10),

                // Outlined Invoice/Receipt Button
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppThemeData.grey300Dark : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 15,
                      color: isDark ? AppThemeData.grey400Dark : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
