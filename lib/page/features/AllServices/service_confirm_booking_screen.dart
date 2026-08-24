import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/controller/service_booking_controller.dart';
import 'package:finway/model/service_price_estimate_model.dart';
import 'package:finway/model/user_model.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/utils/location_picker_helper.dart';
import 'service_finding_expert_screen.dart';
import 'service_style.dart';

class ServiceBookingDraft {
  final String serviceName;
  final String categoryName;
  final List<String> selectedServices;
  final String addressType;
  final String serviceAddress;
  final String lat;
  final String lng;
  final String description;
  final String bookingFrequency;
  final String bookingMode;
  final bool requiresHomeVisit;

  const ServiceBookingDraft({
    required this.serviceName,
    required this.categoryName,
    this.selectedServices = const [],
    required this.addressType,
    required this.serviceAddress,
    required this.lat,
    required this.lng,
    required this.description,
    required this.bookingFrequency,
    required this.bookingMode,
    required this.requiresHomeVisit,
  });
}

class _DateOption {
  final DateTime date;
  final String topLabel;
  final String bottomLabel;

  _DateOption({required this.date, required this.topLabel, required this.bottomLabel});
}

class _TimeSlot {
  final int startHour;
  final int endHour;

  const _TimeSlot({required this.startHour, required this.endHour});

  String get id => '${startHour}_$endHour';

  String get title {
    return '${_formatHour(startHour)} - ${_formatHour(endHour)}';
  }

  static String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }
}

class ServiceConfirmBookingScreen extends StatefulWidget {
  final ServiceBookingDraft draft;

  const ServiceConfirmBookingScreen({super.key, required this.draft});

  @override
  State<ServiceConfirmBookingScreen> createState() => _ServiceConfirmBookingScreenState();
}

class _ServiceConfirmBookingScreenState extends State<ServiceConfirmBookingScreen> {
  final _controller = Get.put(ServiceBookingController(), tag: 'confirm_${DateTime.now().millisecondsSinceEpoch}');
  final _orderNoteController = TextEditingController();

  ServicePriceEstimate? _estimate;
  bool _loading = true;
  bool _booking = false;
  bool _veryUrgent = false;

  late List<_DateOption> _dateOptions;
 int _selectedDateIndex = 0;
  String? _selectedTimeSlotId;
  List<_TimeSlot> _availableTimeSlots = [];

  late String _address;
  late String _lat;
  late String _lng;
  late String _contactPhone;

  static const _timeSlots = [
    _TimeSlot(startHour: 8, endHour: 10),
    _TimeSlot(startHour: 10, endHour: 12),
    _TimeSlot(startHour: 12, endHour: 14),
    _TimeSlot(startHour: 14, endHour: 16),
    _TimeSlot(startHour: 16, endHour: 18),
    _TimeSlot(startHour: 18, endHour: 20),
  ];

