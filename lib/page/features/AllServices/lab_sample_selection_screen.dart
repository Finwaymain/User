import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'service_request_screen.dart';

class LabTestItem {
  final String id;
  final String title;
  final String description;
  final String icon;

  LabTestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class LabSampleSelectionScreen extends StatefulWidget {
  final String categoryName;

  const LabSampleSelectionScreen({
    super.key,
    this.categoryName = 'Lab Sample Collection',
  });

  @override
  State<LabSampleSelectionScreen> createState() => _LabSampleSelectionScreenState();
}

class _LabSampleSelectionScreenState extends State<LabSampleSelectionScreen> {
  final List<LabTestItem> _availableTests = [
    LabTestItem(
      id: 'cbc',
      title: 'Complete Blood Count (CBC)',
      description: 'Checks overall health, infection & anemia indicators',
      icon: '🩸',
    ),
    LabTestItem(
      id: 'sugar_hba1c',
      title: 'Blood Sugar & HbA1c',
      description: 'Fasting, PP sugar and 3-month average blood glucose',
      icon: '🍬',
    ),
    LabTestItem(
      id: 'thyroid',
      title: 'Thyroid Profile (T3, T4, TSH)',
      description: 'Evaluates thyroid hormone levels and metabolism',
      icon: '🦋',
    ),
    LabTestItem(
      id: 'lipid',
      title: 'Lipid Profile (Heart Risk)',
      description: 'Cholesterol, HDL, LDL, and Triglycerides check',
      icon: '❤️',
    ),
    LabTestItem(
      id: 'lft_kft',
      title: 'Liver & Kidney Profile (LFT / KFT)',
      description: 'Creatinine, Urea, Bilirubin & SGPT liver enzymes',
      icon: '🏥',
    ),
    LabTestItem(
      id: 'vitamins',
      title: 'Vitamin D & Vitamin B12 Test',
      description: 'Checks essential bone & nerve vitamin deficiencies',
      icon: '☀️',
    ),
    LabTestItem(
      id: 'urine_stool',
      title: 'Routine Urine & Stool Examination',
      description: 'Screening for infection, protein & digestive health',
      icon: '🧪',
    ),
    LabTestItem(
      id: 'fever_panel',
      title: 'Fever Panel (COVID, Dengue, Malaria, Typhoid)',
      description: 'Rapid diagnostic screening for viral & bacterial fevers',
      icon: '🤒',
    ),
    LabTestItem(
      id: 'full_body',
      title: 'Full Body Health Checkup Package',
      description: 'Comprehensive 60+ parameters essential health suite',
      icon: '🔬',
    ),
    LabTestItem(
      id: 'express_blood',
      title: 'Express Home Blood Sample Collection (1 Hr)',
      description: 'Urgent technician arrival for instant blood draw at home',
      icon: '⚡',
    ),
  ];

  final Set<String> _selectedTestIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedTestIds.contains(id)) {
        _selectedTestIds.remove(id);
      } else {
        _selectedTestIds.add(id);
      }
    });
  }

  void _proceedToBooking() {
    if (_selectedTestIds.isEmpty) {
      Get.snackbar(
        "Select Tests".tr,
        "Please select at least one lab test to proceed.".tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber,
        colorText: Colors.black,
      );
      return;
    }

    final selectedTitles = _availableTests
        .where((item) => _selectedTestIds.contains(item.id))
        .map((item) => item.title)
        .toList();

    final summaryDescription = "Selected Lab Tests (${selectedTitles.length}):\n• " +
        selectedTitles.join("\n• ");

    Get.to(() => ServiceRequestScreen(
          serviceName: summaryDescription,
          categoryName: widget.categoryName,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<DarkThemeProvider>(context).getThem();

    return Scaffold(
      backgroundColor: isDarkMode ? AppThemeData.surface50Dark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode ? AppThemeData.grey900Dark : Colors.black),
        title: Text(
          "Lab Sample Collection".tr,
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
            color: isDarkMode ? AppThemeData.grey100Dark : AppThemeData.primary200.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Text("🧪", style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Lab Tests at Home".tr,
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 15,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.primary200,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Tap multiple tests below for home sample collection".tr,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _availableTests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _availableTests[index];
                final isSelected = _selectedTestIds.contains(item.id);

                return InkWell(
                  onTap: () => _toggleSelection(item.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppThemeData.primary200.withValues(alpha: 0.12)
                          : (isDarkMode ? AppThemeData.grey100Dark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppThemeData.primary200
                            : Colors.grey.withValues(alpha: 0.2),
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
                              const SizedBox(height: 3),
                              Text(
                                item.description.tr,
                                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          activeColor: AppThemeData.primary200,
                          onChanged: (_) => _toggleSelection(item.id),
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
                        "${_selectedTestIds.length} ${"Tests Selected".tr}",
                        style: TextStyle(
                          fontFamily: AppThemeData.bold,
                          fontSize: 15,
                          color: isDarkMode ? AppThemeData.grey900Dark : AppThemeData.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedTestIds.isEmpty ? "Tap tests to select".tr : "Ready for home collection".tr,
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
                    btnColor: AppThemeData.primary200,
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
