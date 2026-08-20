import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:finway/constant/constant.dart';

import 'package:finway/controller/service_history_controller.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/themes/button_them.dart';
import 'all_services_screen.dart';
import 'service_booking_resume.dart';
import 'service_style.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final bool showScaffold;
  final int initialTab;

  const ServiceHistoryScreen({
    super.key,
    this.showScaffold = true,
    this.initialTab = 0,
  });

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> with SingleTickerProviderStateMixin {
  late final ServiceHistoryController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ServiceHistoryController(), tag: 'service_history_${widget.showScaffold}');
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildBody(bool isDarkMode) {
    if (!Preferences.getBoolean(Preferences.isLogin)) {
      return _emptyState(
        isDarkMode,
        icon: Icons.login_rounded,
        title: 'Login required'.tr,
        subtitle: 'Please login to view your service bookings'.tr,
        actionLabel: 'Login'.tr,
        onAction: () => Get.to(() => const PhoneEntryScreen()),
      );
    }

    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.errorMessage.value.isNotEmpty && _controller.items.isEmpty) {
        return _emptyState(
          isDarkMode,
          icon: Icons.error_outline_rounded,
          title: 'Could not load bookings'.tr,
          subtitle: _controller.errorMessage.value,
          actionLabel: 'Retry'.tr,
          onAction: _controller.fetchHistory,
        );
      }

      if (_controller.items.isEmpty) {
        return RefreshIndicator(
          onRefresh: _controller.fetchHistory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              _emptyState(
                isDarkMode,
                icon: Icons.home_repair_service_outlined,
                title: 'No service bookings yet'.tr,
                subtitle: 'Book a home service to see it here'.tr,
                actionLabel: 'Book Service'.tr,
                onAction: () => Get.to(() => const AllServicesScreen()),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppThemeData.primary200,
              unselectedLabelColor: AppThemeData.grey500,
              indicatorColor: AppThemeData.primary200,
              labelStyle: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13),
              tabs: [
                Tab(text: 'Pending (${_controller.pending.length})'.tr),
                Tab(text: 'Ongoing (${_controller.ongoing.length})'.tr),
                Tab(text: 'History (${_controller.history.length})'.tr),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _controller.fetchHistory,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _bookingList(_controller.pending, isDarkMode, emptyText: 'No pending service bookings'.tr),
                  _bookingList(_controller.ongoing, isDarkMode, emptyText: 'No ongoing services'.tr),
                  _bookingList(_controller.history, isDarkMode, emptyText: 'No completed or cancelled bookings'.tr),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _bookingList(List<ServiceRequestData> list, bool isDarkMode, {required String emptyText}) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          _emptyState(
            isDarkMode,
            icon: Icons.home_repair_service_outlined,
            title: emptyText,
            subtitle: 'Book a home service to see it here'.tr,
            actionLabel: 'Book Service'.tr,
            onAction: () => Get.to(() => const AllServicesScreen()),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _bookingCard(list[index], isDarkMode),
    );
  }

  Widget _bookingCard(ServiceRequestData item, bool isDarkMode) {
    final style = categoryStyleFor(item.serviceName);
    final statusColor = item.isCancelled
        ? Colors.redAccent
        : item.isPending
            ? Colors.orange
            : item.isOngoing
                ? AppThemeData.primary200
                : AppThemeData.success300;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(style.icon, color: style.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cleanServiceName(item.serviceName).tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppThemeData.bold,
                    fontSize: 14,
                    color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.statusLabel.tr,
                  style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 11, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow(Icons.calendar_today_outlined, item.scheduleLabel, isDarkMode),
          if (item.payableAmount > 0)
            _infoRow(Icons.payments_outlined, '${Constant.currency ?? ''}${item.payableAmount.toStringAsFixed(0)}', isDarkMode),
          if ((item.serviceAddress ?? item.addressType ?? '').isNotEmpty)
            _infoRow(Icons.location_on_outlined, item.serviceAddress ?? item.addressType!, isDarkMode),
          if ((item.description ?? '').trim().isNotEmpty)
            _infoRow(Icons.notes_outlined, item.description!.trim(), isDarkMode, maxLines: 3),
          if (item.canTrackLive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ButtonThem.buildButton(
                context,
                title: item.trackActionLabel.tr,
                btnColor: style.color,
                btnHeight: 42,
                txtSize: 13,
                radius: 10,
                onPress: () => resumeServiceBookingFlow(item),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDarkMode, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppThemeData.grey500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
    bool isDarkMode, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppThemeData.grey400),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: AppThemeData.grey500, fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final body = _buildBody(isDarkMode);

    if (!widget.showScaffold) return body;

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: CustomAppbar(
        bgColor: AppThemeData.primary200,
        title: 'Service Bookings'.tr,
      ),
      body: body,
    );
  }
}