  List<_TimeSlot> _slotsForDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    return _timeSlots.where((slot) {
      if (!isToday) return true;
      final slotEnd = DateTime(date.year, date.month, date.day, slot.endHour);
      return slotEnd.isAfter(now);
    }).toList();
  }

  void _refreshTimeSlots({bool resetSelection = false}) {
    if (_dateOptions.isEmpty) {
      _availableTimeSlots = _timeSlots;
      _selectedTimeSlotId = _timeSlots.first.id;
      return;
    }
    final date = _dateOptions[_selectedDateIndex].date;
    final slots = _slotsForDate(date);
    _availableTimeSlots = slots.isNotEmpty ? slots : _timeSlots;
    if (resetSelection || _selectedTimeSlotId == null || !_availableTimeSlots.any((s) => s.id == _selectedTimeSlotId)) {
      _selectedTimeSlotId = _availableTimeSlots.first.id;
    }
  }

  Color _accent(bool isDarkMode) => isDarkMode ? AppThemeData.primary300Dark : AppThemeData.primary200;

  Color _pageBg(bool isDarkMode) => isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA);

  Color _cardBg(bool isDarkMode) => isDarkMode ? AppThemeData.grey100Dark : Colors.white;

  Color _titleColor(bool isDarkMode) => isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900;

  Color _mutedColor(bool isDarkMode) => isDarkMode ? AppThemeData.grey500Dark : AppThemeData.grey500;

  Color _chipBg(bool isDarkMode, bool selected) {
    if (selected) return _accent(isDarkMode).withValues(alpha: 0.1);
    return isDarkMode ? AppThemeData.grey200Dark : const Color(0xFFF7F8FC);
  }

  @override
  void initState() {
    super.initState();
    _address = widget.draft.serviceAddress;
    _lat = widget.draft.lat;
    _lng = widget.draft.lng;
    _contactPhone = _readUserPhone();
    _dateOptions = _buildDateOptions();
    _refreshTimeSlots(resetSelection: true);
    _loadEstimate();
  }

  @override
  void dispose() {
    _orderNoteController.dispose();
    super.dispose();
  }

  String _readUserPhone() {
    try {
      final userJson = Preferences.getString(Preferences.user);
      if (userJson.isEmpty) return '';
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      if (map['data'] != null) {
        final userModel = UserModel.fromJson(map);
        return userModel.data?.phone ?? userModel.data?.alternatePhone ?? '';
      }
      final user = User.fromJson(map);
      return user.phone ?? user.alternatePhone ?? '';
    } catch (_) {
      return '';
    }
  }

  List<_DateOption> _buildDateOptions() {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final List<_DateOption> validOptions = [];

    // Check next 10 days and add dates with available slots
    for (int i = 0; validOptions.length < 4 && i < 10; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day + i,
      );

      final slots = _slotsForDate(date);
      if (slots.isEmpty) continue;

      final isToday = i == 0;
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final isTomorrow = date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day;

      String topLabel;
      if (isToday) {
        topLabel = 'Today';
      } else if (isTomorrow) {
        topLabel = 'Tomorrow';
      } else {
        topLabel = '${date.day} ${monthNames[date.month - 1]}';
      }

      validOptions.add(
        _DateOption(
          date: date,
          topLabel: topLabel,
          bottomLabel: '${date.day} ${monthNames[date.month - 1]}',
        ),
      );
    }

    if (validOptions.isEmpty) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      validOptions.add(
        _DateOption(
          date: tomorrow,
          topLabel: 'Tomorrow',
          bottomLabel: '${tomorrow.day} ${monthNames[tomorrow.month - 1]}',
        ),
      );
    }

    return validOptions;
  }

  bool get _hasSelectedSubServices => widget.draft.selectedServices.isNotEmpty;

  Future<void> _loadEstimate() async {
    final estimate = await _controller.fetchPriceEstimate(
      serviceName: widget.draft.serviceName,
      serviceNames: widget.draft.selectedServices.isNotEmpty ? widget.draft.selectedServices : [widget.draft.serviceName],
      lat: _lat,
      lng: _lng,
    );
    if (mounted) {
      setState(() {
        _estimate = estimate;
        _loading = false;
      });
    }
  }

  String get _selectedDateStr {
    final d = _dateOptions[_selectedDateIndex].date;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String get _selectedTimeLabel {
    for (final slot in _availableTimeSlots) {
      if (slot.id == _selectedTimeSlotId) return slot.title;
    }
    return 'Select time slot'.tr;
  }

  Future<void> _changeAddress() async {
    final picked = await LocationPickerHelper.showPickerSheet(context);
    if (picked != null && mounted) {
      setState(() {
        _address = picked.address;
        _lat = picked.latitude.toString();
        _lng = picked.longitude.toString();
        _loading = true;
      });
      await _loadEstimate();
    }
  }

  void _showPriceBreakup(bool isDarkMode) {
    if (_estimate == null) return;
    final pricedItems = _buildDisplayItems();
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg(isDarkMode),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Breakup'.tr, style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: _titleColor(isDarkMode))),
            const SizedBox(height: 12),
            ...pricedItems.map((e) => _breakupRow(
                  isDarkMode,
                  e.name,
                  e.displayPrice.isNotEmpty && e.displayPrice != 'Rate on visit' ? e.displayPrice : (_estimate!.displayTotal),
                )),
            if (_estimate!.displayVisitingCharge.isNotEmpty)
              _breakupRow(isDarkMode, 'Visiting Charge'.tr, _estimate!.displayVisitingCharge),
            if (_estimate!.providersNearby > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_estimate!.providersNearby} nearby providers'.tr,
                  style: TextStyle(fontSize: 12, color: _mutedColor(isDarkMode)),
                ),
              ),
            const Divider(height: 24),
            _breakupRow(
              isDarkMode,
              'Total Payable'.tr,
              _estimate!.displayTotal,
              bold: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _breakupRow(bool isDarkMode, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: bold ? AppThemeData.semiBold : AppThemeData.regular,
                fontSize: 14,
                color: _titleColor(isDarkMode),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: bold ? AppThemeData.bold : AppThemeData.semiBold,
              fontSize: 14,
              color: bold ? _accent(isDarkMode) : _titleColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(Color btnColor) async {
    if (_estimate == null) return;
    if (_selectedTimeSlotId == null) {
      Get.snackbar('Time Required'.tr, 'Please select an available time slot.'.tr);
      return;
    }
    setState(() => _booking = true);

    final note = _orderNoteController.text.trim();
    var description = widget.draft.description;
    if (note.isNotEmpty) description = '$description\n[Order Note] $note';
    if (_veryUrgent) description = '[VERY URGENT]\n$description';

    final bookingId = await _controller.bookService({
      'service_name': widget.draft.serviceName,
      'address_type': widget.draft.addressType,
      'service_address': _address,
      'lat': _lat,
      'lng': _lng,
      'date': _selectedDateStr,
      'time': _selectedTimeLabel,
      'description': description,
      'booking_frequency': widget.draft.bookingFrequency,
      'booking_mode': widget.draft.bookingMode,
      'amount': _estimate!.totalMin > 0 ? _estimate!.totalMin : _estimate!.payableAmountFor(includeServicePrices: true),
      'price_breakdown': _estimate!.toBreakdownJson(),
    });

    if (!mounted) return;
    setState(() => _booking = false);

    if (bookingId != null) {
      Get.off(() => ServiceFindingExpertScreen(bookingId: bookingId));
    }
  }

  List<ServicePriceLineItem> _buildDisplayItems() {
    if (_estimate == null) return const [];
    final names = _hasSelectedSubServices && widget.draft.selectedServices.isNotEmpty
        ? widget.draft.selectedServices
        : [cleanServiceName(widget.draft.serviceName)];
    final matched = _estimate!.lineItemsForSelection(names);
    if (matched.isNotEmpty) return matched;
    if (_estimate!.serviceItems.isNotEmpty) return _estimate!.serviceItems;

    return [
      ServicePriceLineItem(
        name: cleanServiceName(widget.draft.serviceName),
        price: _estimate!.totalMin,
        minPrice: _estimate!.totalMin,
        maxPrice: _estimate!.totalMax,
        priceAvailable: _estimate!.totalMin > 0 || _estimate!.totalMax > 0,
        priceLabel: _estimate!.displayTotal,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final style = categoryStyleFor(widget.draft.categoryName);
    final accent = _accent(isDarkMode);
    final items = _buildDisplayItems();
    final serviceCount = items.isEmpty ? 1 : items.length;
    final payableTotal = _estimate?.displayTotal ?? 'Rate on visit'.tr;

    return Scaffold(
      backgroundColor: _pageBg(isDarkMode),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: _titleColor(isDarkMode)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Booking'.tr,
              style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: _titleColor(isDarkMode)),
            ),
            Text(
              'Please confirm your booking details'.tr,
              style: TextStyle(fontSize: 11.5, color: _mutedColor(isDarkMode), fontFamily: AppThemeData.regular),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      children: [
                        _card(
                          isDarkMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(isDarkMode, Icons.home_repair_service_outlined, 'Selected Services'.tr),
                              const SizedBox(height: 12),
                              ...items.map((e) => _serviceRow(
                                    isDarkMode,
                                    e.name,
                                    widget.draft.categoryName,
                                    e.displayPrice.isNotEmpty && e.displayPrice != 'Rate on visit' ? e.displayPrice : (_estimate?.displayTotal ?? 'Rate on visit'.tr),
                                    style,
                                  )),
                              if (_estimate != null && _estimate!.displayVisitingCharge.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _serviceRow(isDarkMode, 'Visiting Charge'.tr, 'Nearby providers'.tr, _estimate!.displayVisitingCharge, style, icon: Icons.directions_walk_rounded),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Total $serviceCount ${serviceCount == 1 ? 'Service' : 'Services'}'.tr,
                                    style: TextStyle(fontSize: 13, color: _mutedColor(isDarkMode)),
                                  ),
                                  const Spacer(),
                                  Text(
                                    payableTotal,
                                    style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 15, color: accent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          isDarkMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(isDarkMode, Icons.calendar_month_outlined, 'Select Date & Time'.tr),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _dateOptions.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final opt = _dateOptions[index];
                                    final selected = _selectedDateIndex == index;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedDateIndex = index;
                                        _refreshTimeSlots(resetSelection: true);
                                      }),
                                      child: Container(
                                        width: 78,
                                        decoration: BoxDecoration(
                                          color: _chipBg(isDarkMode, selected),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selected ? accent : Colors.grey.withValues(alpha: 0.25),
                                            width: selected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              opt.topLabel,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: AppThemeData.semiBold,
                                                color: selected ? accent : _titleColor(isDarkMode),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(opt.bottomLabel, style: TextStyle(fontSize: 11, color: _mutedColor(isDarkMode))),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (_availableTimeSlots.isEmpty)
                                Text(
                                  'No slots available for this date. Please choose another day.'.tr,
                                  style: TextStyle(fontSize: 12, color: _mutedColor(isDarkMode)),
                                )
                              else
                                ..._availableTimeSlots.map((slot) {
                                  final selected = _selectedTimeSlotId == slot.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedTimeSlotId = slot.id),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _chipBg(isDarkMode, selected),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: selected ? accent : Colors.grey.withValues(alpha: 0.25),
                                            width: selected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                slot.title,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.semiBold,
                                                  fontSize: 13,
                                                  color: selected ? accent : _titleColor(isDarkMode),
                                                ),
                                              ),
                                            ),
                                            if (selected) Icon(Icons.check_circle, color: accent, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          isDarkMode,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppThemeData.primary50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.bolt_rounded, color: accent, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Very Urgent Service'.tr,
                                      style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: _titleColor(isDarkMode)),
                                    ),
                                    Text(
                                      'Need immediate service? Enable urgent mode.'.tr,
                                      style: TextStyle(fontSize: 11.5, color: _mutedColor(isDarkMode)),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _veryUrgent,
                                activeTrackColor: accent.withValues(alpha: 0.35),
                                activeThumbColor: accent,
                                onChanged: (v) => setState(() => _veryUrgent = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _card(
                          isDarkMode,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionHeader(isDarkMode, Icons.receipt_long_outlined, 'Booking Details'.tr),
                              const SizedBox(height: 10),
                              _detailRow(
                                isDarkMode: isDarkMode,
                                icon: Icons.location_on_outlined,
                                label: 'Service Location'.tr,
                                value: _address.isEmpty ? 'Add address'.tr : _address,
                                onChange: widget.draft.requiresHomeVisit ? _changeAddress : null,
                              ),
                              const SizedBox(height: 10),
                              _detailRow(
                                isDarkMode: isDarkMode,
                                icon: Icons.phone_outlined,
                                label: 'Contact Number'.tr,
                                value: _contactPhone.isNotEmpty ? _contactPhone : 'Your registered number'.tr,
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _orderNoteController,
                                maxLines: 2,
                                style: TextStyle(color: _titleColor(isDarkMode), fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Order Note (Optional)'.tr,
                                  labelStyle: TextStyle(color: _mutedColor(isDarkMode)),
                                  hintText: 'Add any special instructions...'.tr,
                                  hintStyle: TextStyle(color: _mutedColor(isDarkMode), fontSize: 12),
                                  filled: true,
                                  fillColor: isDarkMode ? AppThemeData.grey200Dark : const Color(0xFFF7F8FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: accent, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
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
                  decoration: BoxDecoration(
                    color: _cardBg(isDarkMode),
                    border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Payable'.tr, style: TextStyle(fontSize: 12, color: _mutedColor(isDarkMode))),
                              Text(
                                payableTotal,
                                style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 20, color: _titleColor(isDarkMode)),
                              ),
                              GestureDetector(
                                onTap: () => _showPriceBreakup(isDarkMode),
                                child: Text(
                                  'View Price Breakup'.tr,
                                  style: TextStyle(fontSize: 12, color: accent, fontFamily: AppThemeData.semiBold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ButtonThem.buildButton(
                            context,
                            title: _booking ? 'Booking...'.tr : 'Confirm & Book'.tr,
                            btnColor: style.color,
                            radius: 10,
                            onPress: _booking ? () {} : () => _confirmBooking(style.color),
                          ),
                        ),
                      ],
                    ),
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
        color: _cardBg(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(bool isDarkMode, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accent(isDarkMode)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 14, color: _titleColor(isDarkMode))),
      ],
    );
  }

  Widget _serviceRow(bool isDarkMode, String title, String subtitle, String price, ServiceCategoryStyle style, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon ?? style.icon, color: style.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 13, color: _titleColor(isDarkMode)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(subtitle, style: TextStyle(fontSize: 11, color: _mutedColor(isDarkMode)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 13, color: _accent(isDarkMode)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onChange,
  }) {
    final accent = _accent(isDarkMode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: _mutedColor(isDarkMode))),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 13, fontFamily: AppThemeData.medium, color: _titleColor(isDarkMode)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onChange != null)
          TextButton(
            onPressed: onChange,
            child: Text('Change'.tr, style: TextStyle(color: accent, fontFamily: AppThemeData.semiBold)),
          ),
      ],
    );
  }
}
