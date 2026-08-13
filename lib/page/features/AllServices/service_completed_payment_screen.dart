import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/page/wallet/wallet_screen.dart';
import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/controller/wallet_controller.dart';
import 'package:finway/model/razorpay_gen_orderid_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'service_payment_success_screen.dart';
import 'service_scan_to_pay_screen.dart';

class ServiceCompletedPaymentScreen extends StatefulWidget {
  final int bookingId;

  const ServiceCompletedPaymentScreen({super.key, required this.bookingId});

  @override
  State<ServiceCompletedPaymentScreen> createState() => _ServiceCompletedPaymentScreenState();
}

class _ServiceCompletedPaymentScreenState extends State<ServiceCompletedPaymentScreen> {
  late final ServiceBookingController _controller;
  late final WalletController _walletController;
  final Razorpay _razorpay = Razorpay();
  ServiceRequestData? _booking;
  String _paymentMethod = 'wallet';
  bool _paying = false;
  bool _loading = true;
  double _walletBalance = 0;
  double _pendingRazorpayAmount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ServiceBookingController(), tag: 'payment_${widget.bookingId}');
    _walletController = Get.isRegistered<WalletController>() ? Get.find<WalletController>() : Get.put(WalletController());
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkCashPaidStatus());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _checkCashPaidStatus() async {
    if (!mounted || _paying) return;
    final item = await _controller.refreshBooking(widget.bookingId);
    if (!mounted || item == null) return;
    if (item.isPaid || item.isCompleted) {
      _pollTimer?.cancel();
      _goToSuccess(item.payableAmount, item.paymentStatus ?? 'paid_cash');
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final item = await _controller.refreshBooking(widget.bookingId);
    final balance = await _controller.fetchWalletBalance();
    if (!mounted) return;
    setState(() {
      _booking = item;
      _walletBalance = balance;
      _loading = false;
    });

    if (item != null && item.isPaid) {
      _goToSuccess(item.payableAmount, item.paymentStatus ?? 'wallet');
    }
  }

  Future<void> _payWithRazorpay(double total) async {
    final razorpay = _walletController.paymentSettingModel.value.razorpay;
    if (razorpay == null || razorpay.isEnabled != 'true' || (razorpay.key ?? '').isEmpty) {
      ShowToastDialog.showToast('UPI/Razorpay is not available. Please choose wallet or cash.'.tr);
      return;
    }

    _pendingRazorpayAmount = total;
    ShowToastDialog.showLoader('Please wait'.tr);
    final CreateRazorPayOrderModel? order =
        await _walletController.createOrderRazorPay(amount: total.round(), isTopup: false);
    ShowToastDialog.closeLoader();

    if (order == null || (order.id ?? '').isEmpty) {
      ShowToastDialog.showToast('Could not start UPI payment.'.tr);
      return;
    }

    _razorpay.open({
      'key': razorpay.key,
      'amount': (total * 100).round(),
      'name': 'Fiinway',
      'order_id': order.id,
      'currency': 'INR',
      'description': 'Home Service Booking',
      'retry': {'enabled': true, 'max_count': 1},
    });
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _paying = true);
    final ok = await _controller.payBooking(bookingId: widget.bookingId, paymentMethod: 'upi');
    if (!mounted) return;
    setState(() => _paying = false);
    if (ok) {
      _goToSuccess(_pendingRazorpayAmount, 'upi');
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    ShowToastDialog.showToast('Payment failed. Please try again.'.tr);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ShowToastDialog.showToast('Payment processing via ${response.walletName ?? 'UPI'}'.tr);
  }

  Future<void> _pay() async {
    final booking = _booking;
    if (booking == null || booking.isPaid) return;

    final total = booking.payableAmount;
    if (total <= 0) {
      ShowToastDialog.showToast('Payment amount is not available. Please contact support.'.tr);
      return;
    }

    if (_paymentMethod == 'wallet') {
      final paymentSuccess = await Get.to(() => ServiceScanToPayScreen(
            bookingId: widget.bookingId,
            expectedDriverId: booking.driverId?.toString() ?? '',
            amount: total,
            controller: _controller,
          ));

      if (paymentSuccess == true) {
        _goToSuccess(total, 'wallet');
      }
      return;
    }

    if (_paymentMethod == 'upi') {
      await _payWithRazorpay(total);
      return;
    }

    setState(() => _paying = true);
    final ok = await _controller.payBooking(bookingId: widget.bookingId, paymentMethod: _paymentMethod);
    if (!mounted) return;
    setState(() => _paying = false);

    if (ok) {
      _goToSuccess(total, _paymentMethod);
    }
  }

  void _goToSuccess(double amount, String method) {
    Get.off(
      () => ServicePaymentSuccessScreen(
        bookingId: widget.bookingId,
        amountPaid: amount,
        paymentMethod: method,
      ),
    );
  }

  String _money(double value) => '${Constant.currency ?? ''}${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final booking = _booking;
    final total = booking?.payableAmount ?? 0;
    final visitLabel = booking?.visitingChargeLabel ?? '';
    final visitAmount = booking?.visitingChargeAmount ?? 0;
    final materialAmount = booking?.materialCostAmount ?? 0;
    final platformFee = booking?.priceBreakdown?.platformFee ?? 0;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Complete Payment'.tr,
            style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
          ),
        ),
        body: _loading || booking == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [AppThemeData.primary200, AppThemeData.primary300]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.celebration, color: Colors.white, size: 36),
                                const SizedBox(height: 8),
                                Text('Payment Required'.tr, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Pay now so the expert can complete your booking.'.tr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _card(
                            isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Payment Summary'.tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                                const SizedBox(height: 10),
                                ...booking.bookedServiceItems.map(
                                  (e) => _priceRow(
                                    e.name,
                                    e.priceAvailable ? _money(e.minPrice) : (e.displayPrice.isNotEmpty ? e.displayPrice : 'Rate on visit'.tr),
                                    isDarkMode,
                                  ),
                                ),
                                if (visitAmount > 0)
                                  _priceRow('Visiting Charge'.tr, _money(visitAmount), isDarkMode)
                                else if (visitLabel.isNotEmpty)
                                  _priceRow('Visiting Charge'.tr, visitLabel, isDarkMode),
                                if (materialAmount > 0)
                                  _priceRow('Material Cost'.tr, _money(materialAmount), isDarkMode),
                                const Divider(height: 20),
                                _priceRow('Total Amount'.tr, total > 0 ? _money(total) : booking.displayPayableLabel, isDarkMode, bold: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _card(
                            isDarkMode,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Select Payment Method'.tr, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  '${'Wallet balance'.tr}: ${_money(_walletBalance)}',
                                  style: TextStyle(fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                                ),
                                const SizedBox(height: 8),
                                RadioListTile<String>(
                                  value: 'wallet',
                                  groupValue: _paymentMethod,
                                  activeColor: AppThemeData.primary200,

                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Wallet Balance'.tr,
                                        ),
                                      ),

                                      // Show Add Money button only when balance is insufficient
                                      if (_walletBalance < total && total > 0)
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () {
                                            Get.to(() =>  WalletScreen());
                                          },
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: AppThemeData.primary200.withValues(
                                                alpha: 0.10,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 22,
                                              color: AppThemeData.primary200,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  subtitle: _walletBalance < total && total > 0
                                      ? Text(
                                    'Insufficient balance'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                    ),
                                  )
                                      : Text(
                                    _money(_walletBalance),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode
                                          ? AppThemeData.grey500Dark
                                          : AppThemeData.grey500,
                                    ),
                                  ),

                                  onChanged: booking.isPaid
                                      ? null
                                      : (v) => setState(
                                        () => _paymentMethod = v ?? 'wallet',
                                  ),
                                ),
                                RadioListTile<String>(
                                  value: 'upi',
                                  groupValue: _paymentMethod,
                                  activeColor: AppThemeData.primary200,
                                  title: Text('UPI'.tr),
                                  subtitle: Text('Pay via Razorpay UPI'.tr, style: TextStyle(fontSize: 11, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                                  onChanged: booking.isPaid ? null : (v) => setState(() => _paymentMethod = v ?? 'upi'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                    child: SafeArea(
                      top: false,
                      child: ButtonThem.buildButton(
                        context,
                        title: booking.isPaid
                            ? 'Already Paid'.tr
                            : (_paying ? 'Processing...'.tr : '${'Pay'.tr} ${total > 0 ? _money(total) : booking.displayPayableLabel}'),
                        btnColor: AppThemeData.primary200,
                        radius: 12,
                        onPress: (_paying || booking.isPaid || total <= 0) ? () {} : _pay,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _card(bool isDarkMode, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value, bool isDarkMode, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontFamily: bold ? AppThemeData.semiBold : AppThemeData.regular))),
          Text(value, style: TextStyle(fontSize: 13, fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold, color: bold ? AppThemeData.primary200 : null)),
        ],
      ),
    );
  }
}
