import 'dart:math';

import 'package:finway/constant/constant.dart';
import 'package:finway/page/features/SmartValue/AccountDetails/controller/account_details_controller.dart';
import 'package:finway/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:finway/page/wallet/utils/wallet_formatters.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WalletFlipCard extends StatelessWidget {
  const WalletFlipCard({super.key, required this.controller});

  final AccountDetailsController controller;

  String _planLabel() {
    final plan = Constant.getUserData().data?.consumerPlan?.name;
    if (plan != null && plan.isNotEmpty) return plan.toUpperCase();
    final type = controller.cardType;
    if (type.isNotEmpty && type != 'N/A') return type.toUpperCase();
    return 'PLATINUM';
  }

  String _lastFourDigits() {
    final acNo = controller.accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (acNo.length >= 4) {
      return acNo.substring(acNo.length - 4);
    }
    final user = Constant.getUserData().data;
    if (user?.id != null && user!.id.toString().length >= 4) {
      final idStr = user.id.toString();
      return idStr.substring(idStr.length - 4);
    }
    return '1068';
  }

  String _fullName() {
    if (controller.holderName.isNotEmpty && controller.holderName != 'N/A') {
      return controller.holderName;
    }
    final user = Constant.getUserData().data;
    final name = '${user?.prenom ?? ''} ${user?.nom ?? ''}'.trim();
    return name.isNotEmpty ? name : 'SMART VALUE MEMBER';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const cardHeight = 215.0;

    return Obx(() {
      final hasProfile = controller.accountDetailsModel.value?.data != null ||
          Constant.getUserData().data != null;

      if (controller.isLoading.value && !hasProfile) {
        return _buildShimmerCard(isDark, cardHeight);
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.flipCard,
        child: SizedBox(
          height: cardHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              controller.flipAnimation,
              controller.shimmerAnimation,
            ]),
            builder: (context, child) {
              final isFrontVisible = controller.flipAnimation.value <= pi / 2;

              return Stack(
                children: [
                  // Soft glow shadow
                  Container(
                    width: double.infinity,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A859).withOpacity(0.32),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.20),
                          blurRadius: 18,
                          offset: const Offset(4, 6),
                        ),
                      ],
                    ),
                  ),
                  // 3D Flip Card Container
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(controller.flipAnimation.value),
                    child: Container(
                      width: double.infinity,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: isFrontVisible
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF00A859), // Rich Emerald Green
                                  Color(0xFF058A48), // Forest Green
                                  Color(0xFF0D9488), // Deep Teal
                                  Color(0xFFD97706), // Amber
                                  Color(0xFFEA580C), // Vibrant Orange
                                ],
                                stops: [0.0, 0.35, 0.60, 0.85, 1.0],
                              )
                            : const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E293B),
                                  Color(0xFF0F172A),
                                ],
                              ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: isFrontVisible
                            ? _buildFrontCard(cardHeight)
                            : _buildBackCard(cardHeight),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildFrontCard(double cardHeight) {
    final fourDigits = _lastFourDigits();
    final balanceText = controller.totalAmount.isNotEmpty && controller.totalAmount != '0'
        ? Constant().amountShow(amount: controller.totalAmount)
        : Constant().amountShow(amount: '0');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Subtle shimmer highlight
        AnimatedBuilder(
          animation: controller.shimmerAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment(-1 + controller.shimmerAnimation.value * 1.5, -1),
                    end: Alignment(1 + controller.shimmerAnimation.value * 1.5, 1),
                  ),
                ),
              ),
            );
          },
        ),

        // Main Card Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. TOP HEADER ROW: Title + Platinum Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Value ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontFamily: AppThemeData.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Transfer &  earn monthly Upto 25000',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 10.5,
                            fontFamily: AppThemeData.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Golden Crown Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.40),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFCD34D).withOpacity(0.70),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: Color(0xFFFDE047),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _planLabel(),
                          style: const TextStyle(
                            color: Color(0xFFFFFBEB),
                            fontSize: 10,
                            fontFamily: AppThemeData.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. MIDDLE ROW: Gold Chip + Masked Number + FIINWAY Logo
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gold EMV Chip
                  _buildGoldChip(),
                  const SizedBox(width: 10),
                  Text(
                    '**** $fourDigits',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontFamily: AppThemeData.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // Brand Wordmark
                  _buildFiinwayLogo(),
                ],
              ),

              // 3. BALANCE & CASHBACK ROW
              Row(
                children: [
                  // Available Balance
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 9.5,
                              fontFamily: AppThemeData.regular,
                            ),
                          ),
                          Text(
                            balanceText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontFamily: AppThemeData.bold,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (controller.hasCashback) ...[
                    const Spacer(),
                    // Dynamic Cashback Pill (only rendered when cashback is set)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withOpacity(0.70),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.card_giftcard_rounded,
                              color: Color(0xFFA7F3D0),
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.cashbackText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: AppThemeData.bold,
                                ),
                              ),
                              Text(
                                'on Every Transaction',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 8,
                                  fontFamily: AppThemeData.regular,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // 4. BOTTOM ACTION BUTTONS: View Details + Upgrade Plan
              Row(
                children: [
                  // View Details Button (White pill)
                  Expanded(
                    child: GestureDetector(
                      onTap: controller.flipCard,
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Color(0xFF1E1B4B),
                            fontSize: 12,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Upgrade Plan Button (Green pill)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.to(() => const SubscriptionPlanScreen(isbackButton: true)),
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF047857),
                              Color(0xFF065F46),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Upgrade Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: AppThemeData.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldChip() {
    return Container(
      width: 34,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3B0),
            Color(0xFFFFD54F),
            Color(0xFFFFA000),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFB45309).withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          // Inner circuit pattern
          Center(
            child: Container(
              width: 18,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: const Color(0xFF92400E).withOpacity(0.45),
                  width: 0.6,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 0.6,
              height: 24,
              color: const Color(0xFF92400E).withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiinwayLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Green & Orange curved brand mark
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFFF97316)],
            ),
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'FIINWAY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontFamily: AppThemeData.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildBackCard(double cardHeight) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Black magnetic strip
            Container(
              width: double.infinity,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Signature / CVV bar
            Container(
              width: double.infinity,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'A/c: ${controller.accountNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    controller.cvv.isNotEmpty ? controller.cvv : '***',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            // Cardholder and Expiry
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CARDHOLDER',
                        style: TextStyle(color: Colors.white60, fontSize: 8),
                      ),
                      Text(
                        _fullName().toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: AppThemeData.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VALID THRU',
                      style: TextStyle(color: Colors.white60, fontSize: 8),
                    ),
                    Text(
                      controller.expDate.isNotEmpty ? controller.expDate : '12/28',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontFamily: AppThemeData.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Flip back button
            GestureDetector(
              onTap: controller.flipCard,
              child: Container(
                height: 32,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white30),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Flip to Front',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: AppThemeData.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark, double cardHeight) {
    return Container(
      height: cardHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [AppThemeData.grey800, AppThemeData.grey900Dark]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child: const CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2,
      ),
    );
  }
}
