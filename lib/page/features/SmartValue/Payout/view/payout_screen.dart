import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../constant/constant.dart';
import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../add_bank_details/add_bank_account.dart';
import '../controller/payout_controller.dart';

class PayoutScreen extends StatelessWidget {
  const PayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PayoutController controller = Get.put(PayoutController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppThemeData.primary200;

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: "Request Payout",
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: controller.fadeAnimation,
            child: SlideTransition(
              position: controller.slideAnimation,
              child: Column(
                children: [
                  // Balance Overview Section
                  Obx(() {
                    if (controller.accountDetailsModel.value == null) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withValues(alpha: 0.8),
                              primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withValues(alpha: 0.9),
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Decorative circles
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -20,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Available Balance",
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "${Constant.currency}${controller.totalAmount}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Divider
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Wallet and Earnings breakdown
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.wallet,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Wallet",
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 30),
                                            child: Text(
                                              "${Constant.currency}${controller.amount}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const SizedBox(width: 12),
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.trending_up_rounded,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Earnings",
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 42),
                                            child: Text(
                                              "${Constant.currency}${controller.earnAmount}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Amount Input Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Enter Withdrawal Amount",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800.withValues(alpha: 0.5)
                                : primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                Constant.currency.toString(),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor.withValues(alpha: 0.5),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: IntrinsicWidth(
                                  child: TextField(
                                    controller: controller.amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      height: 1,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "0.00",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                    ],
                                    onChanged: (value) => controller.update(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Amount Selection
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Quick Select",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  GetBuilder<PayoutController>(
                    builder: (controller) => Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: controller.presetAmounts.map((amount) {
                        final isSelected = controller.amountController.text == amount.toString();
                        return GestureDetector(
                          onTap: () => controller.handleAmountSelection(amount),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                                  : null,
                              color: isSelected
                                  ? null
                                  : isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(
                              "${Constant.currency}$amount",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : isDark
                                    ? Colors.white70
                                    : Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Receiving Bank Account Card
                  Obx(() {
                    final accData = controller.accountDetailsModel.value?.data;
                    final bankName = accData?.bankName;
                    final accountNo = accData?.accountNo;
                    final holderName = accData?.holderName;
                    final ifsc = accData?.ifscCode ?? accData?.otherInfo;

                    final hasBank = bankName != null && bankName.isNotEmpty && bankName != 'null';

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_rounded,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        "Receiving Bank Account",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    isDismissible: true,
                                    isScrollControlled: true,
                                    context: context,
                                    backgroundColor: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                                    builder: (context) => const AddBankAccount(),
                                  ).then((_) => controller.getAccountDetails("${Constant.getUserData().data?.acNo}"));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded, size: 14, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        hasBank ? "Change" : "+ Add",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (hasBank) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        bankName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.grey.shade900,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "Linked",
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Account No: ${accountNo ?? 'N/A'}",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  ),
                                  if (holderName != null && holderName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "Holder: $holderName",
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ],
                                  if (ifsc != null && ifsc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "IFSC / Info: $ifsc",
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "No bank account linked. Please tap '+ Add' to set up your payout destination.",
                                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Request Button
                  Obx(() => Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: controller.isLoading.value
                          ? null
                          : LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      color: controller.isLoading.value ? Colors.grey.shade300 : null,
                      boxShadow: controller.isLoading.value
                          ? null
                          : [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.isLoading.value ? null : controller.handlePayoutRequest,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: controller.isLoading.value
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "Request Payout",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue.shade900.withValues(alpha: 0.2)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.blue.shade800.withValues(alpha: 0.3)
                            : Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Payouts typically take 1-3 business days to process",
                            style: TextStyle(
                              color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../../../../constant/constant.dart';
// import '../../../../../themes/constant_colors.dart';
// import '../../../../../themes/custom_base_widget.dart';
// import '../controller/payout_controller.dart';
//
// class PayoutScreen extends StatelessWidget {
//   const PayoutScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final PayoutController controller = Get.put(PayoutController());
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final primaryColor = AppThemeData.primary200;
//
//     return CustomBaseWidget(
//       showAppBar: true,
//       appBarTitle: "Request Payout",
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: FadeTransition(
//             opacity: controller.fadeAnimation,
//             child: SlideTransition(
//               position: controller.slideAnimation,
//               child: Column(
//                 children: [
//                   // Header Section
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(24),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           primaryColor.withOpacity(0.1),
//                           primaryColor.withOpacity(0.05),
//                         ],
//                       ),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: primaryColor.withOpacity(0.2),
//                         width: 1,
//                       ),
//                     ),
//                     child: Column(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: primaryColor.withOpacity(0.1),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.account_balance_wallet_rounded,
//                             size: 32,
//                             color: primaryColor,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           "Enter Payout Amount",
//                           style: Theme.of(context)
//                               .textTheme
//                               .headlineSmall
//                               ?.copyWith(
//                             fontWeight: FontWeight.bold,
//                             color: isDark
//                                 ? Colors.white
//                                 : Colors.grey.shade800,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           "Enter the amount you'd like to withdraw",
//                           style:
//                           Theme.of(context).textTheme.bodyMedium?.copyWith(
//                             color: Colors.grey.shade600,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   // Amount Input Section
//                   Container(
//                     padding: const EdgeInsets.all(24),
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: isDark ? Colors.grey.shade800 : Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Amount (${Constant.currency})",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color:
//                             isDark ? Colors.white70 : Colors.grey.shade700,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Container(
//                           width: double.infinity,
//                           decoration: BoxDecoration(
//                             color: isDark
//                                 ? Colors.grey.shade700
//                                 : Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: Center(
//                             child: IntrinsicWidth(
//                               child: TextField(
//                                 controller: controller.amountController,
//                                 keyboardType:
//                                 const TextInputType.numberWithOptions(
//                                     decimal: true),
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 36,
//                                   fontWeight: FontWeight.bold,
//                                   color: primaryColor,
//                                 ),
//                                 decoration: InputDecoration(
//                                   hintText: "0.00",
//                                   hintStyle: TextStyle(
//                                     color: Colors.grey.shade400,
//                                     fontSize: 36,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                   prefix: Text(
//                                     Constant.currency.toString(),
//                                     style: TextStyle(
//                                       color: isDark
//                                           ? AppThemeData.grey500Dark
//                                           : AppThemeData.grey500,
//                                       fontFamily: AppThemeData.semiBold,
//                                       fontSize: 36,
//                                     ),
//                                   ),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                     borderSide: BorderSide.none,
//                                   ),
//                                   filled: false,
//                                   // fillColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
//                                 ),
//                                 inputFormatters: [
//                                   FilteringTextInputFormatter.allow(
//                                       RegExp(r'^\d+\.?\d{0,2}')),
//                                 ],
//                                 onChanged: (value) => controller.update(),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Quick Amount Selection
//                   Text(
//                     "Quick Select",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? Colors.white : Colors.grey.shade800,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//
//                   GetBuilder<PayoutController>(
//                     builder: (controller) => Wrap(
//                       spacing: 12,
//                       runSpacing: 12,
//                       alignment: WrapAlignment.center,
//                       children: controller.presetAmounts.map((amount) {
//                         final isSelected =
//                             controller.amountController.text == amount.toString();
//                         return AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           child: GestureDetector(
//                             onTap: () => controller.handleAmountSelection(amount),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                                 vertical: 12,
//                               ),
//                               decoration: BoxDecoration(
//                                 gradient: isSelected
//                                     ? LinearGradient(
//                                   colors: [
//                                     primaryColor,
//                                     primaryColor.withOpacity(0.8)
//                                   ],
//                                 )
//                                     : null,
//                                 color: isSelected
//                                     ? null
//                                     : isDark
//                                     ? Colors.grey.shade700
//                                     : Colors.white,
//                                 borderRadius: BorderRadius.circular(25),
//                                 border: Border.all(
//                                   color: isSelected
//                                       ? Colors.transparent
//                                       : primaryColor.withOpacity(0.3),
//                                   width: 1.5,
//                                 ),
//                                 boxShadow: isSelected
//                                     ? [
//                                   BoxShadow(
//                                     color: primaryColor.withOpacity(0.3),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 2),
//                                   ),
//                                 ]
//                                     : [
//                                   BoxShadow(
//                                     color: Colors.black.withOpacity(0.05),
//                                     blurRadius: 4,
//                                     offset: const Offset(0, 1),
//                                   ),
//                                 ],
//                               ),
//                               child: Text(
//                                 Constant.currency.toString() + "$amount",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: isSelected
//                                       ? Colors.white
//                                       : isDark
//                                       ? Colors.white70
//                                       : Colors.grey.shade700,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//
//                   const SizedBox(height: 40),
//
//                   // Request Button
//                   Obx(() => SizedBox(
//                     width: double.infinity,
//                     height: 56,
//                     child: ElevatedButton(
//                       onPressed: controller.isLoading.value ? null : controller.handlePayoutRequest,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         disabledBackgroundColor: Colors.grey.shade300,
//                       ),
//                       child: controller.isLoading.value
//                           ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           valueColor:
//                           AlwaysStoppedAnimation<Color>(Colors.white),
//                         ),
//                       )
//                           : Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.send_rounded,
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Request Payout",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   )),
//
//                   const SizedBox(height: 24),
//
//                   // Info Section
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.blue.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Colors.blue.shade200,
//                         width: 1,
//                       ),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.info_outline,
//                           color: Colors.blue.shade700,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             "Payouts typically take 1-3 business days to process",
//                             style: TextStyle(
//                               color: Colors.blue.shade700,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
