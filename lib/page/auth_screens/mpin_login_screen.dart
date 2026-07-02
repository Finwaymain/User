import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/page/auth_screens/phone_entry_screen.dart';
import 'package:finway/page/auth_screens/phone_otp_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class MpinLoginScreen extends StatefulWidget {
  final String phone;

  const MpinLoginScreen({super.key, required this.phone});

  @override
  State<MpinLoginScreen> createState() => _MpinLoginScreenState();
}

class _MpinLoginScreenState extends State<MpinLoginScreen> {
  final mpinController = TextEditingController();
  final controller = Get.find<AuthOtpController>();

  @override
  void dispose() {
    mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey50;
    final hintColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: labelColor, size: 20),
          onPressed: () => Get.offAll(() => const PhoneEntryScreen(mode: 'signup')),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Enter your MPIN'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify your identity using your 4-digit MPIN for ${widget.phone}.'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.regular,
                  color: hintColor,
                ),
              ),
              const SizedBox(height: 48),

              // PIN Input
              Center(
                child: Pinput(
                  controller: mpinController,
                  length: 4,
                  obscureText: true,
                  obscuringCharacter: '●',
                  defaultPinTheme: PinTheme(
                    height: 56,
                    width: 56,
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontFamily: AppThemeData.bold,
                      color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200,
                      ),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    height: 56,
                    width: 56,
                    textStyle: TextStyle(
                      fontSize: 22,
                      fontFamily: AppThemeData.bold,
                      color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppThemeData.primary200, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ),

              const SizedBox(height: 40),

              Obx(() => ButtonThem.buildButton(
                    context,
                    title: controller.isLoading.value ? 'Please wait...' : 'Verify & Log in'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () async {
                            final mpin = mpinController.text.trim();
                            if (mpin.length != 4) {
                              return;
                            }
                            final user = await controller.loginByMpin(widget.phone, mpin, userCat: 'customer');
                            if (user != null) {
                              Get.offAll(() => MainDashboard());
                            }
                          },
                  )),

              const Spacer(),

              // Forgot MPIN
              Center(
                child: TextButton(
                  onPressed: () async {
                    if (controller.isLoading.value) return;
                    // Trigger phone OTP for resetting MPIN
                    final sent = await controller.sendPhoneOtp(widget.phone, mode: 'login');
                    if (sent) {
                      Get.to(() => const PhoneOtpScreen(mode: 'reset_mpin'));
                    }
                  },
                  child: Text(
                    'Forgot MPIN?'.tr,
                    style: TextStyle(
                      color: AppThemeData.primary200,
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: AppThemeData.primary200,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Change Phone
              Center(
                child: TextButton(
                  onPressed: () => Get.offAll(() => const PhoneEntryScreen(mode: 'signup')),
                  child: Text(
                    'Use a different mobile number'.tr,
                    style: TextStyle(
                      color: hintColor,
                      fontFamily: AppThemeData.regular,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
