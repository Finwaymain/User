// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/subscription_controller.dart';
import 'package:finway/model/subscription_plan_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/utils/mpin_dialog.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final bool isbackButton;
  final bool? isSplashScreen;

  const SubscriptionPlanScreen({
    super.key,
    required this.isbackButton,
    this.isSplashScreen,
  });

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  late final SubscriptionController controller;
  final Razorpay razorPayController = Razorpay();

  // View Navigation Modes
  // 'dashboard': My Membership Dashboard
  // 'plans': Choose Subscription Plan Screen
  // 'benefits': Plan Benefits Screen
  // 'activated': Plan Activated Confirmation Screen
  String viewMode = 'dashboard';

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SubscriptionController>()) {
      controller = Get.find<SubscriptionController>();
    } else {
      controller = Get.put(SubscriptionController());
    }
    viewMode = 'dashboard';
    razorPayController.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorPayController.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    razorPayController.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshAll();
    });
  }

  @override
  void dispose() {
    razorPayController.clear();
    super.dispose();
  }

  String _calculateDaysRemaining(User? userData, SubscriptionPlanData? activePlan) {
    if (userData?.consumerPlanExpiryDate != null && userData!.consumerPlanExpiryDate!.isNotEmpty) {
      try {
        final expiry = DateTime.parse(userData.consumerPlanExpiryDate!);
        final diff = expiry.difference(DateTime.now()).inDays;
        if (diff > 0) return "$diff days";
        if (diff == 0) return "Expires Today";
        return "Expired";
      } catch (_) {}
    }
    if (activePlan?.expiryDay != null) {
      if (activePlan!.expiryDay == "-1") return "Lifetime";
      return "${activePlan.expiryDay} days";
    }
    return "N/A";
  }

  String _formatExpiryDate(User? userData, SubscriptionPlanData? activePlan) {
    if (userData?.consumerPlanExpiryDate != null && userData!.consumerPlanExpiryDate!.isNotEmpty) {
      try {
        final expiry = DateTime.parse(userData.consumerPlanExpiryDate!);
        return DateFormat('dd MMM yyyy').format(expiry);
      } catch (_) {
        return userData.consumerPlanExpiryDate!;
      }
    }
    if (activePlan?.expiryDay == "-1") return "Lifetime Unlimited";
    return "Active Plan";
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<SubscriptionController>(
      builder: (ctrl) {
        return WillPopScope(
          onWillPop: () async {
            if (viewMode != 'dashboard') {
              setState(() => viewMode = 'dashboard');
              return false;
            }
            return widget.isbackButton;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _getAppBarTitle(),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: AppThemeData.bold,
                  fontSize: 18,
                ),
              ),
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () {
                  if (viewMode != 'dashboard') {
                    setState(() => viewMode = 'dashboard');
                  } else if (widget.isbackButton) {
                    Get.back();
                  }
                },
              ),
            ),
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentView(isDark, ctrl),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (viewMode) {
      case 'dashboard':
        return 'My Membership';
      case 'plans':
        return 'Choose Subscription Plan';
      case 'benefits':
        return 'Plan Benefits & Advantages';
      case 'activated':
        return 'Plan Activated';
      default:
        return 'My Membership';
    }
  }

  Widget _buildCurrentView(bool isDark, SubscriptionController controller) {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppThemeData.primary200,
            ),
            const SizedBox(height: 16),
            Text(
              "Loading Membership...".tr,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontFamily: AppThemeData.medium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    switch (viewMode) {
      case 'dashboard':
        return _buildDashboardScreen(isDark, controller);
      case 'plans':
        return _buildPlansListScreen(isDark, controller);
      case 'benefits':
        return _buildBenefitsScreen(isDark, controller);
      case 'activated':
        return _buildActivatedSuccessScreen(isDark, controller);
      default:
        return _buildDashboardScreen(isDark, controller);
    }
  }

  // ===========================================================================
  // 1. DEFAULT SCREEN: MY MEMBERSHIP DASHBOARD
  // ===========================================================================
  Widget _buildDashboardScreen(bool isDark, SubscriptionController controller) {
    final userData = controller.userModel.value.data ?? Constant.getUserData().data;

    final String userName = (userData?.prenom != null || userData?.nom != null)
        ? "${userData?.prenom ?? ''} ${userData?.nom ?? ''}".trim()
        : "User Profile";

    final SubscriptionPlanData activePlan = controller.selectedSubscriptionPlan.value;
    final String activePlanName = activePlan.name ?? userData?.consumerPlan?.name ?? "Standard Plan";
    final String activePlanPrice = activePlan.price != null
        ? Constant().amountShow(amount: activePlan.price!)
        : (userData?.consumerPlan?.price != null ? Constant().amountShow(amount: userData!.consumerPlan!.price!) : "Free");

    final String formattedExpiry = _formatExpiryDate(userData, activePlan);
    final String remainingDays = _calculateDaysRemaining(userData, activePlan);

    final List<String> activePlanPoints = (activePlan.planPoints != null && activePlan.planPoints!.isNotEmpty)
        ? activePlan.planPoints!
        : (activePlan.description != null && activePlan.description!.isNotEmpty
            ? [activePlan.description!]
            : ["Standard booking access", "Basic support", "Regular ride rates"]);

    final bool hasActiveSubscription = userData?.consumerPlanId != null && userData!.consumerPlanId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, size: 32, color: AppThemeData.primary200),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasActiveSubscription ? AppThemeData.primary200 : const Color(0xFF64748B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hasActiveSubscription ? 'Premium' : 'Standard',
                              style: const TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activePlanName,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Plan Validity Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan Validity', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(formattedExpiry, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Days Remaining', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(remainingDays, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subscription Details
          Text('Subscription Details', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSubDetailRow('Plan Name', activePlanName, isDark),
                const Divider(height: 16),
                _buildSubDetailRow('Subscription Price', activePlanPrice, isDark),
               
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Active Plan Benefits List
          Text('Plan Benefits ($activePlanName)', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activePlanPoints.length,
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: AppThemeData.primary200, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activePlanPoints[idx],
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Button to Change or Upgrade Plan
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Change / Upgrade Subscription Plan',
                    style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. CHOOSE SUBSCRIPTION PLAN SCREEN
  // ===========================================================================
  Widget _buildPlansListScreen(bool isDark, SubscriptionController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Top Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Premium Benefits',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeData.primary200),
                      ),
                      Text(
                        'FIINWAY Premium Plans',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppThemeData.primary200),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More Savings. More Comfort. More Value.',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.card_membership_rounded, size: 40, color: AppThemeData.primary200),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 18,
                fontFamily: AppThemeData.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Render Dynamic Subscription Plans
          controller.isLoading.value
              ? Center(child: Constant.loader(context))
              : controller.subscriptionPlanList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.loadError.value.isNotEmpty
                                  ? controller.loadError.value
                                  : "No subscription plans available right now.".tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: controller.refreshAll,
                              child: Text('Retry'.tr),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: controller.subscriptionPlanList.length,
                      itemBuilder: (context, idx) {
                        final plan = controller.subscriptionPlanList[idx];
                        final isSelected = controller.selectedSubscriptionPlan.value.id == plan.id;

                        return GestureDetector(
                          onTap: () {
                            controller.selectedSubscriptionPlan.value = plan;
                            controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppThemeData.primary200 : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isSelected) BoxShadow(color: AppThemeData.primary200.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Dynamic Plan Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: (plan.image != null && plan.image!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          imageUrl: plan.image!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: AppThemeData.primary200.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(Icons.card_membership_rounded, color: AppThemeData.primary200, size: 28),
                                          ),
                                        )
                                      : Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: AppThemeData.primary200.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.card_membership_rounded, color: AppThemeData.primary200, size: 28),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plan.name ?? 'Premium Plan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: AppThemeData.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${Constant().amountShow(amount: plan.price ?? '0.0')} / ${plan.expiryDay == "-1" ? "Lifetime" : "${plan.expiryDay} Days"}',
                                        style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    controller.selectedSubscriptionPlan.value = plan;
                                    controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                                    setState(() {
                                      viewMode = 'benefits';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: AppThemeData.primary200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('View Benefits', style: TextStyle(fontSize: 11, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          const SizedBox(height: 20),

          if (controller.subscriptionPlanList.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => setState(() => viewMode = 'benefits'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Select Plan & View Benefits', style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. PLAN BENEFITS & ADVANTAGES PAGE
  // ===========================================================================
  Widget _buildBenefitsScreen(bool isDark, SubscriptionController controller) {
    final plan = controller.selectedSubscriptionPlan.value;

    final String planTitle = plan.name ?? 'Subscription Plan';
    final String planPrice = Constant().amountShow(amount: plan.price ?? '0.0');
    final String expiryText = plan.expiryDay == "-1" ? "Lifetime" : "${plan.expiryDay ?? '365'} Days";

    final List<String> benefitsList = (plan.planPoints != null && plan.planPoints!.isNotEmpty)
        ? plan.planPoints!
        : (plan.description != null && plan.description!.isNotEmpty
            ? [plan.description!]
            : ["Premium ride access", "Priority booking", "24/7 Customer support"]);
    final double cashbackAmount = double.tryParse(plan.cashbackOnPurchase ?? '0') ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Plan Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (plan.image != null && plan.image!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: plan.image!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 28),
                          ),
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppThemeData.primary200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 28),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planTitle,
                        style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$planPrice / $expiryText",
                        style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: AppThemeData.primary200),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (cashbackAmount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14532D) : AppThemeData.success50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppThemeData.success300.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppThemeData.success300.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_giftcard_rounded, color: AppThemeData.success300, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Purchase Cashback Reward',
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: AppThemeData.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get ${Constant().amountShow(amount: cashbackAmount.toString())} credited to your wallet instantly after you purchase this plan.',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppThemeData.regular,
                            color: isDark ? Colors.white70 : AppThemeData.grey500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text('Key Benefits & Advantages', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: benefitsList.length,
            itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppThemeData.primary200.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: AppThemeData.primary200, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefitsList[idx],
                        style: TextStyle(fontSize: 13, fontFamily: AppThemeData.medium, color: isDark ? Colors.white : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Proceed to Payment Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                controller.totalAmount.value = double.parse(plan.price ?? '0.0');
                paymentDialog(context, controller, isDark);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Proceed to Payment', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('Secure Payment Gateway', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. PLAN ACTIVATED SUCCESS CONFIRMATION SCREEN
  // ===========================================================================
  Widget _buildActivatedSuccessScreen(bool isDark, SubscriptionController controller) {
    final plan = controller.selectedSubscriptionPlan.value;
    final planName = plan.name ?? "Subscription Plan";
    final planPrice = Constant().amountShow(amount: plan.price ?? '0.0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppThemeData.primary200,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),

          Text(
            'Plan Activated Successfully!',
            style: TextStyle(fontSize: 20, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Premium Subscription Plan is now active',
            style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Activated Plan Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (plan.image != null && plan.image!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: plan.image!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 26),
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppThemeData.primary200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.card_membership_rounded, color: Colors.white, size: 26),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              planName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppThemeData.primary200, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Active', style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      Text(planPrice, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Go to Dashboard Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 13, fontFamily: AppThemeData.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
      ],
    );
  }

  // Payment Options Bottom Sheet
  Future<dynamic> paymentDialog(BuildContext context, SubscriptionController paymentController, bool isDarkMode) {
    return showModalBottomSheet(
      elevation: 5,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
      context: context,
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      builder: (context) {
        return Obx(() {
          return SizedBox(
            height: Get.height / 1.15,
            child: SingleChildScrollView(
              child: InkWell(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 8,
                        width: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: isDarkMode ? AppThemeData.grey300Dark : AppThemeData.grey300,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Transform(
                            alignment: Alignment.center,
                            transform: Directionality.of(context).name == 'rtl' ? Matrix4.rotationY(3.14159) : Matrix4.identity(),
                            child: SvgPicture.asset(
                              'assets/icons/ic_left.svg',
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                isDarkMode ? AppThemeData.grey50 : AppThemeData.grey900,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          "Select Payment Method".tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: AppThemeData.bold,
                            color: isDarkMode ? AppThemeData.grey50 : AppThemeData.grey900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          buildPaymentOption(
                            title: "Razorpay",
                            value: "razorpay",
                            controller: paymentController,
                            isDarkMode: isDarkMode,
                          ),
                          buildPaymentOption(
                            title: "Wallet",
                            value: "wallet",
                            controller: paymentController,
                            isDarkMode: isDarkMode,
                          ),
                          buildPaymentOption(
                            title: "Stripe",
                            value: "stripe",
                            controller: paymentController,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: paymentController.selectedRadioTile.value.isEmpty
                                  ? null
                                  : () async {
                                      final method = paymentController.selectedRadioTile.value;
                                      Get.back();
                                      if (method == 'razorpay') {
                                        razorpayPayment(paymentController);
                                        return;
                                      }
                                      if (method == 'wallet') {
                                        final verified = await showMpinVerificationBottomSheet(
                                          context,
                                          amount: paymentController.totalAmount.value,
                                          title: 'Enter MPIN to Pay'.tr,
                                          userCat: 'customer',
                                        );
                                        if (verified != true) {
                                          return;
                                        }
                                      }
                                      final success = await paymentController.completeSubscription();
                                      if (!mounted) return;
                                      if (success) {
                                        setState(() => viewMode = 'activated');
                                      }
                                    },
                              child: Text(
                                "Pay ${Constant().amountShow(amount: paymentController.totalAmount.value.toString())}".tr,
                                style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget buildPaymentOption({
    required String title,
    required String value,
    required SubscriptionController controller,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: controller.selectedRadioTile.value == value ? AppThemeData.primary200! : const Color(0xFFE2E8F0),
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontFamily: AppThemeData.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        value: value,
        groupValue: controller.selectedRadioTile.value,
        activeColor: AppThemeData.primary200,
        onChanged: (val) {
          controller.selectedRadioTile.value = val!;
        },
      ),
    );
  }

  void razorpayPayment(SubscriptionController controller) {
    var options = {
      'key': controller.paymentSettingModel.value.razorpay?.key ?? '',
      'amount': (controller.totalAmount.value * 100).toInt(),
      'name': 'FIINWAY Subscription',
      'description': controller.selectedSubscriptionPlan.value.name ?? 'Premium Plan',
      'prefill': {
        'contact': controller.userModel.value.data?.phone ?? '',
        'email': controller.userModel.value.data?.email ?? '',
      }
    };
    try {
      razorPayController.open(options);
    } catch (e) {
      log("Razorpay error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ShowToastDialog.showToast("Payment Successful!");
    final success = await controller.completeSubscription();
    if (!mounted) return;
    if (success) {
      setState(() => viewMode = 'activated');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ShowToastDialog.showToast("Payment Failed: ${response.message}");
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    ShowToastDialog.showToast("External Wallet Selected: ${response.walletName}");
  }
}
