import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:finway/constant/constant.dart';
import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/model/service_price_estimate_model.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_history_screen.dart';
import 'service_style.dart';

class ServicePaymentSuccessScreen extends StatefulWidget {
  final int bookingId;
  final double amountPaid;
  final String paymentMethod;
  final ServiceRequestData? initialBooking;

  const ServicePaymentSuccessScreen({
    super.key,
    required this.bookingId,
    required this.amountPaid,
    required this.paymentMethod,
    this.initialBooking,
  });

  @override
  State<ServicePaymentSuccessScreen> createState() => _ServicePaymentSuccessScreenState();
}

class _ServicePaymentSuccessScreenState extends State<ServicePaymentSuccessScreen> {
  ServiceRequestData? _booking;
  bool _isLoading = false;
  late final ServiceBookingController _bookingController;

  @override
  void initState() {
    super.initState();
    _booking = widget.initialBooking;
    _bookingController = Get.isRegistered<ServiceBookingController>(tag: 'invoice_${widget.bookingId}')
        ? Get.find<ServiceBookingController>(tag: 'invoice_${widget.bookingId}')
        : Get.put(ServiceBookingController(), tag: 'invoice_${widget.bookingId}');

    if (_booking == null || _booking?.driver == null || _booking?.priceBreakdown == null) {
      _fetchBookingDetails();
    }
  }

