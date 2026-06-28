// ignore_for_file: must_be_immutable
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/auth_screens/login_screen.dart';
import 'package:finway/page/auth_screens/phone_otp_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Step 1 of the new auth flow.
/// Accepts an Indian phone number and routes to OTP verification.
/// [mode] = 'signup' (default) or 'login'
class PhoneEntryScreen extends StatelessWidget {
  final String mode;

  const PhoneEntryScreen({super.key, this.mode = 'signup'});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final controller = Get.put(AuthOtpController());

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey50;
    final hintColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;
    final borderColor = isDark ? AppThemeData.grey200Dark : AppThemeData.grey200;
    final inputBg = isDark ? AppThemeData.grey100Dark : AppThemeData.primary50;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: mode == 'signup'
            ? null
            : IconButton(
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
              const SizedBox(height: 16),

              // Header
              Text(
                mode == 'signup' ? 'Create account'.tr : 'Welcome back'.tr,
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode == 'signup'
                    ? 'Enter your mobile number to get started.'.tr
                    : 'Enter your registered mobile number.'.tr,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: AppThemeData.regular,
                  color: hintColor,
                ),
              ),

              const SizedBox(height: 40),

              // Phone input
              Container(
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    // Country prefix chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          Text('🇮🇳', style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 15,
                              fontFamily: AppThemeData.semiBold,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Number field
                    Expanded(
                      child: TextField(
                        controller: controller.phoneController.value,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: AppThemeData.medium,
                          color: labelColor,
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: TextStyle(
                            color: hintColor,
                            fontFamily: AppThemeData.regular,
                            letterSpacing: 0.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                          counterText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Text(
                '10-digit Indian mobile number'.tr,
                style: TextStyle(fontSize: 12, color: hintColor, fontFamily: AppThemeData.regular),
              ),

              const Spacer(),

              // Continue button
              Obx(() => ButtonThem.buildButton(
                    context,
                    title: controller.isLoading.value ? 'Please wait...' : 'Continue'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () async {
                      final number = controller.phoneController.value.text.trim();
                      if (number.length != 10) {
                        return;
                      }
                      final fullPhone = '+91$number';

                      if (mode == 'signup') {
                        final sent = await controller.sendPhoneOtp(fullPhone, mode: 'signup');
                        if (sent) {
                          Get.to(() => PhoneOtpScreen(mode: mode));
                        }
                      } else {
                        // Login: send email OTP directly
                        final sent = await controller.loginByPhone(fullPhone);
                        if (sent) {
                          Get.to(() => PhoneOtpScreen(mode: 'login'));
                        }
                      }
                    },
                  )),

              const SizedBox(height: 20),

              // Toggle between login and signup
              Center(
                child: Text.rich(
                  TextSpan(
                    text: mode == 'signup' ? 'Already have an account? '.tr : 'Don\'t have an account? '.tr,
                    style: TextStyle(
                      color: hintColor,
                      fontFamily: AppThemeData.regular,
                      fontSize: 14,
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => Get.offAll(() => mode == 'signup'
                              ? PhoneEntryScreen(mode: 'login')
                              : PhoneEntryScreen(mode: 'signup')),
                          child: Text(
                            mode == 'signup' ? 'Log in'.tr : 'Sign up'.tr,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Legacy fallback for existing users without phone
              Center(
                child: GestureDetector(
                  onTap: () => Get.to(() => const LegacyLoginScreen()),
                  child: Text(
                    'Login with email & password'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppThemeData.grey400,
                      fontFamily: AppThemeData.regular,
                      decoration: TextDecoration.underline,
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
