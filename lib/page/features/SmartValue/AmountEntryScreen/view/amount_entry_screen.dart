import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/amount_entry_controller.dart';

class AmountEntryScreen extends StatefulWidget {
  final bool isQRPayment;
  final bool isBusiness;

  const AmountEntryScreen({
    super.key,
    required this.isQRPayment,
    this.isBusiness = false,
  });

  @override
  State<AmountEntryScreen> createState() => _AmountEntryScreenState();
}

class _AmountEntryScreenState extends State<AmountEntryScreen> {
  final AmountEntryController controller = Get.put(AmountEntryController());
  late final FocusNode amountFocusNode;

  @override
  void initState() {
    super.initState();
    amountFocusNode = FocusNode();

    // Request focus when screen builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          amountFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Unfocus and dispose before disposing screen
    amountFocusNode.unfocus();
    amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: widget.isBusiness ? 'Request Payment' : 'Enter Amount',
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                kToolbarHeight -
                20,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // User Info Card
                if (widget.isBusiness)
                  _buildBusinessUserCard(isDark)
                else
                  _buildRegularUserCard(isDark),

                const SizedBox(height: 40),

                // Amount Input Section
                if (widget.isBusiness)
                  _buildBusinessAmountInput(isDark, context)
                else
                  _buildRegularAmountInput(isDark, context),

                const Spacer(),

                // Action Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (controller.isLoading.value ||
                        controller.isLoadingName.value)
                        ? null
                        : () {
                      // Unfocus before navigation
                      amountFocusNode.unfocus();
                      FocusScope.of(context).unfocus();
                      controller.proceedToPinEntry(
                          controller.paymentData, widget.isQRPayment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isBusiness
                          ? AppThemeData.secondary300
                          : AppThemeData.primary200,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isBusiness
                              ? Icons.request_quote
                              : Icons.payment,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.isBusiness
                              ? "Complete Payment"
                              : "Pay Now",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularUserCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(() => controller.isLoadingName.value
              ? _buildShimmerAvatar(isDark)
              : CircleAvatar(
            radius: 30,
            backgroundColor: AppThemeData.primary200.withValues(alpha: 0.2),
            child: Text(
              controller.accountHolderName.value.isNotEmpty
                  ? controller.accountHolderName.value
                  .substring(0, 1)
                  .toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppThemeData.primary200,
              ),
            ),
          )),
          const SizedBox(height: 12),
          Obx(() => controller.isLoadingName.value
              ? _buildShimmerText(isDark, width: 150, height: 20)
              : Text(
            controller.accountHolderName.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: 8),
          Text(
            controller.paymentData.length > 10
                ? '${controller.paymentData.substring(0, 6)}...${controller.paymentData.substring(controller.paymentData.length - 4)}'
                : controller.paymentData,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessUserCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.blue[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemeData.secondary300.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 14,
                  color: AppThemeData.secondary300,
                ),
                const SizedBox(width: 4),
                Text(
                  'Business Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppThemeData.secondary300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Obx(() => controller.isLoadingName.value
                  ? _buildShimmerAvatar(isDark)
                  : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppThemeData.secondary300.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.store,
                  size: 36,
                  color: AppThemeData.secondary300,
                ),
              )),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paying to Business',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => controller.isLoadingName.value
                        ? _buildShimmerText(isDark, width: 120, height: 18)
                        : Text(
                      controller.accountHolderName.value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 16,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  controller.paymentData.length > 10
                      ? '${controller.paymentData.substring(0, 6)}...${controller.paymentData.substring(controller.paymentData.length - 4)}'
                      : controller.paymentData,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularAmountInput(bool isDark, BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter Amount',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            IntrinsicWidth(
              child: TextField(
                controller: controller.amountController,
                focusNode: amountFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    color: isDark ? Colors.grey[400] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) {
                  amountFocusNode.unfocus();
                  FocusScope.of(context).unfocus();
                  if (!controller.isLoading.value &&
                      !controller.isLoadingName.value) {
                    controller.proceedToPinEntry(
                      controller.paymentData,
                      widget.isQRPayment,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessAmountInput(bool isDark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Amount to Pay',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.secondary300.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppThemeData.secondary300,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IntrinsicWidth(
                child: TextField(
                  controller: controller.amountController,
                  focusNode: amountFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      color: isDark ? Colors.grey[400] : Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) {
                    amountFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                    if (!controller.isLoading.value &&
                        !controller.isLoadingName.value) {
                      controller.proceedToPinEntry(
                        controller.paymentData,
                        widget.isQRPayment,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Payment will be paid from business',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerAvatar(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey[600] : Colors.grey[300],
      ),
      child: ClipOval(
        child: _buildShimmerEffect(isDark),
      ),
    );
  }

  Widget _buildShimmerText(bool isDark,
      {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: _buildShimmerEffect(isDark),
    );
  }

  Widget _buildShimmerEffect(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, double opacity, child) {
          return AnimatedBuilder(
            animation: AlwaysStoppedAnimation(opacity),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.grey[700]!.withValues(alpha: 0.5),
                      Colors.grey[600]!.withValues(alpha: opacity),
                      Colors.grey[700]!.withValues(alpha: 0.5),
                    ]
                        : [
                      Colors.grey[200]!.withValues(alpha: 0.5),
                      Colors.grey[100]!.withValues(alpha: opacity),
                      Colors.grey[200]!.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              );
            },
          );
        },
        onEnd: () {},
      ),
    );
  }
}
/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../../themes/constant_colors.dart';
import '../../../../../themes/custom_base_widget.dart';
import '../../../../../utils/dark_theme_provider.dart';
import '../controller/amount_entry_controller.dart';

class AmountEntryScreen extends StatelessWidget {
  final bool isQRPayment;
  final AmountEntryController controller = Get.put(AmountEntryController());

  AmountEntryScreen({
    Key? key,
    required this.isQRPayment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    // Initialize API call when screen loads
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   controller.initializeWithPaymentData(paymentData);
    // });

    return CustomBaseWidget(
      showAppBar: true,
      appBarTitle: 'Enter Amount',
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // User Info Card with Shimmer Effect
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with shimmer
                  Obx(() => controller.isLoadingName.value
                      ? _buildShimmerAvatar(isDark)
                      : CircleAvatar(
                    radius: 30,
                    backgroundColor: AppThemeData.primary200.withOpacity(0.2),
                    child: Text(
                      controller.accountHolderName.value.isNotEmpty
                          ? controller.accountHolderName.value.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppThemeData.primary200,
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 12),

                  // Name with shimmer
                  Obx(() => controller.isLoadingName.value
                      ? _buildShimmerText(isDark, width: 150, height: 20)
                      : Text(
                    controller.accountHolderName.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ),
                  const SizedBox(height: 8),

                  // Account number/QR data
                  Text(
                    controller.paymentData.length > 10
                        ? '${controller.paymentData.substring(0, 6)}...${controller.paymentData.substring(controller.paymentData.length - 4)}'
                        : controller.paymentData,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Amount Input Label
            Text(
              'Enter Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Amount Input Field with ₹ centered
            Container(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IntrinsicWidth(
                    child: TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: false,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          color: isDark ? Colors.grey[400] : Colors.grey[400],
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Pay Button
            Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (controller.isLoading.value || controller.isLoadingName.value)
                    ? null
                    : () => controller.proceedToPinEntry(controller.paymentData, isQRPayment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeData.primary200,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Pay Now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Shimmer effect for avatar
  Widget _buildShimmerAvatar(bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.grey[600] : Colors.grey[300],
      ),
      child: ClipOval(
        child: _buildShimmerEffect(isDark),
      ),
    );
  }

  // Shimmer effect for text
  Widget _buildShimmerText(bool isDark, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[600] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: _buildShimmerEffect(isDark),
    );
  }

  // Base shimmer effect widget
  Widget _buildShimmerEffect(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, double opacity, child) {
          return AnimatedBuilder(
            animation: AlwaysStoppedAnimation(opacity),
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                      Colors.grey[700]!.withOpacity(0.5),
                      Colors.grey[600]!.withOpacity(opacity),
                      Colors.grey[700]!.withOpacity(0.5),
                    ]
                        : [
                      Colors.grey[200]!.withOpacity(0.5),
                      Colors.grey[100]!.withOpacity(opacity),
                      Colors.grey[200]!.withOpacity(0.5),
                    ],
                  ),
                ),
              );
            },
          );
        },
        onEnd: () {
          // Animation completed, can add repeat logic here if needed
        },
      ),
    );
  }
}*/

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:provider/provider.dart';
//
// import '../../../../../themes/constant_colors.dart';
// import '../../../../../themes/custom_base_widget.dart';
// import '../../../../../utils/dark_theme_provider.dart';
// import '../controller/amount_entry_controller.dart';
//
// class AmountEntryScreen extends StatelessWidget {
//   final String paymentData;
//   final bool isQRPayment;
//   final AmountEntryController controller = Get.put(AmountEntryController());
//
//   AmountEntryScreen({
//     Key? key,
//     required this.paymentData,
//     required this.isQRPayment,
//   }) : super(key: key);
//
//
//   @override
//   Widget build(BuildContext context) {
//     final themeChange = Provider.of<DarkThemeProvider>(context);
//     final isDark = themeChange.getThem();
//
//     return CustomBaseWidget(
//       showAppBar: true,
//       appBarTitle: 'Enter Amount',
//       resizeToAvoidBottomInset: true,
//       body: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           children: [
//             const SizedBox(height: 20),
//
//             // User Info Card
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: isDark ? Colors.grey[700] : Colors.white,
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: AppThemeData.primary200.withOpacity(0.2),
//                     child: Text(
//                       controller.accountHolderName.value.substring(0, 1),
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: AppThemeData.primary200,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     controller.accountHolderName.value,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: isDark ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     paymentData.length > 10
//                         ? '${paymentData.substring(0, 6)}...${paymentData.substring(paymentData.length - 4)}'
//                         : paymentData,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: isDark ? Colors.grey[300] : Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 40),
//
//             // Amount Input Label
//             Text(
//               'Enter Amount',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: isDark ? Colors.white : Colors.black87,
//               ),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Amount Input Field with ₹ centered
//             Container(
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 // Row content ke width ke hisaab se
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     '₹',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: isDark ? Colors.white : Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   IntrinsicWidth(
//                     child: TextField(
//                       controller: controller.amountController,
//                       keyboardType: TextInputType.number,
//                       textAlign: TextAlign.center,
//                       autofocus: false,
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: isDark ? Colors.white : Colors.black87,
//                       ),
//                       decoration: InputDecoration(
//                         hintText: '0.00',
//                         hintStyle: TextStyle(
//                           fontSize: 24,
//                           color: isDark ? Colors.grey[400] : Colors.grey[400],
//                         ),
//                         border: InputBorder.none,
//                         contentPadding: EdgeInsets.zero,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Spacer(),
//
//             // Pay Button
//             Obx(() => SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: controller.isLoading.value
//                     ? null
//                     : () => controller.proceedToPinEntry(
//                     paymentData, isQRPayment),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppThemeData.primary200,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 18),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   elevation: 5,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     Icon(Icons.payment, size: 20),
//                     SizedBox(width: 10),
//                     Text(
//                       "Pay Now",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )),
//
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
