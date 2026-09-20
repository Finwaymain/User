import 'package:cached_network_image/cached_network_image.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/image_constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_payment_controller.dart';
import 'package:finway/controller/parcel_order_controller.dart';
import 'package:finway/page/chats_screen/FullScreenImageViewer.dart';
import 'package:finway/page/parcel_service_screen/all_parcel_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_payment_selection_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_route_osm_view_screen.dart';
import 'package:finway/page/parcel_service_screen/parcel_route_view_screen.dart';
import 'package:finway/page/review_screens/add_review_screen.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/themes/custom_alert_dialog.dart';
import 'package:finway/themes/text_field_them.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/widget/StarRating.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ParcelDetailsScreen extends StatefulWidget {
  const ParcelDetailsScreen({super.key});

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen> {
  final resonController = TextEditingController();
  late Razorpay _razorpay;
  Timer? _pollTimer;
  ParcelPaymentController? _activeController;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_activeController != null && _activeController!.data.value.id != null) {
        final st = _activeController!.data.value.status?.toString().toLowerCase() ?? '';
        if (st != 'completed' && st != 'rejected' && st != 'canceled') {
          _activeController!.getParcelDetailsData(_activeController!.data.value.id.toString());
        }
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _razorpay.clear();
    resonController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    log('Razorpay UPI success: ${response.paymentId}');
    ShowToastDialog.showLoader('Verifying payment...'.tr);
    if (_activeController != null) {
      var res = await _activeController!.transactionAmountRequest();
      ShowToastDialog.closeLoader();
      if (res != null) {
        _activeController!.data.value.paymentStatus = 'yes';
        _activeController!.data.refresh();
        ShowToastDialog.showToast('Payment successful! Driver will now navigate to destination.'.tr);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log('Razorpay payment error: ${response.message}');
    ShowToastDialog.showToast('Payment failed. Please try again.'.tr);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log('Razorpay external wallet: ${response.walletName}');
    ShowToastDialog.showToast('Payment via ${response.walletName}'.tr);
  }


  void _payByUPI(ParcelPaymentController controller) {
    final key = controller.paymentSettingModel.value.razorpay?.key ?? '';
    if (key.isEmpty) {
      ShowToastDialog.showToast('UPI payment gateway not configured. Please contact support.'.tr);
      return;
    }
    final userData = Constant.getUserData();
    final userPhone = userData.data?.phone ?? '';
    final userEmail = userData.data?.email ?? '';
    final amount = controller.getTotalAmount();

    final options = <String, dynamic>{
      'key': key,
      'amount': (amount * 100).round(),
      'name': 'Fiinway',
      'currency': 'INR',
      'description': 'Parcel Delivery #${controller.data.value.id}',
      'send_sms_hash': true,
      'method': {'netbanking': false, 'card': false, 'upi': true, 'wallet': false},
      'prefill': {
        if (userPhone.isNotEmpty) 'contact': userPhone,
        if (userEmail.isNotEmpty) 'email': userEmail,
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      log('Razorpay UPI error: $e');
      ShowToastDialog.showToast('Could not launch UPI app. Please try again.'.tr);
    }
  }

  void _payByWallet(ParcelPaymentController controller) {
    final totalAmount = controller.getTotalAmount();
    final currentWallet = double.tryParse(controller.walletAmount.value) ?? 0.0;
    if (currentWallet < totalAmount) {
      ShowToastDialog.showToast("Insufficient wallet balance (${Constant().amountShow(amount: controller.walletAmount.value)}). Please choose Cash or UPI.".tr);
      return;
    }
    Get.defaultDialog(
      title: "Pay from Wallet".tr,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text("Wallet Balance: ${Constant().amountShow(amount: controller.walletAmount.value)}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Text("Pay ${Constant().amountShow(amount: totalAmount.toString())} for Parcel #${controller.data.value.id}?", textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      textConfirm: "Pay Now".tr,
      textCancel: "Cancel".tr,
      confirmTextColor: Colors.white,
      buttonColor: AppThemeData.primary200,
      onConfirm: () async {
        Get.back();
        List taxList = [];
        for (var v in Constant.taxList) {
          taxList.add(v.toJson());
        }
        Map<String, dynamic> bodyParams = {
          'id_parcel': controller.data.value.id.toString(),
          'id_driver': controller.data.value.idConducteur.toString(),
          'id_user_app': Preferences.getInt(Preferences.userId).toString(),
          'amount': controller.subTotalAmount.value.toString(),
          'paymethod': 'Wallet',
          'discount': controller.discountAmount.value.toString(),
          'tip': controller.tipAmount.value.toString(),
          'tax': taxList,
          'transaction_id': DateTime.now().microsecondsSinceEpoch.toString(),
          'payment_status': 'success',
        };
        var res = await controller.walletDebitAmountRequest(bodyParams);
        if (res != null) {
          controller.data.value.paymentStatus = 'yes';
          controller.walletAmount.value = (currentWallet - totalAmount).toStringAsFixed(2);
          controller.data.refresh();
          ShowToastDialog.showToast("Paid successfully from wallet! Driver will now navigate to destination.".tr);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    return GetX<ParcelPaymentController>(
      init: ParcelPaymentController(),
      builder: (controller) {
        _activeController = controller;
        final parcel = controller.data.value;
        final status = parcel.status?.toString().toLowerCase() ?? '';
        final isPaid = parcel.paymentStatus == "yes";
        final canCancel = (status == "new" || status == "confirmed") && status != "onride" && status != "completed";
        final isCompleted = status == "completed";

        return Scaffold(
          backgroundColor: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
          appBar: CustomAppbar(
            bgColor: AppThemeData.primary200,
            title: 'Parcel Details'.tr,
            elevation: 0,
          ),
          body: Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              // Top green header background strip
              Container(
                height: 100,
                color: AppThemeData.primary200,
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Top Route & Status Card
                            _buildTopRouteCard(context, controller, isDark),
                            const SizedBox(height: 14),

                            // 2. PROMINENT PICKUP OTP CARD
                            if (_shouldShowOtp(parcel))
                              _buildPickupOtpCard(context, controller, isDark),

                            // 2.1 POST-PICKUP PAYMENT REQUIRED CARD (Cash, UPI, Wallet)
                            if (status == 'onride' && !isPaid)
                              _buildPostOtpPaymentCard(context, controller, isDark),

                            // 2.2 PAYMENT COMPLETED CONFIRMATION
                            if (status == 'onride' && isPaid)
                              _buildPaymentCompletedCard(context, controller, isDark),

                            // 3. Assigned Driver Card (when assigned)
                            if (_hasDriver(parcel))
                              _buildAssignedDriverCard(context, controller, isDark),

                            // 4. Sender and Receiver Contacts Card
                            _buildSenderReceiverCard(context, controller, isDark),
                            const SizedBox(height: 14),

                            // 5. Parcel Specifications & Photos
                            _buildParcelInfoCard(context, controller, isDark),
                            const SizedBox(height: 14),

                            // 6. Bill & Pricing Details
                            _buildBillDetailsCard(context, controller, isDark),
                            const SizedBox(height: 14),

                            // 7. Order Meta Card
                            _buildOrderMetaCard(context, controller, isDark),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Bar
                    _buildBottomActionBar(context, controller, isDark, canCancel, isPaid, isCompleted),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _shouldShowOtp(dynamic parcel) {
    final status = parcel.status?.toString().toLowerCase() ?? '';
    final otp = parcel.otp?.toString() ?? '';
    return otp.isNotEmpty && status != 'onride' && status != 'completed' && status != 'rejected' && status != 'canceled';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2.1 POST-PICKUP PAYMENT CARD (Cash, UPI, Wallet)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPostOtpPaymentCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final totalAmount = controller.getTotalAmount();
    final amountFormatted = Constant().amountShow(amount: totalAmount.toString());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2205), const Color(0xFF382C07)]
              : [const Color(0xFFFFF9E6), const Color(0xFFFFF3CC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeData.warning200.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.warning200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Required".tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.amber[300] : const Color(0xFF8A5800),
                      ),
                    ),
                    Text(
                      "Parcel picked up! Complete payment so driver can navigate to destination.".tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[300] : const Color(0xFF6B4A08),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppThemeData.warning200.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Payable:".tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: AppThemeData.medium,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Text(
                  amountFormatted,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: AppThemeData.bold,
                    color: AppThemeData.primary200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3 Action Buttons: Cash, UPI, Wallet
          Row(
            children: [
              // 1. UPI Option
              Expanded(
                child: InkWell(
                  onTap: () => _payByUPI(controller),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF281E45) : const Color(0xFFF0ECFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF673AB7).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.qr_code_2_rounded, color: Color(0xFF673AB7), size: 26),
                        const SizedBox(height: 6),
                        Text(
                          "UPI (Instant)".tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            color: isDark ? Colors.white : const Color(0xFF4527A0),
                          ),
                        ),
                        Text(
                          "GPay / PhonePe / Paytm".tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.regular,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. Wallet Option
              Expanded(
                child: InkWell(
                  onTap: () => _payByWallet(controller),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF382216) : const Color(0xFFFFF0E6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6F00).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFF6F00), size: 26),
                        const SizedBox(height: 6),
                        Text(
                          "Smart Value".tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            color: isDark ? Colors.white : const Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          "Bal: ${Constant().amountShow(amount: controller.walletAmount.value)}",
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: AppThemeData.medium,
                            color: isDark ? Colors.orange[200] : const Color(0xFFB23B00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cash Notice (Collected by driver only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppThemeData.success300.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_outlined, color: AppThemeData.success300, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Paying with Cash? Hand cash directly to your driver. The driver will confirm cash receipt on their app.".tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: AppThemeData.medium,
                      color: isDark ? Colors.green[200] : const Color(0xFF0B6634),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2.2 PAYMENT COMPLETED CONFIRMATION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPaymentCompletedCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF102E20), const Color(0xFF183D2C)]
              : [const Color(0xFFE8F8F0), const Color(0xFFD3F4E3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeData.success300.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppThemeData.success300,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment Completed".tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.green[300] : const Color(0xFF0B6634),
                  ),
                ),
                Text(
                  "Delivery in progress. Driver is navigating to destination.".tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: AppThemeData.regular,
                    color: isDark ? Colors.grey[300] : const Color(0xFF265339),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDriver(dynamic parcel) {
    final driverId = parcel.idConducteur?.toString() ?? '';
    return driverId.isNotEmpty && driverId != 'null' && driverId != '0';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. TOP ROUTE & STATUS CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTopRouteCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;
    final status = parcel.status?.toString().toLowerCase() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Order ID + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppThemeData.primary200.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "#${parcel.id ?? ''}",
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        fontSize: 14,
                        color: AppThemeData.primary200,
                      ),
                    ),
                  ),
                  if (parcel.title != null && parcel.title.toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      parcel.title.toString(),
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // Route timeline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin column
              Column(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppThemeData.success300,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeData.success300.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 48,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppThemeData.warning200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppThemeData.warning200.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Addresses column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender / Pickup
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              parcel.senderName?.toString() ?? 'Sender',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: AppThemeData.semiBold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppThemeData.success300.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Pickup".tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.success300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          parcel.source?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppThemeData.regular,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Receiver / Dropoff
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              parcel.receiverName?.toString() ?? 'Receiver',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: AppThemeData.semiBold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppThemeData.warning200.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Dropoff".tr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: AppThemeData.medium,
                                  color: AppThemeData.warning200,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          parcel.destination?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: AppThemeData.regular,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Stats summary strip
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppThemeData.surface50Dark.withValues(alpha: 0.8) : AppThemeData.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Distance".tr, "${parcel.distance ?? '0'} ${parcel.distanceUnit ?? 'KM'}", isDark),
                Container(width: 1, height: 24, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                _buildStatItem("Duration".tr, parcel.duration?.toString() ?? '--', isDark),
                Container(width: 1, height: 24, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                _buildStatItem("Amount".tr, Constant().amountShow(amount: parcel.amount?.toString() ?? '0'), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. PROMINENT PICKUP VERIFICATION OTP CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildPickupOtpCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;
    final otp = parcel.otp?.toString() ?? '';
    final digits = otp.split('');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F2B1E), const Color(0xFF143826)]
              : [const Color(0xFFE8F8F0), const Color(0xFFD4F3E4)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppThemeData.success300.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeData.success300.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppThemeData.success300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                "Pickup Verification OTP".tr,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppThemeData.semiBold,
                  color: isDark ? Colors.green[300] : const Color(0xFF0B6634),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Share this 6-digit code with your driver when they arrive to pick up the parcel."
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontFamily: AppThemeData.regular,
              color: isDark ? Colors.grey[300] : const Color(0xFF265339),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // 6 Styled Digit Boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits.map((digit) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B4D34) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppThemeData.success300.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  digit,
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: AppThemeData.bold,
                    color: isDark ? Colors.white : const Color(0xFF0B6634),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Action buttons row: Copy OTP & Share OTP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Copy OTP Button
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: otp));
                  HapticFeedback.lightImpact();
                  ShowToastDialog.showToast("OTP $otp copied to clipboard".tr);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppThemeData.success300.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 16, color: AppThemeData.success300),
                      const SizedBox(width: 6),
                      Text(
                        "Copy OTP".tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: isDark ? Colors.white : const Color(0xFF0B6634),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Share OTP Button
              InkWell(
                onTap: () {
                  final msg = "Fiinway Parcel Pickup OTP: $otp\n"
                      "Pickup Location: ${parcel.source ?? ''}\n"
                      "Destination: ${parcel.destination ?? ''}\n"
                      "Order #${parcel.id}";
                  Share.share(msg, subject: "Parcel Pickup OTP: $otp");
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppThemeData.success300,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppThemeData.success300.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        "Share OTP".tr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AppThemeData.medium,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ASSIGNED DRIVER CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAssignedDriverCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;
    final driverName = parcel.driverName?.toString().isNotEmpty == true
        ? parcel.driverName.toString()
        : "${parcel.prenomConducteur ?? ''} ${parcel.nomConducteur ?? ''}".trim();
    final driverPhone = parcel.driverPhone?.toString() ?? '';
    final driverPhoto = parcel.driverPhoto?.toString() ?? parcel.photoPath?.toString() ?? '';
    final rating = double.tryParse(parcel.moyenneDriver?.toString() ?? parcel.moyenne?.toString() ?? '5.0') ?? 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Driver Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: driverPhoto.isNotEmpty && (driverPhoto.startsWith("http://") || driverPhoto.startsWith("https://"))
                ? CachedNetworkImage(
                    imageUrl: driverPhoto,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Image.asset(ImageConstant.logo, width: 56, height: 56),
                  )
                : Image.asset(ImageConstant.logo, width: 56, height: 56),
          ),
          const SizedBox(width: 14),

          // Driver details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assigned Delivery Partner".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.primary200,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driverName.isNotEmpty ? driverName : "Driver Partner",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: AppThemeData.semiBold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StarRating(
                      size: 14,
                      rating: rating,
                      color: AppThemeData.warning200,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call button
          if (driverPhone.isNotEmpty)
            InkWell(
              onTap: () => Constant.makePhoneCall(driverPhone),
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppThemeData.success300.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppThemeData.success300.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(Icons.phone_in_talk_rounded, color: AppThemeData.success300, size: 22),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. SENDER & RECEIVER CONTACTS CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSenderReceiverCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Contact Details".tr,
            style: TextStyle(
              fontSize: 15,
              fontFamily: AppThemeData.semiBold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Sender Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.success300.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded, size: 18, color: AppThemeData.success300),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sender".tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.medium,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      parcel.senderName?.toString() ?? 'Sender',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      parcel.senderPhone?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (parcel.senderPhone?.toString().isNotEmpty == true)
                IconButton(
                  icon: Icon(Icons.phone_rounded, color: AppThemeData.primary200, size: 20),
                  onPressed: () => Constant.makePhoneCall(parcel.senderPhone.toString()),
                ),
            ],
          ),

          const Divider(height: 20),

          // Receiver Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppThemeData.warning200.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_downward_rounded, size: 18, color: AppThemeData.warning200),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Receiver".tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppThemeData.medium,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      parcel.receiverName?.toString() ?? 'Receiver',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: AppThemeData.semiBold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      parcel.receiverPhone?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: AppThemeData.regular,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (parcel.receiverPhone?.toString().isNotEmpty == true)
                IconButton(
                  icon: Icon(Icons.phone_rounded, color: AppThemeData.primary200, size: 20),
                  onPressed: () => Constant.makePhoneCall(parcel.receiverPhone.toString()),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. PARCEL SPECIFICATIONS & PHOTOS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildParcelInfoCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;
    final images = parcel.parcelImage ?? [];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Parcel Specifications".tr,
            style: TextStyle(
              fontSize: 15,
              fontFamily: AppThemeData.semiBold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Specs chips row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSpecChip("Weight".tr, "${parcel.parcelWeight ?? '0'} KG", Icons.fitness_center_rounded, isDark),
              _buildSpecChip("Size".tr, "${parcel.parcelDimension ?? '0'} ft", Icons.aspect_ratio_rounded, isDark),
              if (parcel.title != null && parcel.title.toString().isNotEmpty)
                _buildSpecChip("Category".tr, parcel.title.toString(), Icons.inventory_2_rounded, isDark),
            ],
          ),

          // Photos gallery
          if (images.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Package Photos".tr,
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.medium,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                itemCount: images.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final imgUrl = images[index];
                  return InkWell(
                    onTap: () {
                      Get.to(() => FullScreenImageViewer(imageUrl: imgUrl));
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => Image.asset(ImageConstant.logo),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. BILL & PRICING DETAILS CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBillDetailsCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bill Breakdown".tr,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.semiBold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: parcel.paymentStatus == "yes"
                      ? AppThemeData.success300.withValues(alpha: 0.12)
                      : AppThemeData.warning200.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  parcel.paymentStatus == "yes" ? "Paid".tr : "Payment Pending".tr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: AppThemeData.semiBold,
                    color: parcel.paymentStatus == "yes" ? AppThemeData.success300 : AppThemeData.warning200,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildBillRow("Delivery Fare".tr, Constant().amountShow(amount: controller.subTotalAmount.toString()), isDark),
          if (controller.discountAmount.value > 0) ...[
            const SizedBox(height: 8),
            _buildBillRow("Discount".tr, "-${Constant().amountShow(amount: controller.discountAmount.toString())}", isDark, isDiscount: true),
          ],
          if (controller.taxAmount.value > 0) ...[
            const SizedBox(height: 8),
            _buildBillRow("Taxes".tr, Constant().amountShow(amount: controller.taxAmount.toString()), isDark),
          ],
          const Divider(height: 20),
          _buildBillRow("Total Payable".tr, Constant().amountShow(amount: controller.getTotalAmount().toString()), isDark, isTotal: true),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. ORDER META CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOrderMetaCard(BuildContext context, ParcelPaymentController controller, bool isDark) {
    final parcel = controller.data.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppThemeData.grey200Dark.withValues(alpha: 0.5) : AppThemeData.grey200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMetaRow("Booked On".tr, "${parcel.parcelDate ?? ''} ${parcel.parcelTime ?? ''}", isDark),
          const Divider(height: 16),
          _buildMetaRow("Payment Method".tr, parcel.libelle ?? 'Cash', isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. BOTTOM ACTION BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(
    BuildContext context,
    ParcelPaymentController controller,
    bool isDark,
    bool canCancel,
    bool isPaid,
    bool isCompleted,
  ) {
    final parcel = controller.data.value;
    final status = parcel.status?.toString().toLowerCase() ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pay Now Row
          if (!isPaid && !isCompleted)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => ParcelPaymentSelectionScreen(), arguments: {
                      "parcelData": controller.data.value,
                    });
                  },
                  icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
                  label: Text("Pay Now".tr, style: const TextStyle(fontSize: 16, fontFamily: AppThemeData.semiBold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeData.primary200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

          // Action buttons: Cancel Parcel | Track Ride
          Row(
            children: [
              if (canCancel)
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => buildShowBottomSheet(context, isDark, controller),
                      icon: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
                      label: Text("Cancel".tr, style: const TextStyle(color: Colors.red, fontFamily: AppThemeData.medium, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              if (canCancel) const SizedBox(width: 10),

              // Track Ride Button (or Add Review if completed)
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isCompleted) {
                        Get.to(() => const AddReviewScreen(), arguments: {
                          "data": controller.data.value,
                          "ride_type": "parcel",
                        });
                      } else {
                        var argumentData = {'type': status, 'data': controller.data.value};
                        if (Constant.liveTrackingMapType == "inappmap") {
                          if (Constant.selectedMapType == "osm") {
                            Get.to(() => const ParcelRouteOsmViewScreen(), arguments: argumentData);
                          } else {
                            Get.to(() => const ParcelRouteViewScreen(), arguments: argumentData);
                          }
                        } else {
                          Constant.redirectMap(
                            latitude: double.parse(controller.data.value.latDestination ?? '0'),
                            longLatitude: double.parse(controller.data.value.lngDestination ?? '0'),
                            name: controller.data.value.destination?.toString() ?? '',
                          );
                        }
                      }
                    },
                    icon: Icon(isCompleted ? Icons.star_rounded : Icons.radar_rounded, color: Colors.white, size: 20),
                    label: Text(
                      isCompleted ? "Add Review".tr : "Track Ride".tr,
                      style: const TextStyle(fontSize: 15, fontFamily: AppThemeData.semiBold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted ? AppThemeData.warning200 : AppThemeData.primary200,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'confirmed':
        bg = AppThemeData.success300.withValues(alpha: 0.14);
        fg = AppThemeData.success300;
        label = "Confirmed".tr;
        break;
      case 'onride':
      case 'on ride':
        bg = AppThemeData.warning200.withValues(alpha: 0.18);
        fg = AppThemeData.warning200;
        label = "In Transit".tr;
        break;
      case 'completed':
        bg = AppThemeData.primary200.withValues(alpha: 0.15);
        fg = AppThemeData.primary200;
        label = "Completed".tr;
        break;
      case 'canceled':
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red;
        label = "Cancelled".tr;
        break;
      case 'new':
      default:
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue;
        label = "Pending Driver".tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontFamily: AppThemeData.semiBold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontFamily: AppThemeData.semiBold,
            color: AppThemeData.primary200,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: AppThemeData.regular,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecChip(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppThemeData.surface50Dark : AppThemeData.surface50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppThemeData.primary200),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: AppThemeData.regular,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppThemeData.semiBold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, bool isDark, {bool isTotal = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontFamily: isTotal ? AppThemeData.semiBold : AppThemeData.regular,
            color: isTotal
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontFamily: isTotal ? AppThemeData.bold : AppThemeData.semiBold,
            color: isDiscount
                ? Colors.red
                : isTotal
                    ? AppThemeData.primary200
                    : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.regular,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontFamily: AppThemeData.medium,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CANCEL PARCEL BOTTOM SHEET
  // ──────────────────────────────────────────────────────────────────────────
  buildShowBottomSheet(BuildContext context, bool isDarkMode, ParcelPaymentController controller) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(20), topLeft: Radius.circular(20)),
      ),
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cancel Parcel".tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: AppThemeData.semiBold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Write a reason for Parcel cancellation".tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: AppThemeData.regular,
                      color: isDarkMode ? AppThemeData.grey400 : AppThemeData.grey300Dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFieldWidget(
                    maxLine: 3,
                    controller: resonController,
                    hintText: 'Enter reason here...'.tr,
                    fontSize: 14,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                          ),
                          child: Text("Close".tr, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (resonController.text.trim().isNotEmpty) {
                              Get.back();
                              showDialog(
                                barrierColor: Colors.black26,
                                context: context,
                                builder: (context) {
                                  return CustomAlertDialog(
                                    title: "Do you want to cancel this booking?".tr,
                                    onPressNegative: () => Get.back(),
                                    onPressPositive: () {
                                      if (controller.data.value.status.toString() == "new") {
                                        Map<String, String> bodyParams = {
                                          'parcel_id': controller.data.value.id.toString(),
                                          'reason': resonController.text.trim(),
                                        };
                                        controller.rejectParcel(bodyParams).then((value) {
                                          Get.back();
                                          if (value != null) {
                                            if (Get.isRegistered<ParcelOrderController>()) {
                                              Get.find<ParcelOrderController>().getParcel();
                                            }
                                            Get.offAll(() => const AllParcelScreen());
                                          }
                                        });
                                      } else {
                                        Map<String, String> bodyParams = {
                                          'id_parcel': controller.data.value.id.toString(),
                                          'id_user': controller.data.value.idConducteur?.toString() ?? '',
                                          'name': "${controller.data.value.senderName}",
                                          'from_id': Preferences.getInt(Preferences.userId).toString(),
                                          'user_cat': controller.userModel?.data?.userCat?.toString() ?? 'user_app',
                                          'reason': resonController.text.trim(),
                                        };
                                        controller.canceledParcel(bodyParams).then((value) {
                                          Get.back();
                                          if (value != null) {
                                            if (Get.isRegistered<ParcelOrderController>()) {
                                              Get.find<ParcelOrderController>().getParcel();
                                            }
                                            Get.offAll(() => const AllParcelScreen());
                                          }
                                        });
                                      }
                                    },
                                  );
                                },
                              );
                            } else {
                              ShowToastDialog.showToast("Please enter a reason".tr);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text("Cancel Booking".tr, style: const TextStyle(color: Colors.white, fontFamily: AppThemeData.semiBold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