  Future<void> _fetchBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await _bookingController.refreshBooking(widget.bookingId);
      if (mounted && fetched != null) {
        setState(() {
          _booking = fetched;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _money(double value) => '${Constant.currency ?? '₹'}${value.toStringAsFixed(0)}';

  String get _methodLabel {
    final method = (widget.paymentMethod.isNotEmpty ? widget.paymentMethod : (_booking?.paymentStatus ?? ''))
        .toLowerCase()
        .trim();
    if (method.contains('wallet')) return 'Fiinway Wallet'.tr;
    if (method.contains('upi') || method.contains('razorpay')) return 'UPI / Online'.tr;
    if (method.contains('cash')) return 'Cash on Delivery'.tr;
    return 'Paid / Direct'.tr;
  }

  Future<void> _makeCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final booking = _booking;
    final driver = booking?.driver;
    final breakdown = booking?.priceBreakdown;
    final categoryStyle = categoryStyleFor(booking?.serviceName);

    // Calculate itemized breakdown
    final serviceItems = booking?.bookedServiceItems ?? [];
    double serviceItemsTotal = 0.0;
    for (var item in serviceItems) {
      final itemPrice = item.minPrice > 0 ? item.minPrice : item.price;
      serviceItemsTotal += itemPrice;
    }

    final visitingCharge = booking?.visitingChargeAmount ?? (breakdown?.visitingCharge ?? 0);
    final materialCost = booking?.materialCostAmount ?? (breakdown?.materialCost ?? 0);
    
    double baseServiceCost = serviceItemsTotal > 0 ? serviceItemsTotal : (booking?.amount ?? 0);
    if (baseServiceCost <= 0 && widget.amountPaid > 0) {
      baseServiceCost = widget.amountPaid;
    }

    // Dynamic Admin Taxes & Fees from booking record or active tax settings
    List<Map<String, dynamic>> activeTaxList = [];
    if (booking?.tax != null && booking!.tax!.isNotEmpty) {
      for (var item in booking.tax!) {
        if (item is Map) {
          final label = item['libelle'] ?? item['name'] ?? item['label'] ?? 'Tax';
          final val = item['value']?.toString() ?? '';
          final type = item['type']?.toString() ?? 'Percentage';
          final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          if (amt > 0) {
            activeTaxList.add({
              'label': type == 'Percentage' && val.isNotEmpty ? '$label ($val%)' : label.toString(),
              'amount': amt,
            });
          }
        }
      }
    }

    if (activeTaxList.isEmpty) {
      final paymentMethod = widget.paymentMethod.isNotEmpty ? widget.paymentMethod : (booking?.paymentStatus ?? 'wallet');
      activeTaxList = Constant.getTaxBreakdown(
        baseServiceCost + visitingCharge,
        paymentMethod,
      );
    }

    double totalTaxAmount = 0;
    for (var t in activeTaxList) {
      totalTaxAmount += (t['amount'] as double? ?? 0.0);
    }

    if (totalTaxAmount <= 0 && booking?.taxAmount != null && booking!.taxAmount! > 0) {
      totalTaxAmount = booking!.taxAmount!;
      activeTaxList.add({
        'label': 'Taxes & Platform Charges'.tr,
        'amount': totalTaxAmount,
      });
    }

    final double baseSum = baseServiceCost + visitingCharge + materialCost;
    if (activeTaxList.isEmpty && widget.amountPaid > baseSum) {
      final diff = widget.amountPaid - baseSum;
      if (diff > 0) {
        totalTaxAmount = diff;
        activeTaxList.add({
          'label': 'Taxes & Platform Charges'.tr,
          'amount': diff,
        });
      }
    }

    final double computedTotal = baseSum + totalTaxAmount;
    final double totalAmount = (widget.amountPaid > computedTotal) ? widget.amountPaid : computedTotal;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF6F8FA),
        appBar: AppBar(
          backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Service Invoice'.tr,
            style: TextStyle(
              fontFamily: AppThemeData.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : AppThemeData.grey900,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.close_rounded, color: isDarkMode ? Colors.white70 : AppThemeData.grey800),
              onPressed: () => Get.offAll(() => const MainDashboard()),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading && _booking == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    children: [
                      // 1. Success Hero Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF16232B) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode ? Colors.white10 : const Color(0xFFA7F3D0),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppThemeData.success300.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle_rounded, color: AppThemeData.success300, size: 44),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Payment Successful!'.tr,
                              style: TextStyle(
                                fontFamily: AppThemeData.bold,
                                fontSize: 20,
                                color: isDarkMode ? Colors.white : AppThemeData.grey900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your home service has been completed & verified.'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. Receipt Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E2436) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDarkMode ? Colors.white10 : const Color(0xFFEBEFF5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking Summary Header
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: categoryStyle.bg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(categoryStyle.icon, color: categoryStyle.color, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Booking ID'.tr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: AppThemeData.medium,
                                              color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppThemeData.success300.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'PAID'.tr,
                                              style: TextStyle(
                                                fontFamily: AppThemeData.bold,
                                                fontSize: 10,
                                                color: AppThemeData.success300,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '#${widget.bookingId}',
                                        style: TextStyle(
                                          fontFamily: AppThemeData.bold,
                                          fontSize: 15,
                                          color: isDarkMode ? Colors.white : AppThemeData.grey900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cleanServiceName(booking?.serviceName).tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.semiBold,
                                          fontSize: 14,
                                          color: categoryStyle.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ),

                            _buildDottedDivider(isDarkMode),

                            // Booking Details (Location & Schedule)
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  if ((booking?.serviceAddress ?? booking?.addressType ?? '').isNotEmpty)
                                    _buildInfoRow(
                                      icon: Icons.location_on_rounded,
                                      iconColor: const Color(0xFFEF4444),
                                      title: 'Service Address'.tr,
                                      value: booking?.serviceAddress ?? booking!.addressType!,
                                      isDarkMode: isDarkMode,
                                    ),
                                  if (booking?.scheduleLabel != null && booking!.scheduleLabel.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      icon: Icons.calendar_month_rounded,
                                      iconColor: AppThemeData.primary200,
                                      title: 'Date & Time Slot'.tr,
                                      value: booking.scheduleLabel,
                                      isDarkMode: isDarkMode,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    icon: Icons.payment_rounded,
                                    iconColor: const Color(0xFF3B82F6),
                                    title: 'Payment Method'.tr,
                                    value: _methodLabel,
                                    isDarkMode: isDarkMode,
                                  ),
                                ],
                              ),
                            ),

                            _buildDottedDivider(isDarkMode),

                            // 3. Serviceman / Provider Details Card
                            if (driver != null && (driver.name?.isNotEmpty ?? false)) ...[
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SERVICEMAN DETAILS'.tr,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.bold,
                                        fontSize: 11,
                                        letterSpacing: 1,
                                        color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF283049) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // Provider Avatar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: driver.photo != null && driver.photo!.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: driver.photo!,
                                                    width: 48,
                                                    height: 48,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (_, __, ___) => _defaultAvatar(driver.name),
                                                  )
                                                : _defaultAvatar(driver.name),
                                          ),
                                          const SizedBox(width: 12),
                                          // Name & Profession
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  driver.name ?? 'Service Specialist',
                                                  style: TextStyle(
                                                    fontFamily: AppThemeData.bold,
                                                    fontSize: 14.5,
                                                    color: isDarkMode ? Colors.white : AppThemeData.grey900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  driver.profession ?? cleanServiceName(booking?.serviceName),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB800)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      driver.ratingLabel,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData.semiBold,
                                                        fontSize: 11.5,
                                                        color: isDarkMode ? Colors.white70 : AppThemeData.grey800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Phone Call Button
                                          if (driver.phone != null && driver.phone!.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () => _makeCall(driver.phone),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: AppThemeData.primary200.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.phone_in_talk_rounded,
                                                    color: AppThemeData.primary200,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (driver.phone != null && driver.phone!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.phone_iphone_rounded, size: 13, color: AppThemeData.grey500),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Contact: ${driver.phone}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontFamily: AppThemeData.medium,
                                                color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _buildDottedDivider(isDarkMode),
                            ],

                            // 4. Itemized Cost Breakdown
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AMOUNT BREAKDOWN'.tr,
                                    style: TextStyle(
                                      fontFamily: AppThemeData.bold,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Service Line Items or Base Service Cost
                                  if (serviceItems.isNotEmpty)
                                    ...serviceItems.map((item) {
                                      final itemPrice = item.minPrice > 0 ? item.minPrice : item.price;
                                      return _buildBreakdownRow(
                                        item.name,
                                        itemPrice > 0 ? _money(itemPrice) : (item.displayPrice),
                                        isDarkMode,
                                      );
                                    })
                                  else if (baseServiceCost > 0)
                                    _buildBreakdownRow(
                                      cleanServiceName(booking?.serviceName).tr,
                                      _money(baseServiceCost),
                                      isDarkMode,
                                    )
                                  else
                                    _buildBreakdownRow(
                                      cleanServiceName(booking?.serviceName).tr,
                                      _money(totalAmount),
                                      isDarkMode,
                                    ),

                                  // Visiting Charge
                                  if (visitingCharge > 0 && serviceItems.isNotEmpty)
                                    _buildBreakdownRow(
                                      'Visiting & Inspection Charge'.tr,
                                      _money(visitingCharge),
                                      isDarkMode,
                                    )
                                  else if (breakdown?.visitingChargeLabel.isNotEmpty ?? false)
                                    _buildBreakdownRow(
                                      'Visiting Charge'.tr,
                                      breakdown!.visitingChargeLabel,
                                      isDarkMode,
                                      isHighlighted: true,
                                    ),

                                  // Material / Parts Cost
                                  if (materialCost > 0)
                                    _buildBreakdownRow(
                                      'Materials & Spare Parts'.tr,
                                      _money(materialCost),
                                      isDarkMode,
                                    ),

                                  // GST and Taxes Breakdown
                                  if (activeTaxList.isNotEmpty)
                                    ...activeTaxList.map((tax) => _buildBreakdownRow(
                                          tax['label'].toString().tr,
                                          _money(tax['amount'] as double? ?? 0.0),
                                          isDarkMode,
                                        ))
                                  else if (totalTaxAmount > 0)
                                    _buildBreakdownRow(
                                      'Taxes & GST (18%)'.tr,
                                      _money(totalTaxAmount),
                                      isDarkMode,
                                    ),

                                  const SizedBox(height: 8),
                                  Divider(color: isDarkMode ? Colors.white12 : const Color(0xFFE2E8F0)),
                                  const SizedBox(height: 8),

                                  // Total Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Amount Paid'.tr,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.bold,
                                          fontSize: 15,
                                          color: isDarkMode ? Colors.white : AppThemeData.grey900,
                                        ),
                                      ),
                                      Text(
                                        _money(totalAmount),
                                        style: TextStyle(
                                          fontFamily: AppThemeData.bold,
                                          fontSize: 20,
                                          color: AppThemeData.primary200,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 5. Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6AA720),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.receipt_long_rounded, size: 20),
                          label: Text('Download Tax Invoice'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 14)),
                          onPressed: () async {
                            final uri = Uri.parse('https://api.fiinway.com/invoice/${widget.bookingId}/download?ride_id=${widget.bookingId}&amount=${widget.amountPaid}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      ButtonThem.buildButton(
                        context,
                        title: 'View Booking History'.tr,
                        btnColor: AppThemeData.primary200,
                        txtColor: Colors.white,
                        radius: 14,
                        btnHeight: 50,
                        onPress: () {
                          Get.offAll(() => const ServiceHistoryScreen(initialTab: 2));
                        },
                      ),

                      const SizedBox(height: 12),

                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: isDarkMode ? Colors.white24 : AppThemeData.primary200,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () => Get.offAll(() => const MainDashboard()),
                        child: Text(
                          'Back to Home'.tr,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : AppThemeData.primary200,
                            fontFamily: AppThemeData.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String? name) {
    final initial = (name != null && name.trim().isNotEmpty) ? name.trim()[0].toUpperCase() : 'S';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppThemeData.primary200.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 20,
            color: AppThemeData.primary200,
          ),
        ),
      ),
    );
  }

  Widget _buildDottedDivider(bool isDarkMode) {
    return Container(
      height: 1,
      color: isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppThemeData.medium,
                  color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontFamily: AppThemeData.semiBold,
                  color: isDarkMode ? Colors.white : AppThemeData.grey900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, String amount, bool isDarkMode, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontFamily: AppThemeData.medium,
                color: isDarkMode ? AppThemeData.grey400Dark : AppThemeData.grey500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontFamily: AppThemeData.semiBold,
              color: isHighlighted
                  ? AppThemeData.success300
                  : (isDarkMode ? Colors.white : AppThemeData.grey900),
            ),
          ),
        ],
      ),
    );
  }
}

