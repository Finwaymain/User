import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:finway/constant/constant.dart';
import 'package:finway/constant/show_toast_dialog.dart';

import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/controller/service_history_controller.dart';
import 'package:finway/model/service_price_estimate_model.dart';
import 'package:finway/model/service_request_model.dart';
import 'package:finway/page/features/AllServices/service_category_icon.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_completed_payment_screen.dart';

class ServiceExpertAssignedScreen extends StatefulWidget {
  final int bookingId;
  final ServiceRequestData? initialBooking;

  const ServiceExpertAssignedScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  State<ServiceExpertAssignedScreen> createState() => _ServiceExpertAssignedScreenState();
}

class _ServiceExpertAssignedScreenState extends State<ServiceExpertAssignedScreen> {
  late final ServiceBookingController _controller;
  ServiceRequestData? _booking;
  bool _loading = true;
  String? _error;
  bool _cancelling = false;

  Color _accent(bool isDarkMode) => isDarkMode ? AppThemeData.primary300Dark : AppThemeData.primary200;

  @override
  void initState() {
    super.initState();
    _booking = widget.initialBooking;
    _loading = _booking == null;
    _controller = Get.put(ServiceBookingController(), tag: 'assigned_${widget.bookingId}');
    _load();
    _controller.startPolling(widget.bookingId, onUpdate: (item) {
      if (!mounted) return;
      setState(() {
        _booking = item;
        _loading = false;
        _error = null;
      });
      if (item.isPaid || item.isCompleted || item.needsPayment) {
        _controller.stopPolling();
        Get.off(() => ServiceCompletedPaymentScreen(bookingId: widget.bookingId));
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      if (_booking == null) _loading = true;
      _error = null;
    });

    final item = await _controller.refreshBooking(widget.bookingId);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _booking = item ?? _booking ?? widget.initialBooking;
      if (_booking == null) {
        _error = 'Could not load booking details'.tr;
      }
    });
  }

  Future<void> _cancelBooking() async {
    if (_booking == null || !_booking!.canBeCancelled) {
      ShowToastDialog.showToast('Service is already in progress or completed. Cannot be cancelled.'.tr);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Booking?'.tr),
        content: Text('Are you sure you want to cancel this service request?'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No'.tr)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Yes, Cancel'.tr)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    _controller.stopPolling();
    final ok = await _controller.cancelBooking(bookingId: widget.bookingId);
    if (!mounted) return;
    setState(() => _cancelling = false);

    if (ok) {
      await ServiceHistoryController.refreshAll();
      Get.offAll(() => const MainDashboard());
    } else {
      _controller.startPolling(widget.bookingId, onUpdate: (item) {
        if (!mounted) return;
        setState(() => _booking = item);
        if (item.isCompleted && item.isPaid) {
          _controller.stopPolling();
          return;
        }
        if (item.needsPayment) {
          _controller.stopPolling();
          Get.off(() => ServiceCompletedPaymentScreen(bookingId: widget.bookingId));
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.stopPolling();
    super.dispose();
  }

  String _money(double value) => '${Constant.currency ?? ''}${value.toStringAsFixed(0)}';

  String _driverPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return '';
    if (photo.startsWith('http')) return photo;
    return resolveServiceImageUrl(photo);
  }

  void _showPriceBreakup(bool isDarkMode, ServiceRequestData booking) {
    final breakdown = booking.priceBreakdown;
    if (breakdown == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Breakup'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ...breakdown.serviceItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 13)),
                      Text(item.displayPrice, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13)),
                    ],
                  ),
                )),
            if (breakdown.visitingCharge > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Visiting Charge'.tr, style: const TextStyle(fontSize: 13)),
                    Text(breakdown.displayVisitingCharge, style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13)),
                  ],
                ),
              ),
            if (breakdown.platformFee > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Platform Fee'.tr, style: const TextStyle(fontSize: 13)),
                    Text(_money(breakdown.platformFee), style: const TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13)),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Base Estimate'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 15)),
                Text('${breakdown.displayTotal} +', style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16, color: _accent(isDarkMode))),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'GST & other charges applicable based on chosen payment method.'.tr,
                      style: TextStyle(fontSize: 11.5, color: Colors.orange.shade800, fontFamily: AppThemeData.medium),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callExpert(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:${phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final accent = _accent(isDarkMode);

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
          onPressed: _cancelling
              ? null
              : () {
                  if (_booking != null && (_booking!.isAwaitingPayment || _booking!.needsPayment)) {
                    Get.off(() => ServiceCompletedPaymentScreen(bookingId: widget.bookingId));
                  } else {
                    Get.back();
                  }
                },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expert Assigned'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 17, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
            Text(
              'Your service expert is on the way'.tr,
              style: TextStyle(fontSize: 11, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500, fontFamily: AppThemeData.regular),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _booking == null
              ? _errorView(isDarkMode, accent)
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: _content(isDarkMode, accent, _booking!),
                        ),
                      ),
                    ),
                    if (_booking != null && _booking!.canBeCancelled)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: ButtonThem.buildBorderButton(
                          context,
                          title: _cancelling ? 'Cancelling...'.tr : 'Cancel Booking'.tr,
                          btnColor: Colors.white,
                          btnBorderColor: accent,
                          txtColor: accent,
                          onPress: _cancelling ? () {} : _cancelBooking,
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _errorView(bool isDarkMode, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppThemeData.grey400),
            const SizedBox(height: 12),
            Text(_error ?? 'Could not load booking details'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: Text('Retry'.tr)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Get.back(), child: Text('Go Back'.tr)),
          ],
        ),
      ),
    );
  }

  Widget _content(bool isDarkMode, Color accent, ServiceRequestData booking) {
    final driver = booking.driver;

    return Column(
      children: [
        _successBanner(isDarkMode),
        const SizedBox(height: 14),
        _expertCard(isDarkMode, accent, booking, driver),
        const SizedBox(height: 14),
        _otpCard(isDarkMode, accent, booking),
        const SizedBox(height: 14),
        _tripDetailsCard(isDarkMode, accent, booking, driver),
        const SizedBox(height: 14),
        _servicesCard(isDarkMode, accent, booking),
        const SizedBox(height: 14),
        _safetyBanner(isDarkMode),
        if (booking.isAwaitingPayment && !booking.isPaid) ...[
          const SizedBox(height: 20),
          ButtonThem.buildButton(
            context,
            title: 'Pay Now'.tr,
            btnColor: accent,
            radius: 12,
            onPress: () => Get.off(() => ServiceCompletedPaymentScreen(bookingId: widget.bookingId)),
          ),
        ],
      ],
    );
  }

  Widget _successBanner(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8E6C8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Color(0xFF22A45D), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expert Assigned Successfully!'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 14, color: Color(0xFF166534))),
                const SizedBox(height: 2),
                Text(
                  'Your expert is confirmed and on the way.'.tr,
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expertCard(bool isDarkMode, Color accent, ServiceRequestData booking, ServiceDriverInfo? driver) {
    final photoUrl = _driverPhotoUrl(driver?.photo);
    final phone = (driver?.phone ?? '').trim();
    final expertName = (driver?.name ?? '').trim().isNotEmpty
        ? driver!.name!
        : (booking.hasAssignedDriver ? '${'Service Expert'.tr} #${booking.driverId}' : 'Service Expert'.tr);

    return _card(
      isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _avatarPlaceholder(accent),
                          errorWidget: (_, __, ___) => _avatarPlaceholder(accent),
                        )
                      : _avatarPlaceholder(accent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expertName,
                      style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 16, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.green.shade600),
                        const SizedBox(width: 4),
                        Text(
                          driver?.ratingLabel ?? '4.8',
                          style: TextStyle(fontSize: 12.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      driver?.profession ?? 'Home Service Expert'.tr,
                      style: TextStyle(fontSize: 12.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver?.experience ?? '5+ Years Experience'.tr,
                      style: TextStyle(fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500),
                    ),
                  ],
                ),
              ),
              if (phone.isNotEmpty)
                Material(
                  color: const Color(0xFF22A45D),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _callExpert(phone),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.call_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppThemeData.primary50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_in_talk_rounded, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Expert Phone'.tr, style: TextStyle(fontSize: 11, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
                      Text(
                        phone.isNotEmpty ? phone : 'Phone not available'.tr,
                        style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                      ),
                    ],
                  ),
                ),
                if (phone.isNotEmpty)
                  TextButton(onPressed: () => _callExpert(phone), child: Text('Call'.tr)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpCard(bool isDarkMode, Color accent, ServiceRequestData booking) {
    final displayOtp = ServiceRequestData.displayServiceOtp(booking.otp);
    final isGenerating = displayOtp.length < 4 && !booking.isCompleted;

    return _card(
      isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              Text('Service Start OTP'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 15, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share this OTP with the expert when they arrive to start the service.'.tr,
            style: TextStyle(fontSize: 12.5, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (isGenerating)
            Row(
              children: [
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Text('Generating OTP...'.tr, style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayOtp,
                    style: TextStyle(
                      fontFamily: AppThemeData.bold,
                      fontSize: 32,
                      letterSpacing: 10,
                      color: accent,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayOtp));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP copied'.tr)));
                  },
                  icon: Icon(Icons.copy_rounded, color: accent),
                ),
              ],
            ),
            Text(
              'Do not share this OTP until the expert reaches your location.'.tr,
              style: TextStyle(fontSize: 11.5, color: Colors.orange.shade800),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(Color accent) {
    return Container(
      color: AppThemeData.primary50,
      child: Icon(Icons.person_rounded, size: 40, color: accent),
    );
  }

  Widget _tripDetailsCard(bool isDarkMode, Color accent, ServiceRequestData booking, ServiceDriverInfo? driver) {
    final eta = driver?.etaLabel ?? booking.preferredTime ?? '20 - 25 mins';
    final vehicle = (driver?.vehicleNumber ?? '').trim().isNotEmpty ? driver!.vehicleNumber! : '—';
    final address = booking.serviceAddress ?? booking.addressType ?? '—';

    return _card(
      isDarkMode,
      child: Column(
        children: [
          _detailTile(
            isDarkMode,
            accent,
            icon: Icons.schedule_rounded,
            label: 'Estimated Arrival Time'.tr,
            value: eta,
            valueColor: const Color(0xFF22A45D),
          ),
          const SizedBox(height: 14),
          _detailTile(isDarkMode, accent, icon: Icons.directions_car_filled_rounded, label: 'Vehicle Number'.tr, value: vehicle),
          const SizedBox(height: 14),
          _detailTile(isDarkMode, accent, icon: Icons.location_on_rounded, label: 'Service Location'.tr, value: address, multiline: true),
        ],
      ),
    );
  }

  Widget _detailTile(
    bool isDarkMode,
    Color accent, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppThemeData.primary50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: multiline ? 4 : 1,
                overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppThemeData.semiBold,
                  fontSize: 13.5,
                  color: valueColor ?? (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                  height: multiline ? 1.35 : 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _servicesCard(bool isDarkMode, Color accent, ServiceRequestData booking) {
    final items = booking.bookedServiceItems;
    final totalLabel = booking.displayPayableLabel;

    return _card(
      isDarkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Services Booked'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 15, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
          const SizedBox(height: 12),
          ...items.map((e) => _serviceRow(isDarkMode, accent, e)),
          if ((booking.priceBreakdown?.visitingCharge ?? 0) > 0)
            _serviceRow(
              isDarkMode,
              accent,
              ServicePriceLineItem(
                name: 'Visiting Charge'.tr,
                price: booking.priceBreakdown!.visitingCharge,
                minPrice: booking.priceBreakdown!.visitingCharge,
                maxPrice: booking.priceBreakdown!.visitingCharge,
                priceAvailable: true,
              ),
            ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Payable (Base)'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 14, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
                    const SizedBox(height: 2),
                    Text(
                      '+ GST & other charges applicable'.tr,
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontFamily: AppThemeData.medium),
                    ),
                    if (booking.priceBreakdown != null)
                      GestureDetector(
                        onTap: () => _showPriceBreakup(isDarkMode, booking),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'View Price Breakup'.tr,
                            style: TextStyle(fontSize: 12, color: accent, fontFamily: AppThemeData.semiBold, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '$totalLabel +',
                style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 20, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceRow(bool isDarkMode, Color accent, ServicePriceLineItem item) {
    final price = item.priceAvailable
        ? (item.maxPrice > item.minPrice && item.minPrice > 0
            ? '${Constant.currency ?? ''}${item.minPrice.toStringAsFixed(0)}-${Constant.currency ?? ''}${item.maxPrice.toStringAsFixed(0)}'
            : _money(item.minPrice))
        : (item.displayPrice.isNotEmpty ? item.displayPrice : '—');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppThemeData.primary50, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.home_repair_service_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
            ),
          ),
          Text(price, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900)),
        ],
      ),
    );
  }

  Widget _safetyBanner(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB8E6C8)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Background Verified Expert'.tr, style: const TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: Color(0xFF166534))),
                Text(
                  'Your safety is our priority.'.tr,
                  style: TextStyle(fontSize: 11.5, color: Colors.green.shade800.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
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
        boxShadow: isDarkMode ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
