import 'dart:math';

import 'package:finway/constant/constant.dart';
import 'package:finway/page/features/SmartValue/AccountDetails/controller/account_details_controller.dart';
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
    return controller.cardType;
  }

  double _cardHeight(double screenWidth) {
    return (screenWidth * 0.62).clamp(250.0, 300.0);
  }

  String _fullName() => controller.holderName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final hasProfile = controller.accountDetailsModel.value?.data != null ||
          Constant.getUserData().data != null;

      if (controller.isLoading.value && !hasProfile) {
        return _buildShimmerCard(isDark);
      }

      return GestureDetector(
        onTap: controller.flipCard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final cardHeight = _cardHeight(screenWidth);

            return SizedBox(
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
                      Container(
                        width: double.infinity,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeData.primary200.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(controller.flipAnimation.value),
                        child: Container(
                          width: double.infinity,
                          height: cardHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: isFrontVisible
                                  ? [AppThemeData.primary200, AppThemeData.primary300, const Color(0xFF0EA5E9)]
                                  : const [
                                      Color(0xFF1E293B),
                                      Color(0xFF0F172A),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: isFrontVisible
                                ? _buildFrontCard(cardHeight)
                                : _buildBackCard(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildFrontCard(double cardHeight) {
    final compact = cardHeight < 270;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: controller.shimmerAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.12),
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20, vertical: compact ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.bank,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          controller.accountType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _planLabel(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  maskWalletAccount(controller.accountNumber),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: compact ? 15 : 17,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _fullName().toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVAILABLE BALANCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Constant().amountShow(amount: controller.totalAmount),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 18 : 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (double.tryParse(controller.earnAmount) != null &&
                        (double.tryParse(controller.earnAmount) ?? 0) > 0)
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Cashback ${Constant().amountShow(amount: controller.earnAmount)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Row(
                children: [
                  Expanded(
                    child: _cardMeta(
                      'CARDHOLDER',
                      _fullName().toUpperCase(),
                      compact,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _cardMeta('VALID FROM', controller.expDate, compact, alignEnd: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardMeta(String label, String value, bool compact, {bool alignEnd = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 8, letterSpacing: 0.5),
        ),
        Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildBackCard() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A/c: ${controller.accountNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Text(
                      controller.cvv,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Tap to flip back',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
