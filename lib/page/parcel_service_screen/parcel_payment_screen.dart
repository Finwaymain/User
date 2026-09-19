import 'dart:developer';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/parcel_service_controller.dart';
import 'package:finway/themes/appbar_cust.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class ParcelPaymentScreen extends StatefulWidget {
  const ParcelPaymentScreen({super.key});

  @override
  State<ParcelPaymentScreen> createState() => _ParcelPaymentScreenState();
}

class _ParcelPaymentScreenState extends State<ParcelPaymentScreen> {
  late Razorpay _razorpay;
  ParcelServiceController? _ctrl;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    log('Razorpay UPI success: ${response.paymentId}');
    ShowToastDialog.showToast('UPI Payment successful!');
    _ctrl?.bookParcelRide();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    log('Razorpay UPI error: ${response.message}');
    String msg = 'Payment failed.';
    try {
      final decoded = response.message ?? '';
      if (decoded.isNotEmpty) msg = 'Payment failed: $decoded';
    } catch (_) {}
    ShowToastDialog.showToast(msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    log('Razorpay external wallet: ${response.walletName}');
    ShowToastDialog.showToast('Payment via ${response.walletName}');
  }

  void _openRazorpayUPI(ParcelServiceController controller, double amount) {
    final key = controller.paymentSettingModel.value.razorpay?.key ?? '';
    if (key.isEmpty) {
      ShowToastDialog.showToast('UPI payment not configured. Contact admin.');
      return;
    }
    final userData = Constant.getUserData();
    final userPhone = userData.data?.phone ?? '';
    final userEmail = userData.data?.email ?? '';

    final options = <String, dynamic>{
      'key': key,
      'amount': (amount * 100).round(),
      'name': 'Fiinway',
      'currency': 'INR',
      'description': 'Parcel Delivery Payment',
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
      log('Razorpay open error: $e');
      ShowToastDialog.showToast('Could not open UPI payment. Try again.');
    }
  }

