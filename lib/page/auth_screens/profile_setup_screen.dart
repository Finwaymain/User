// ignore_for_file: must_be_immutable
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/auth_screens/email_entry_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Step 3 of signup — collect first name and last name.
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final controller = Get.find<AuthOtpController>();

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey50;
    final hintColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;
    final borderColor = isDark ? AppThemeData.grey200Dark : AppThemeData.grey200;
    final inputBg = isDark ? AppThemeData.grey100Dark : AppThemeData.primary50;

    InputDecoration inputDecoration(String label, String hint, IconData icon) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular),
        prefixIcon: Icon(icon, color: hintColor, size: 20),
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppThemeData.primary200, width: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: labelColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Progress indicator
              _buildProgress(step: 3),
              const SizedBox(height: 28),

              Text(
                'What\'s your name?'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will be shown on your ride profile.'.tr,
                style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
              ),

              const SizedBox(height: 36),

              // First name
              TextField(
                controller: controller.firstNameController.value,
                style: TextStyle(color: labelColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.words,
                decoration: inputDecoration('First name'.tr, 'e.g. Rahul', Icons.person_outline_rounded),
              ),

              const SizedBox(height: 16),

              // Last name
              TextField(
                controller: controller.lastNameController.value,
                style: TextStyle(color: labelColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.words,
                decoration: inputDecoration('Last name'.tr, 'e.g. Sharma', Icons.person_outline_rounded),
              ),

              const Spacer(),

              Obx(() => ButtonThem.buildButton(
                    context,
                    title: controller.isLoading.value ? 'Please wait...' : 'Continue'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () {
                      final first = controller.firstNameController.value.text.trim();
                      if (first.isEmpty) {
                        return;
                      }
                      Get.to(() => EmailEntryScreen());
                    },
                  )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress({required int step}) {
    return Row(
      children: List.generate(5, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
            decoration: BoxDecoration(
              color: active ? AppThemeData.primary200 : AppThemeData.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
