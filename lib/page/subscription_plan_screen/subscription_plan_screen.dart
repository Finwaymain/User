// ignore_for_file: must_be_immutable, use_build_context_synchronously

import 'dart:developer';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/subscription_controller.dart';
import 'package:finway/model/subscription_plan_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/utils/email_otp_dialog.dart';
import 'package:finway/utils/mpin_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  // View Navigation Modes:
  // 'current_plan': Screen 1 (What You May Miss, 10 chargeable items, ₹850/mo savings callout)
  // 'plans': Screen 2 (5-tier cards grid: Basic, Standard, Executive, VIP, Premium)
  // 'benefits': Screen 3 (Dynamic Benefits list, comparison & payment options)
  // 'activated': Plan Activated Confirmation Screen
  // 'dashboard': Screen 4 (Active My Plan dashboard with countdown, monthly savings, active perks)
  String viewMode = 'current_plan';

  // 10 Canonical Chargeable Items on Free/Basic Plan
  static const List<Map<String, String>> chargeableItems = [
    {
      "title": "Platform Fees",
      "tag": "Paid",
      "desc": "Eligible rides, food, home services, parcel, travel and orders may include platform fees."
    },
    {
      "title": "Delivery & Shipping",
      "tag": "Paid",
      "desc": "Applicable food, parcel and marketplace orders may have delivery/shipping charges."
    },
    {
      "title": "Payment Handling Charges",
      "tag": "Paid",
      "desc": "Additional handling charges may apply based on UPI, Cash, Wallet, Card or other payment modes."
    },
    {
      "title": "Booking & Service Charges",
      "tag": "Paid",
      "desc": "Applicable booking, convenience or service charges may apply to rides and other services."
    },
    {
      "title": "Shopping Charges",
      "tag": "Paid",
      "desc": "Marketplace orders may include platform, convenience, delivery or applicable transaction charges."
    },
    {
      "title": "Limited Cashback",
      "tag": "Limited",
      "desc": "Cashback benefits available under premium/promotional plans may not be available on your current plan."
    },
    {
      "title": "Limited Referral Benefits",
      "tag": "Limited",
      "desc": "Enhanced referral benefits may not be available on your current plan."
    },
    {
      "title": "Premium Discounts & Offers",
      "tag": "Locked",
      "desc": "Premium discounts, cashback, free usage limits and special offers may not be available."
    },
    {
      "title": "Loan & Credit Benefits",
      "tag": "Locked",
      "desc": "Eligible premium/qualified users may receive additional benefits such as Interest-Free Loan and up to ₹15,000 Instant Virtual Credit, subject to applicable rules."
    },
    {
      "title": "Business Benefits",
      "tag": "Locked",
      "desc": "Priority listing, extra visibility, marketing tools, advanced analytics and dedicated support may not be available under your current plan."
    },
  ];


  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SubscriptionController>()) {
      controller = Get.find<SubscriptionController>();
    } else {
      controller = Get.put(SubscriptionController());
    }

    razorPayController.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    razorPayController.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    razorPayController.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshAll().then((_) {
        _determineInitialViewMode();
      });
    });
  }

  @override
  void dispose() {
    razorPayController.clear();
    super.dispose();
  }

  void _determineInitialViewMode() {
    final userData = controller.userModel.value.data ?? Constant.getUserData().data;
    final hasActivePlan = userData?.consumerPlanId != null && userData!.consumerPlanId!.isNotEmpty;
    if (mounted) {
      setState(() {
        viewMode = hasActivePlan ? 'dashboard' : 'current_plan';
      });
    }
  }

  String _calculateDaysRemaining(User? userData, SubscriptionPlanData? activePlan) {
    if (userData?.consumerPlanExpiryDate != null && userData!.consumerPlanExpiryDate!.isNotEmpty) {
      try {
        final expiry = DateTime.parse(userData.consumerPlanExpiryDate!);
        final diff = expiry.difference(DateTime.now()).inDays;
        if (diff > 0) return "$diff Days Remaining";
        if (diff == 0) return "Expires Today";
        return "Expired";
      } catch (_) {}
    }
    if (activePlan?.expiryDay != null) {
      if (activePlan!.expiryDay == "-1") return "Lifetime Unlimited";
      return "${activePlan.expiryDay} Days Remaining";
    }
    return "312 Days Remaining";
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
    return DateFormat('dd MMM yyyy').format(DateTime.now().add(const Duration(days: 30)));
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<SubscriptionController>(
      builder: (ctrl) {
        return WillPopScope(
          onWillPop: () async {
            if (viewMode == 'benefits') {
              setState(() => viewMode = 'plans');
              return false;
            } else if (viewMode == 'plans') {
              final userData = ctrl.userModel.value.data ?? Constant.getUserData().data;
              final hasActive = userData?.consumerPlanId != null && userData!.consumerPlanId!.isNotEmpty;
              setState(() => viewMode = hasActive ? 'dashboard' : 'current_plan');
              return false;
            } else if (viewMode == 'activated') {
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
                  if (viewMode == 'benefits') {
                    setState(() => viewMode = 'plans');
                  } else if (viewMode == 'plans') {
                    final userData = ctrl.userModel.value.data ?? Constant.getUserData().data;
                    final hasActive = userData?.consumerPlanId != null && userData!.consumerPlanId!.isNotEmpty;
                    setState(() => viewMode = hasActive ? 'dashboard' : 'current_plan');
                  } else if (viewMode == 'activated') {
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
      case 'current_plan':
        return 'Your Current Plan';
      case 'plans':
        return 'Choose Your Plan';
      case 'benefits':
        return 'Plan Benefits & Payment';
      case 'activated':
        return 'Plan Activated';
      case 'dashboard':
      default:
        return 'My Plan';
    }
  }

  Widget _buildCurrentView(bool isDark, SubscriptionController ctrl) {
    if (ctrl.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppThemeData.primary200),
            const SizedBox(height: 16),
            Text(
              "Loading Plans...".tr,
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
      case 'current_plan':
        return _buildCurrentPlanScreen(isDark, ctrl);
      case 'plans':
        return _buildPlansListScreen(isDark, ctrl);
      case 'benefits':
        return _buildBenefitsScreen(isDark, ctrl);
      case 'activated':
        return _buildActivatedSuccessScreen(isDark, ctrl);
      case 'dashboard':
      default:
        return _buildDashboardScreen(isDark, ctrl);
    }
  }

  // ===========================================================================
  // SCREEN 1: YOUR CURRENT PLAN – WHAT YOU MAY MISS (10 Chargeable Items & Savings Callout)
  // ===========================================================================
  Widget _buildCurrentPlanScreen(bool isDark, SubscriptionController ctrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Basic Plan Status Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Basic Free Plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: const Text('Active', style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Standard services with applicable platform & handling fees',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ₹850/Month Savings Callout Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF78350F), const Color(0xFF1E293B)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade400.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lightbulb_rounded, color: isDark ? Colors.amber.shade300 : Colors.amber.shade800, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save up to ₹850/month with Premium!',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reduce platform charges • Up to 2% cashback • Instant loan & credit benefits • Exclusive shopping discounts',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: isDark ? Colors.white70 : const Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 10 Chargeable Items Header
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Your Current Plan – What You May Miss',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'The following 10 items carry extra fees or are locked on your current plan:',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // 10 Chargeable Items List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chargeableItems.length,
            itemBuilder: (context, idx) {
              final item = chargeableItems[idx];
              final tag = item["tag"] ?? "Paid";
              final Color tagColor = tag == "Paid" ? Colors.red : (tag == "Limited" ? Colors.orange : Colors.purple);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item["title"] ?? "",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: AppThemeData.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tagColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '[$tag]',
                            style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: tagColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item["desc"] ?? "",
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Upgrade CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => viewMode = 'plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Upgrade to Unlock More Benefits',
                    style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 2: CHOOSE YOUR PLAN (5-Tier Cards: Basic ₹300, Standard ₹500, Executive ₹700, VIP ₹900, Premium ₹1,100)
  // ===========================================================================
  Widget _buildPlansListScreen(bool isDark, SubscriptionController ctrl) {
    final userData = ctrl.userModel.value.data ?? Constant.getUserData().data;
    final int currentTier = int.tryParse(userData?.consumerPlan?.tierLevel?.toString() ?? '1') ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [AppThemeData.primary200.withOpacity(0.12), Colors.white],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock Maximum Privileges',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppThemeData.primary200),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose Your Premium Plan',
                        style: TextStyle(
                          fontSize: 17,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a tier to view all applicable benefits and cashback rewards.',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.stars_rounded, size: 44, color: AppThemeData.primary200),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Available Membership Tiers',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Render Plan Cards
          if (ctrl.subscriptionPlanList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  ctrl.loadError.value.isNotEmpty ? ctrl.loadError.value : "No subscription plans available right now.".tr,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                ),
              ),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: ctrl.subscriptionPlanList.length,
              itemBuilder: (context, idx) {
                final plan = ctrl.subscriptionPlanList[idx];
                final planTier = plan.tierLevel ?? (idx + 2);
                final isDowngrade = planTier < currentTier;
                final isCurrent = plan.id == userData?.consumerPlanId;
                final isSelected = ctrl.selectedSubscriptionPlan.value.id == plan.id;
                final validity = plan.expiryDay ?? plan.bookingLimit ?? '30';
                final cashback = double.tryParse(plan.cashbackOnPurchase ?? '0') ?? 0;

                return GestureDetector(
                  onTap: () {
                    if (isDowngrade) {
                      ShowToastDialog.showToast("Cannot downgrade to a lower-tier plan (Strict No-Downgrade).");
                      return;
                    }
                    ctrl.selectedSubscriptionPlan.value = plan;
                    ctrl.totalAmount.value = double.parse(plan.price ?? '0.0');
                    setState(() => viewMode = 'benefits');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? Colors.green
                            : (isSelected ? AppThemeData.primary200 : const Color(0xFFE2E8F0)),
                        width: isSelected || isCurrent ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppThemeData.primary200.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Plan Tier Icon / Image
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.green.withOpacity(0.15) : AppThemeData.primary200.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: isCurrent ? Colors.green : AppThemeData.primary200,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      plan.name ?? 'Premium Plan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: AppThemeData.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (plan.badge != null && plan.badge!.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        plan.badge!,
                                        style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: AppThemeData.bold),
                                      ),
                                    ),
                                  ],
                                  if (isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('Active', style: TextStyle(fontSize: 9, color: Colors.white, fontFamily: AppThemeData.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${Constant().amountShow(amount: plan.price ?? '0.0')} / $validity Days',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: AppThemeData.bold,
                                  color: AppThemeData.primary200,
                                ),
                              ),
                              if (cashback > 0)
                                Text(
                                  '+ ₹${cashback.toInt()} Wallet Cashback',
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontFamily: AppThemeData.bold),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: isDowngrade
                              ? null
                              : () {
                                  ctrl.selectedSubscriptionPlan.value = plan;
                                  ctrl.totalAmount.value = double.parse(plan.price ?? '0.0');
                                  setState(() => viewMode = 'benefits');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrent ? Colors.green : AppThemeData.primary200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: Text(
                            isDowngrade ? 'Locked' : (isCurrent ? 'Active' : 'Select'),
                            style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3: PLAN BENEFITS & PAYMENT (Dynamic Benefits List & Email OTP + Payment)
  // ===========================================================================
  Widget _buildBenefitsScreen(bool isDark, SubscriptionController ctrl) {
    final plan = ctrl.selectedSubscriptionPlan.value;
    final userData = ctrl.userModel.value.data ?? Constant.getUserData().data;

    final String planTitle = plan.name ?? 'FIINWAY Premium Plan';
    final String planPrice = Constant().amountShow(amount: plan.price ?? '0.0');
    final String validity = "${plan.expiryDay ?? plan.bookingLimit ?? '30'} Days";
    final double cashbackAmount = double.tryParse(plan.cashbackOnPurchase ?? '0') ?? 0;

    // Use only admin-configured benefits from API
    final List<String> benefitsList = (plan.benefitsList != null && plan.benefitsList!.isNotEmpty)
        ? plan.benefitsList!
        : (plan.planPoints ?? []);


    final int currentTier = int.tryParse(userData?.consumerPlan?.tierLevel?.toString() ?? '1') ?? 1;
    final int selectedTier = plan.tierLevel ?? 2;
    final bool isDowngrade = selectedTier < currentTier;
    final bool isCurrentPlan = plan.id == userData?.consumerPlanId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Plan Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : AppThemeData.primary200.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeData.primary200.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium_rounded, color: AppThemeData.primary200, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              planTitle,
                              style: TextStyle(
                                fontSize: 17,
                                fontFamily: AppThemeData.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (plan.badge != null && plan.badge!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plan.badge!,
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontFamily: AppThemeData.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$planPrice / $validity",
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.bold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Cashback banner
          if (cashbackAmount > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Colors.green, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Get ₹${cashbackAmount.toInt()} Cashback credited directly to your FIINWAY wallet on activation.',
                      style: const TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Strict No Downgrade Banner if applicable
          if (isDowngrade) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Strict No Downgrade: Downgrading to a lower plan tier is prohibited. You can only upgrade.',
                      style: TextStyle(fontSize: 12, fontFamily: AppThemeData.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Benefits Header
          Text(
            benefitsList.isNotEmpty
                ? 'Premium Plan Benefits (${benefitsList.length} Included)'
                : 'Premium Plan Benefits',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Benefits List (dynamic from admin panel)
          if (benefitsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppThemeData.primary200, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All standard member benefits are included in this plan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: benefitsList.length,
              itemBuilder: (context, idx) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 15),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        benefitsList[idx],
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

          // Proceed to Payment Button with Email OTP & No Downgrade Checks
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (isDowngrade || isCurrentPlan)
                  ? null
                  : () async {
                      ctrl.totalAmount.value = double.parse(plan.price ?? '0.0');

                      // 1. Enforce No-Downgrade on Client
                      if (isDowngrade) {
                        ShowToastDialog.showToast("Cannot downgrade to a lower tier plan.");
                        return;
                      }

                      // 2. Email OTP Verification Requirement
                      final userEmail = userData?.email ?? '';
                      final isEmailVerified = userData?.emailVerifiedAt != null && userData!.emailVerifiedAt!.isNotEmpty;

                      if (!isEmailVerified) {
                        final verified = await showPlanEmailOtpDialog(
                          context,
                          currentEmail: userEmail,
                          userId: userData?.id ?? '',
                          userCat: 'customer',
                          isDarkMode: isDark,
                        );
                        if (!verified) return;
                      }

                      // 3. Open Payment Modal
                      if (mounted) {
                        paymentDialog(context, ctrl, isDark);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan ? Colors.green : AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCurrentPlan
                        ? 'Plan Currently Active'
                        : (isDowngrade ? 'Downgrade Disabled' : 'Proceed to Payment'),
                    style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white),
                  ),
                  if (!isCurrentPlan && !isDowngrade) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
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
                Text(
                  'Automated Tax Invoice & Active Perks Emailed on Activation',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 3B: PLAN ACTIVATED CONFIRMATION
  // ===========================================================================
  Widget _buildActivatedSuccessScreen(bool isDark, SubscriptionController ctrl) {
    final plan = ctrl.selectedSubscriptionPlan.value;
    final planName = plan.name ?? "Premium Plan";
    final planPrice = Constant().amountShow(amount: plan.price ?? '0.0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 20),

          Text(
            'Plan Activated Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontFamily: AppThemeData.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Congratulations! Your $planName is now active, and all eligible premium benefits are unlocked.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Activated Plan', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Text(planName, style: const TextStyle(fontSize: 14, fontFamily: AppThemeData.bold)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Amount Paid', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Text(planPrice, style: TextStyle(fontSize: 14, fontFamily: AppThemeData.bold, color: AppThemeData.primary200)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Active', style: TextStyle(fontSize: 10, color: Colors.white, fontFamily: AppThemeData.bold)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Confirmation Email', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    const Text('Tax Invoice Sent ✓', style: TextStyle(fontSize: 12, color: Colors.green, fontFamily: AppThemeData.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => viewMode = 'dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeData.primary200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Go to My Plan Dashboard', style: TextStyle(fontSize: 16, fontFamily: AppThemeData.bold, color: Colors.white)),
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
  // SCREEN 4: MY PLAN DASHBOARD (Active Membership, Days Remaining, Savings, Active Perks)
  // ===========================================================================
  Widget _buildDashboardScreen(bool isDark, SubscriptionController ctrl) {
    final userData = ctrl.userModel.value.data ?? Constant.getUserData().data;

    final String userName = (userData?.prenom != null || userData?.nom != null)
        ? "${userData?.prenom ?? ''} ${userData?.nom ?? ''}".trim()
        : "FIINWAY Member";

    final SubscriptionPlanData activePlan = ctrl.selectedSubscriptionPlan.value;
    final String activePlanName = activePlan.name ?? userData?.consumerPlan?.name ?? "Premium Plan";
    final String remainingDays = _calculateDaysRemaining(userData, activePlan);

    // Active benefits list from admin panel (no hardcoded fallback)
    final List<String> activePerks = (activePlan.benefitsList != null && activePlan.benefitsList!.isNotEmpty)
        ? activePlan.benefitsList!
        : (activePlan.planPoints ?? []);


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Profile Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppThemeData.primary200.withOpacity(0.12),
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
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Active', style: TextStyle(fontSize: 10, fontFamily: AppThemeData.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activePlanName,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.bold,
                          color: AppThemeData.primary200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2 Stats: Plan Validity & Monthly Savings
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppThemeData.primary200.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppThemeData.primary200),
                          const SizedBox(width: 6),
                          Text('Plan Validity', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        remainingDays,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatExpiryDate(userData, activePlan),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.savings_rounded, size: 14, color: Colors.green),
                          SizedBox(width: 6),
                          Text('Saved This Month', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "₹680 Saved",
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Active Perks List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Active Perks (${activePerks.length} Unlocked)',
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Scroll to view all', style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active perks scrollable list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activePerks.length,
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
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.green, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activePerks[idx],
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Active', style: TextStyle(fontSize: 10, color: Colors.green, fontFamily: AppThemeData.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Upgrade to Higher Plan Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.upgrade_rounded, color: AppThemeData.primary200, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade Your Membership',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: AppThemeData.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Strict No Downgrade: You can only upgrade to a higher tier plan. Days remaining will be carried over.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => setState(() => viewMode = 'plans'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeData.primary200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Explore Higher Plans',
                      style: TextStyle(fontSize: 15, fontFamily: AppThemeData.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ===========================================================================
  // PAYMENT MODAL SHEET
  // ===========================================================================
  Future<dynamic> paymentDialog(BuildContext context, SubscriptionController ctrl, bool isDarkMode) {
    return showModalBottomSheet(
      elevation: 5,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      context: context,
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : AppThemeData.surface50,
      builder: (context) {
        return GetX<SubscriptionController>(
          builder: (ctrl) {
            return Container(
              padding: const EdgeInsets.only(bottom: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        height: 5,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          buildPaymentOption(
                            title: "UPI / Online Payment (Razorpay)",
                            value: "razorpay",
                            ctrl: ctrl,
                            isDarkMode: isDarkMode,
                          ),
                          buildPaymentOption(
                            title: "FIINWAY Wallet (Instant Debit)",
                            value: "wallet",
                            ctrl: ctrl,
                            isDarkMode: isDarkMode,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primary200,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final method = ctrl.selectedRadioTile.value;
                                if (method.isEmpty) {
                                  ShowToastDialog.showToast("Please select a payment method");
                                  return;
                                }
                                Get.back();
                                if (method == 'razorpay') {
                                  razorpayPayment(ctrl);
                                  return;
                                }
                                String? verifiedMpin;
                                if (method == 'wallet') {
                                  verifiedMpin = await showMpinVerificationBottomSheet(
                                    context,
                                    amount: ctrl.totalAmount.value,
                                    title: 'Enter MPIN to Pay'.tr,
                                    userCat: 'customer',
                                  );
                                  if (verifiedMpin == null || verifiedMpin.isEmpty) {
                                    return;
                                  }
                                }
                                final success = await ctrl.completeSubscription(mpin: verifiedMpin);
                                if (!mounted) return;
                                if (success) {
                                  setState(() => viewMode = 'activated');
                                }
                              },
                              child: Text(
                                "Pay ${Constant().amountShow(amount: ctrl.totalAmount.value.toString())}".tr,
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
            );
          },
        );
      },
    );
  }

  Widget buildPaymentOption({
    required String title,
    required String value,
    required SubscriptionController ctrl,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ctrl.selectedRadioTile.value == value ? AppThemeData.primary200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppThemeData.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        value: value,
        groupValue: ctrl.selectedRadioTile.value,
        activeColor: AppThemeData.primary200,
        onChanged: (val) {
          ctrl.selectedRadioTile.value = val!;
        },
      ),
    );
  }

  void razorpayPayment(SubscriptionController ctrl) {
    var options = {
      'key': ctrl.paymentSettingModel.value.razorpay?.key ?? '',
      'amount': (ctrl.totalAmount.value * 100).toInt(),
      'name': 'FIINWAY Premium Plan',
      'description': ctrl.selectedSubscriptionPlan.value.name ?? 'Consumer Membership',
      'prefill': {
        'contact': ctrl.userModel.value.data?.phone ?? '',
        'email': ctrl.userModel.value.data?.email ?? '',
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
    if (success && mounted) {
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