  void _resetAll(ParcelServiceController c) {
    c.stripe = false.obs;
    c.wallet = false.obs;
    c.cash = false.obs;
    c.razorPay = false.obs;
    c.paypal = false.obs;
    c.payStack = false.obs;
    c.flutterWave = false.obs;
    c.mercadoPago = false.obs;
    c.payFast = false.obs;
    c.xendit = false.obs;
    c.midtrans = false.obs;
    c.orangePay = false.obs;
    c.upi = false.obs;
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final Color primary = AppThemeData.primary200;
    final Color bg = isDark ? AppThemeData.surface50Dark : const Color(0xFFF5F7FA);
    final Color card = isDark ? AppThemeData.surface50Dark : Colors.white;
    final Color textPrimary = isDark ? AppThemeData.grey900Dark : AppThemeData.grey900;
    final Color textSecondary = isDark ? AppThemeData.grey400Dark : AppThemeData.grey500;
    final Color divider = isDark ? AppThemeData.grey300Dark : const Color(0xFFE8ECF0);

    return GetX<ParcelServiceController>(
      init: ParcelServiceController(),
      builder: (controller) {
        _ctrl = controller;
        final String amountStr = Constant().amountShow(amount: '${controller.subTotal.value}');
        final String walletBal = Constant().amountShow(amount: controller.walletAmount.value);

        return Scaffold(
          backgroundColor: bg,
          appBar: CustomAppbar(
            bgColor: primary,
            title: 'Payment'.tr,
          ),
          body: Column(
            children: [



              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Transform.translate(
                    offset: const Offset(0, 50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Order summary card ───────────────────────────
                          _buildCard(
                            card: card,
                            divider: divider,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader('Order Summary'.tr, Icons.receipt_long_outlined, primary),
                                const SizedBox(height: 12),
                                _summaryRow('From'.tr, controller.senderAddress.value, textPrimary, textSecondary),
                                const SizedBox(height: 8),
                                _summaryRow('To'.tr, controller.receiverAddress.value, textPrimary, textSecondary),
                                const SizedBox(height: 8),
                                _summaryRow('Distance'.tr,
                                    '${controller.distance.value.toStringAsFixed(2)} ${Constant.distanceUnit}',
                                    textPrimary, textSecondary),
                                const SizedBox(height: 8),
                                Divider(color: divider, height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total'.tr,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: AppThemeData.semiBold,
                                            color: textPrimary)),
                                    Text(amountStr,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: AppThemeData.semiBold,
                                            color: primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ─── Payment method label ─────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(left: 2, bottom: 10),
                            child: Text(
                              'Select Payment Method'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: AppThemeData.semiBold,
                                color: textPrimary,
                              ),
                            ),
                          ),

                          // ─── Payment option cards ─────────────────────────
                          _buildCard(
                            card: card,
                            divider: divider,
                            child: Column(
                              children: [
                                // Cash
                                if (controller.paymentSettingModel.value.cash?.isEnabled == 'true')
                                  _paymentOption(
                                    context: context,
                                    isDark: isDark,
                                    primary: primary,
                                    divider: divider,
                                    card: card,
                                    icon: Icons.payments_outlined,
                                    iconBg: const Color(0xFFE8F5E9),
                                    iconColor: Colors.green,
                                    label: 'Cash'.tr,
                                    subtitle: 'Pay after delivery'.tr,
                                    isSelected: controller.cash.value,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    onTap: () {
                                      _resetAll(controller);
                                      controller.cash = true.obs;
                                      controller.paymentMethodType.value = 'Cash';
                                      controller.paymentMethodId.value =
                                          controller.paymentSettingModel.value.cash!.idPaymentMethod.toString();
                                    },
                                  ),

                                // Wallet
                                if (controller.paymentSettingModel.value.myWallet?.isEnabled == 'true')
                                  _paymentOption(
                                    context: context,
                                    isDark: isDark,
                                    primary: primary,
                                    divider: divider,
                                    card: card,
                                    icon: Icons.account_balance_wallet_outlined,
                                    iconBg: const Color(0xFFE3F2FD),
                                    iconColor: Colors.blue,
                                    label: 'Wallet'.tr,
                                    subtitle: '${'Balance'.tr}: $walletBal',
                                    isSelected: controller.wallet.value,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    onTap: () {
                                      _resetAll(controller);
                                      controller.wallet = true.obs;
                                      controller.paymentMethodType.value = 'Wallet';
                                      controller.paymentMethodId =
                                          controller.paymentSettingModel.value.myWallet!.idPaymentMethod.toString().obs;
                                    },
                                  ),

                                // UPI via Razorpay
                                if (controller.paymentSettingModel.value.razorpay?.isEnabled == 'true')
                                  _paymentOption(
                                    context: context,
                                    isDark: isDark,
                                    primary: primary,
                                    divider: divider,
                                    card: card,
                                    icon: Icons.qr_code_scanner,
                                    iconBg: const Color(0xFFFFF3E0),
                                    iconColor: Colors.orange,
                                    label: 'UPI'.tr,
                                    subtitle: 'Google Pay, PhonePe, BHIM & more'.tr,
                                    isSelected: controller.upi.value,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    showLast: true,
                                    onTap: () {
                                      _resetAll(controller);
                                      controller.upi = true.obs;
                                      controller.paymentMethodType.value = 'UPI';
                                      controller.paymentMethodId.value =
                                          controller.paymentSettingModel.value.razorpay?.idPaymentMethod?.toString() ??
                                              controller.paymentSettingModel.value.cash!.idPaymentMethod.toString();
                                    },
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100), // bottom padding for Pay button
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ─── Floating Pay button ──────────────────────────────────────────
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: card,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: ButtonThem.buildButton(
                context,
                title: controller.paymentMethodId.isEmpty
                    ? 'Select a payment method'.tr
                    : '${'Pay'.tr} $amountStr',
                btnColor: controller.paymentMethodId.isEmpty ? Colors.grey : primary,
                onPress: () {
                  if (controller.paymentMethodId.isEmpty) {
                    ShowToastDialog.showToast('Please select a payment method');
                    return;
                  }
                  if (controller.wallet.value &&
                      double.parse(controller.walletAmount.value) < controller.subTotal.value) {
                    ShowToastDialog.showToast('Insufficient wallet balance');
                    return;
                  }
                  if (controller.upi.value) {
                    _openRazorpayUPI(controller, controller.subTotal.value);
                  } else {
                    controller.bookParcelRide();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Helper: card container ─────────────────────────────────────────────────
  Widget _buildCard({required Widget child, required Color card, required Color divider}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // ─── Helper: section header ─────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon, Color primary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontFamily: AppThemeData.semiBold,
                color: primary)),
      ],
    );
  }

  // ─── Helper: summary row ────────────────────────────────────────────────────
  Widget _summaryRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12, fontFamily: AppThemeData.regular, color: textSecondary)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
                fontSize: 13, fontFamily: AppThemeData.medium, color: textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Helper: payment option tile ────────────────────────────────────────────
  Widget _paymentOption({
    required BuildContext context,
    required bool isDark,
    required Color primary,
    required Color divider,
    required Color card,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool isSelected,
    required Color textPrimary,
    required Color textSecondary,
    required VoidCallback onTap,
    bool showLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Row(
              children: [
                // Icon bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? primary.withValues(alpha: 0.12) : iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? primary : iconColor,
                  ),
                ),
                const SizedBox(width: 14),
                // Label + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: AppThemeData.semiBold,
                            color: isSelected ? primary : textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: AppThemeData.regular,
                            color: textSecondary,
                          )),
                    ],
                  ),
                ),
                // Radio indicator
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primary : divider,
                      width: isSelected ? 5 : 2,
                    ),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!showLast) Divider(color: divider, height: 1),
      ],
    );
  }
}
