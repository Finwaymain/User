import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/page/auth_screens/profile_setup_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

/// Step 2 (signup) or Step 2 (login) — OTP entry.
/// For signup: verifies phone OTP (dummy 1234) → goes to ProfileSetupScreen
/// For login: (mode='login') this screen is reused for email OTP verification
class PhoneOtpScreen extends StatelessWidget {
  final String mode; // 'signup' or 'login'

  const PhoneOtpScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final controller = Get.find<AuthOtpController>();

    final bgTop = AppThemeData.primary200;
    final bgBody = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final subColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;

    final bool isLoginMode = mode == 'login';

    return Scaffold(
      backgroundColor: bgTop,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top (coloured) header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isLoginMode ? 'Check your email'.tr : 'Verify phone'.tr,
                    style: const TextStyle(
                      fontSize: 26,
                      fontFamily: 'Switzer-Bold',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        isLoginMode
                            ? 'OTP sent to ${controller.emailHint.value}'.tr
                            : 'Enter the 4-digit code sent to ${controller.phone.value}'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Switzer-Regular',
                          color: Colors.white70,
                        ),
                      )),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── White card body ────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgBody,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── OTP pinput ─────────────────────────────────────────
                      Obx(() {
                        final activeTheme = PinTheme(
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
                        );
                        final defaultTheme = PinTheme(
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
                        );
                        return Pinput(
                          controller: isLoginMode
                              ? controller.emailOtpController.value
                              : controller.phoneOtpController.value,
                          length: isLoginMode ? 6 : 4,
                          defaultPinTheme: defaultTheme,
                          focusedPinTheme: activeTheme,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          enabled: !controller.isLoading.value,
                        );
                      }),

                      const SizedBox(height: 32),

                      // ── Verify button ──────────────────────────────────────
                      Obx(() => ButtonThem.buildButton(
                            context,
                            title: controller.isLoading.value ? 'Please wait...' : 'Verify'.tr,
                            onPress: controller.isLoading.value
                                ? () {}
                                : () async {
                              final otp = isLoginMode
                                  ? controller.emailOtpController.value.text.trim()
                                  : controller.phoneOtpController.value.text.trim();

                              if (isLoginMode) {
                                if (otp.length != 6) return;
                                final user = await controller.verifyLoginEmailOtp(otp);
                                if (user != null) {
                                  Get.offAll(() => MainDashboard());
                                }
                              } else {
                                if (otp.length != 4) return;
                                final ok = await controller.verifyPhoneOtp(otp);
                                if (ok) {
                                  Get.to(() => ProfileSetupScreen());
                                }
                              }
                            },
                          )),

                      const SizedBox(height: 24),

                      // ── Resend OTP ─────────────────────────────────────────
                      Obx(() => controller.canResend.value
                          ? GestureDetector(
                              onTap: () async {
                                if (isLoginMode) {
                                  await controller.loginByPhone(controller.phone.value);
                                } else {
                                  await controller.sendPhoneOtp(controller.phone.value, mode: 'signup');
                                }
                              },
                              child: Text(
                                'Resend OTP'.tr,
                                style: TextStyle(
                                  color: AppThemeData.primary200,
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppThemeData.primary200,
                                ),
                              ),
                            )
                          : Text(
                              'Resend in ${controller.resendSeconds.value}s'.tr,
                              style: TextStyle(
                                color: subColor,
                                fontFamily: AppThemeData.regular,
                                fontSize: 14,
                              ),
                            )),

                      const SizedBox(height: 16),

                      // ── Wrong number / go back ─────────────────────────────
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Text(
                          'Wrong number?'.tr,
                          style: TextStyle(
                            color: subColor,
                            fontFamily: AppThemeData.regular,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
