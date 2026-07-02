import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/auth_screens/mpin_setup_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class PhoneOtpScreen extends StatelessWidget {
  final String mode; // 'signup' or 'reset_mpin'

  const PhoneOtpScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();
    final controller = Get.find<AuthOtpController>();

    final bgTop = AppThemeData.primary200;
    final bgBody = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final subColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;

    return Scaffold(
      backgroundColor: bgTop,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'Verify phone'.tr,
                    style: const TextStyle(
                      fontSize: 26,
                      fontFamily: 'Switzer-Bold',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        'Enter the 4-digit code sent to ${controller.phone.value}'.tr,
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
                          controller: controller.phoneOtpController.value,
                          length: 4,
                          defaultPinTheme: defaultTheme,
                          focusedPinTheme: activeTheme,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          enabled: !controller.isLoading.value,
                        );
                      }),

                      const SizedBox(height: 32),

                      Obx(() => ButtonThem.buildButton(
                            context,
                            title: controller.isLoading.value ? 'Please wait...' : 'Verify'.tr,
                            onPress: controller.isLoading.value
                                ? () {}
                                : () async {
                              final otp = controller.phoneOtpController.value.text.trim();
                              if (otp.length != 4) return;

                              final ok = await controller.verifyPhoneOtp(otp);
                              if (ok) {
                                Get.off(() => MpinSetupScreen(mode: mode, otp: otp));
                              }
                            },
                          )),

                      const SizedBox(height: 24),

                      Obx(() => controller.canResend.value
                          ? GestureDetector(
                              onTap: () async {
                                await controller.sendPhoneOtp(controller.phone.value, mode: 'signup');
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
