import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:finway/utils/Preferences.dart';
import 'package:finway/utils/location_picker_helper.dart';
import 'service_confirm_booking_screen.dart';
import 'service_booking_mode.dart';
import 'service_style.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String serviceName;
  final String categoryName;
  final List<String> selectedServices;

  const ServiceRequestScreen({
    super.key,
    required this.serviceName,
    required this.categoryName,
    this.selectedServices = const [],
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  late final ServiceBookingMode _bookingMode;
  late final bool _requiresHomeVisit;

  double? _lat;
  double? _lng;
  String _addressType = 'Home';
  String _contactMethod = 'Online';
  String _bookingFrequency = 'Hourly';

  bool get _supportsFrequencySelection {
    final combined = "${widget.serviceName} ${widget.categoryName}".toLowerCase();
    return RegExp(r'\btutor\b|\btuition\b|\bnurs\b|\bphysio\b|\belderly\b|\bpatient care\b|\bmaid\b|\bcook\b|\bdriver\b|\bbabysitter\b|\bteacher\b').hasMatch(combined);
  }

  @override
  void initState() {
    super.initState();
    _bookingMode = bookingModeFor(serviceName: widget.serviceName, categoryName: widget.categoryName);
    _requiresHomeVisit = _bookingMode == ServiceBookingMode.homeVisit;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final picked = await LocationPickerHelper.showPickerSheet(context);
    if (picked != null && mounted) {
      setState(() {
        _lat = picked.latitude;
        _lng = picked.longitude;
        _addressController.text = picked.address;
      });
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (Preferences.getInt(Preferences.userId) == 0) {
      ShowToastDialog.showToast("Please login to book a service".tr);
      return;
    }
    if (_requiresHomeVisit && (_addressController.text.isEmpty || _lat == null)) {
      ShowToastDialog.showToast("Please select your service address".tr);
      return;
    }

    final fullDescription = _supportsFrequencySelection
        ? "[Plan: $_bookingFrequency]\n${_descriptionController.text}"
        : _descriptionController.text;

    Get.to(() => ServiceConfirmBookingScreen(
          draft: ServiceBookingDraft(
            serviceName: widget.serviceName,
            categoryName: widget.categoryName,
            selectedServices: widget.selectedServices,
            addressType: _requiresHomeVisit ? _addressType : _contactMethod,
            serviceAddress: _requiresHomeVisit ? _addressController.text.trim() : '',
            lat: _requiresHomeVisit ? (_lat?.toString() ?? '') : '',
            lng: _requiresHomeVisit ? (_lng?.toString() ?? '') : '',
            description: fullDescription,
            bookingFrequency: _bookingFrequency,
            bookingMode: _requiresHomeVisit ? 'home_visit' : 'remote',
            requiresHomeVisit: _requiresHomeVisit,
          ),
        ));
  }

  Widget _sectionTitle(String text, bool isDarkMode) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppThemeData.semiBold,
        fontSize: 13,
        color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDarkMode = themeChange.getThem();
    final style = categoryStyleFor(widget.categoryName);

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Request Service".tr,
          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: 18, color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(leafIconFor(widget.serviceName, fallback: style.icon), color: style.color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanServiceName(widget.serviceName).tr,
                          style: TextStyle(fontFamily: AppThemeData.bold, fontSize: widget.serviceName.contains('\n') ? 13 : 16, color: style.color),
                          maxLines: widget.serviceName.contains('\n') ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _requiresHomeVisit
                              ? "A professional will visit your location".tr
                              : "This service can be done online — no address needed".tr,
                          style: TextStyle(
                            fontFamily: AppThemeData.regular,
                            fontSize: 11.5,
                            color: style.color.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_requiresHomeVisit) ...[
              _sectionTitle("Service Address".tr, isDarkMode),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickAddress,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: AppThemeData.primary200, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _addressController.text.isEmpty ? "Tap to use GPS or search address".tr : _addressController.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppThemeData.regular,
                                  fontSize: 13,
                                  color: _addressController.text.isEmpty ? Colors.grey : (isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () async {
                        final picked = await LocationPickerHelper.fetchCurrentLocation();
                        if (picked != null && mounted) {
                          setState(() {
                            _lat = picked.latitude;
                            _lng = picked.longitude;
                            _addressController.text = picked.address;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.my_location_rounded, color: AppThemeData.primary200, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: ['Home', 'Work', 'Other'].map((type) {
                  final selected = _addressType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type.tr),
                      selected: selected,
                      onSelected: (_) => setState(() => _addressType = type),
                      selectedColor: style.color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              _sectionTitle("How would you like to connect?".tr, isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Online', 'Video Call', 'Phone Call'].map((method) {
                  final selected = _contactMethod == method;
                  return ChoiceChip(
                    label: Text(method.tr),
                    selected: selected,
                    onSelected: (_) => setState(() => _contactMethod = method),
                    selectedColor: style.color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            if (_supportsFrequencySelection) ...[
              const SizedBox(height: 20),
              _sectionTitle("Booking Plan / Duration".tr, isDarkMode),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Hourly', 'Daily', 'Monthly', 'Yearly / Course'].map((freq) {
                  final selected = _bookingFrequency == freq;
                  return ChoiceChip(
                    label: Text(freq.tr),
                    selected: selected,
                    onSelected: (_) => setState(() => _bookingFrequency = freq),
                    selectedColor: style.color.withValues(alpha: 0.15),
                    labelStyle: TextStyle(color: selected ? style.color : Colors.grey, fontFamily: AppThemeData.medium, fontSize: 12),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle("Remarks (Optional)".tr, isDarkMode),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900),
                decoration: InputDecoration(
                  hintText: _requiresHomeVisit
                      ? "Any specific requirements for the visit...".tr
                      : "Share topic, goals, or how to reach you...".tr,
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ButtonThem.buildButton(
              context,
              title: "Continue".tr,
              btnColor: style.color,
              radius: 10,
              onPress: _submit,
            ),
            const SizedBox(height: 20),
            _buildTermsCard(isDarkMode, style.color),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(bool isDarkMode, Color accentColor) {
    final terms = [
      {
        'title': 'Final Price:'.tr,
        'desc': 'After booking acceptance, pay the final price shown in the app.'.tr,
      },
      {
        'title': 'Booked Service Only:'.tr,
        'desc': 'The booking covers only the selected service.'.tr,
      },
      {
        'title': 'Extra Work:'.tr,
        'desc': 'Any additional work requires a new booking.'.tr,
      },
      {
        'title': 'No Unauthorised Work:'.tr,
        'desc': 'Extra work cannot be added to the existing booking.'.tr,
      },
      {
        'title': 'Complaint & Penalty:'.tr,
        'desc': 'Valid complaints about unauthorised extra work may result in a penalty.'.tr,
      },
    ];

    final titleColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final descColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF334155);
    final circleBg = isDarkMode ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final circleTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppThemeData.grey100Dark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.shield_outlined, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                'Booking & Service Terms'.tr,
                style: TextStyle(
                  fontFamily: AppThemeData.bold,
                  fontSize: 14.5,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(terms.length, (index) {
            final item = terms[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: AppThemeData.bold,
                        fontSize: 11.5,
                        color: circleTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${item['title']} ',
                            style: TextStyle(
                              fontFamily: AppThemeData.bold,
                              fontSize: 12.5,
                              color: titleColor,
                            ),
                          ),
                          TextSpan(
                            text: item['desc'],
                            style: TextStyle(
                              fontFamily: AppThemeData.regular,
                              fontSize: 12.5,
                              height: 1.4,
                              color: descColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
