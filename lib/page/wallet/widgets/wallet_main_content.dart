import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/page/wallet/widgets/wallet_overview_tab.dart';
import 'package:finway/page/wallet/widgets/wallet_transactions_tab.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/dark_theme_provider.dart';

class WalletMainContent extends StatefulWidget {
  const WalletMainContent({
    super.key,
    required this.walletController,
    required this.onTopUp,
    required this.onRefresh,
  });

  final WalletController walletController;
  final VoidCallback onTopUp;
  final Future<void> Function() onRefresh;

  @override
  State<WalletMainContent> createState() => _WalletMainContentState();
}

class _WalletMainContentState extends State<WalletMainContent> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRefresh());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: isDark ? AppThemeData.grey100Dark : AppThemeData.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppThemeData.primary200,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? AppThemeData.grey400Dark : AppThemeData.grey500,
            labelStyle: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontFamily: AppThemeData.medium, fontSize: 14),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'History'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: AppThemeData.primary200,
                  onRefresh: widget.onRefresh,
                  child: WalletOverviewTab(
                    walletController: widget.walletController,
                    onTopUp: widget.onTopUp,
                  ),
                ),
                WalletTransactionsTab(
                  controller: widget.walletController,
                  onRefresh: widget.onRefresh,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
