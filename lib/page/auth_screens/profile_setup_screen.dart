import 'package:finway/constant/show_toast_dialog.dart';
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ProfileSetupScreen extends StatelessWidget {
  final String otp;
  final String mpin;

  const ProfileSetupScreen({super.key, required this.otp, required this.mpin});

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

    InputDecoration inputDecoration(String label, String hint, IconData icon, {bool optional = false}) {
      return InputDecoration(
        labelText: optional ? '$label (Optional)' : label,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Complete your profile'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will be shown on your profile and ride receipts.'.tr,
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
                decoration: inputDecoration('Last name'.tr, 'e.g. Sharma', Icons.person_outline_rounded, optional: true),
              ),

              const SizedBox(height: 16),

              // Referral code (optional)
              TextField(
                controller: controller.referralCodeController.value,
                style: TextStyle(color: labelColor, fontFamily: AppThemeData.medium),
                textCapitalization: TextCapitalization.characters,
                decoration: inputDecoration('Referral code'.tr, 'e.g. ab3f2', Icons.card_giftcard_rounded, optional: true),
              ),

              // Referral tip
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Have a friend\'s referral code? Enter it above to reward them.'.tr,
                  style: TextStyle(fontSize: 12, color: hintColor, fontFamily: AppThemeData.regular),
                ),
              ),

              const SizedBox(height: 48),

              Obx(() => ButtonThem.buildButton(
                    context,
                    title: controller.isLoading.value ? 'Creating account...' : 'Complete Registration'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () async {
                            final first = controller.firstNameController.value.text.trim();
                            final last = controller.lastNameController.value.text.trim();
                            final referral = controller.referralCodeController.value.text.trim();

                            if (first.isEmpty) {
                              ShowToastDialog.showToast('Please enter your first name.'.tr);
                              return;
                            }

                            final user = await controller.registerSimple(
                              phoneNumber: controller.phone.value,
                              otp: otp,
                              mpin: mpin,
                              firstName: first,
                              lastName: last,
                              userCat: 'customer',
                              referralCode: referral,
                            );

                            if (user != null) {
                              Get.offAll(() => MainDashboard());
                            }
                          },
                  )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
