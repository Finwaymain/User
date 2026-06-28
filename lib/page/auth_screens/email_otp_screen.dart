// ignore_for_file: must_be_immutable
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/MainDashBoard/screen/main_dashboard.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

/// Step 5 (final signup step) — Verify the 6-digit email OTP
/// and create the account. On success → MainDashboard.
class EmailOtpScreen extends StatelessWidget {
  const EmailOtpScreen({super.key});

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
            // ── Top header ─────────────────────────────────────────────────────
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
                    'Verify your email'.tr,
                    style: const TextStyle(
                      fontSize: 26,
                      fontFamily: 'Switzer-Bold',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                        'We sent a 6-digit code to ${controller.emailController.value.text}'.tr,
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
                      // Progress bar (step 5 of 5)
                      Row(
                        children: List.generate(5, (i) => Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                            decoration: BoxDecoration(
                              color: AppThemeData.primary200,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        )),
                      ),

                      const SizedBox(height: 36),

                      // ── 6-digit Pinput ─────────────────────────────────────
                      Obx(() {
                        final activeTheme = PinTheme(
                          height: 52,
                          width: 48,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontFamily: AppThemeData.bold,
                            color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppThemeData.primary200, width: 2),
                          ),
                        );
                        final defaultTheme = PinTheme(
                          height: 52,
                          width: 48,
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontFamily: AppThemeData.bold,
                            color: isDark ? AppThemeData.grey50Dark : AppThemeData.grey50,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppThemeData.grey100Dark : AppThemeData.primary50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppThemeData.grey200Dark : AppThemeData.grey200,
                            ),
                          ),
                        );
                        return Pinput(
                          controller: controller.emailOtpController.value,
                          length: 6,
                          defaultPinTheme: defaultTheme,
                          focusedPinTheme: activeTheme,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          enabled: !controller.isLoading.value,
                        );
                      }),

                      const SizedBox(height: 36),

                      // ── Create account button ─────────────────────────────
                      Obx(() => ButtonThem.buildButton(
                            context,
                            title: controller.isLoading.value ? 'Please wait...' : 'Create Account'.tr,
                            onPress: controller.isLoading.value
                                ? () {}
                                : () async {
                              final otp   = controller.emailOtpController.value.text.trim();
                              final email = controller.emailController.value.text.trim();
                              final first = controller.firstNameController.value.text.trim();
                              final last  = controller.lastNameController.value.text.trim();

                              if (otp.length != 6) return;

                              final user = await controller.verifyEmailAndRegister(
                                email: email,
                                otp: otp,
                                firstName: first,
                                lastName: last,
                              );

                              if (user != null) {
                                Get.offAll(() => MainDashboard());
                              }
                            },
                          )),

                      const SizedBox(height: 24),

                      // ── Resend OTP ────────────────────────────────────────
                      Obx(() => controller.canResend.value
                          ? GestureDetector(
                              onTap: () => controller.sendEmailOtp(
                                controller.emailController.value.text.trim(),
                              ),
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
