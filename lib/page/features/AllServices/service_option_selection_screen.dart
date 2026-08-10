import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/controller/all_services_controller.dart';
import 'package:finway/model/service_category_model.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_flow.dart';
import 'service_request_screen.dart';
import 'service_style.dart';

class ServiceOptionItem {
  final String id;
  final String title;
  final String description;
  final String icon;

  const ServiceOptionItem({
    required this.id,
    required this.title,
    this.description = '',
    this.icon = '✓',
  });

  factory ServiceOptionItem.fromCategory(ServiceCategoryData data) {
    return ServiceOptionItem(
      id: (data.id ?? data.libelle ?? '').toString(),
      title: cleanServiceName(data.libelle),
      description: '',
      icon: _iconFor(cleanServiceName(data.libelle)),
    );
  }

  static String _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('physician') || lower.contains('doctor')) return '🩺';
    if (lower.contains('pediatric') || lower.contains('child')) return '👶';
    if (lower.contains('elderly') || lower.contains('geriatric')) return '🧓';
    if (lower.contains('women')) return '👩‍⚕️';
    if (lower.contains('heart') || lower.contains('bp')) return '❤️';
    if (lower.contains('diabetes')) return '🍬';
    if (lower.contains('physio') || lower.contains('rehab')) return '🦴';
    if (lower.contains('nurse') || lower.contains('injection')) return '💉';
    if (lower.contains('tutor') || lower.contains('tuition')) return '📚';
    if (lower.contains('jee') || lower.contains('neet')) return '🎯';
    return '✓';
  }
}

class ServiceOptionSelectionScreen extends StatefulWidget {
  final int? categoryId;
  final String serviceName;
  final String parentCategoryName;
  final ServiceSelectionMode mode;
  final AllServicesController controller;

  const ServiceOptionSelectionScreen({
    super.key,
    this.categoryId,
    required this.serviceName,
    required this.parentCategoryName,
    required this.mode,
    required this.controller,
  });

  @override
  State<ServiceOptionSelectionScreen> createState() => _ServiceOptionSelectionScreenState();
}

class _ServiceOptionSelectionScreenState extends State<ServiceOptionSelectionScreen> {
  bool _isLoading = true;
  List<ServiceOptionItem> _options = [];
  final Set<String> _selectedIds = {};
  String? _singleSelectedId;

  bool get _isMulti => widget.mode == ServiceSelectionMode.multi;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final clean = cleanServiceName(widget.serviceName);
    if (selectionModeForName(clean) == ServiceSelectionMode.multi) {
      final children = await widget.controller.fetchSelectionOptions(
        categoryId: widget.categoryId,
        categoryName: widget.serviceName,
      );
      setState(() {
        _options = children.isNotEmpty
            ? children.map(ServiceOptionItem.fromCategory).where((e) => e.title.isNotEmpty).toList()
            : widget.controller.labTestOptions();
        _isLoading = false;
      });
      return;
    }

    final children = await widget.controller.fetchSelectionOptions(
      categoryId: widget.categoryId,
      categoryName: widget.serviceName,
    );

    setState(() {
      _options = children.map(ServiceOptionItem.fromCategory).where((e) => e.title.isNotEmpty).toList();
      _isLoading = false;
    });
  }

  void _toggleMulti(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectSingle(String id) {
    setState(() => _singleSelectedId = id);
  }

  void _proceedToBooking() {
    if (_isMulti) {
      if (_selectedIds.isEmpty) {
        Get.snackbar(
          "Select Options".tr,
          "Please select at least one option to proceed.".tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber,
          colorText: Colors.black,
        );
        return;
      }

      final selectedTitles = _options.where((item) => _selectedIds.contains(item.id)).map((e) => e.title).toList();
      final summary = "Selected ${cleanServiceName(widget.serviceName)} (${selectedTitles.length}):\n• ${selectedTitles.join('\n• ')}";

      Get.to(() => ServiceRequestScreen(
            serviceName: summary,
            categoryName: cleanServiceName(widget.parentCategoryName),
            selectedServices: selectedTitles,
          ));
      return;
    }

    if (_singleSelectedId == null) {
      Get.snackbar(
        "Select Option".tr,
        "Please choose one option to continue.".tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
        colorText: Colors.black,
      );
      return;
    }

    final selected = _options.firstWhere((e) => e.id == _singleSelectedId);
    Get.to(() => ServiceRequestScreen(
          serviceName: selected.title,
          categoryName: cleanServiceName(widget.serviceName),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();
    final style = categoryStyleFor(widget.parentCategoryName);
    final title = cleanServiceName(widget.serviceName);
    final selectedCount = _isMulti ? _selectedIds.length : (_singleSelectedId == null ? 0 : 1);

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          title.tr,
          style: TextStyle(
            fontFamily: AppThemeData.bold,
            fontSize: 17,
            color: isDarkMode ? AppThemeData.grey900Dark : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? AppThemeData.grey100Dark : style.bg,
            child: Row(
              children: [
                Text(_isMulti ? '🧪' : '🩺', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isMulti ? "Select Lab Tests at Home".tr : "Choose Service Type".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 15,
                          color: isDarkMode ? AppThemeData.grey900Dark : style.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isMulti
                            ? "You can select multiple tests for one home visit".tr
                            : "Select one option — a single appointment will be booked".tr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _options.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("No options available".tr, style: TextStyle(color: AppThemeData.grey500)),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Get.to(() => ServiceRequestScreen(
                                      serviceName: title,
                                      categoryName: cleanServiceName(widget.parentCategoryName),
                                    )),
                                child: Text("Book directly".tr),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _options.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _options[index];
                          final isSelected = _isMulti ? _selectedIds.contains(item.id) : _singleSelectedId == item.id;

                          return InkWell(
                            onTap: () => _isMulti ? _toggleMulti(item.id) : _selectSingle(item.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? style.color.withValues(alpha: 0.12)
                                    : (isDarkMode ? AppThemeData.grey100Dark : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? style.color : Colors.grey.withValues(alpha: 0.2),
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(item.icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title.tr,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.bold,
                                            fontSize: 14,
                                            color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                                          ),
                                        ),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(item.description.tr, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (_isMulti)
                                    Checkbox(
                                      value: isSelected,
                                      activeColor: style.color,
                                      onChanged: (_) => _toggleMulti(item.id),
                                    )
                                  else
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? style.color : Colors.grey,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isMulti ? "$selectedCount ${"Selected".tr}" : (selectedCount == 1 ? "1 ${"Selected".tr}" : "None selected".tr),
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 15,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedCount == 0
                            ? (_isMulti ? "Tap to select tests".tr : "Tap one option".tr)
                            : "Continue to booking form".tr,
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: ButtonThem.buildButton(
                    context,
                    title: "Proceed to Booking".tr,
                    btnColor: style.color,
                    txtColor: Colors.white,
                    radius: 10,
                    onPress: _proceedToBooking,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
