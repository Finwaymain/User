// ignore_for_file: must_be_immutable
import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/auth_screens/email_otp_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Step 4 of signup — collect email, trigger email OTP send.
class EmailEntryScreen extends StatelessWidget {
  const EmailEntryScreen({super.key});

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

              _buildProgress(step: 4),
              const SizedBox(height: 28),

              Text(
                'Your email address'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: AppThemeData.bold,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send a one-time code to verify it.'.tr,
                style: TextStyle(fontSize: 14, color: hintColor, fontFamily: AppThemeData.regular),
              ),

              const SizedBox(height: 36),

              // Email input
              TextField(
                controller: controller.emailController.value,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                style: TextStyle(
                  color: labelColor,
                  fontFamily: AppThemeData.medium,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: 'Email address'.tr,
                  labelStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular, fontSize: 14),
                  hintText: 'rahul@example.com',
                  hintStyle: TextStyle(color: hintColor, fontFamily: AppThemeData.regular),
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: hintColor, size: 20),
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
                ),
              ),

              const SizedBox(height: 12),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppThemeData.grey100Dark : AppThemeData.blue200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppThemeData.primary200),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This email will be used to send you ride updates and login OTPs in future.'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppThemeData.grey400Dark : AppThemeData.primary300,
                          fontFamily: AppThemeData.regular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Obx(() => ButtonThem.buildButton(
                    context,
                    title: controller.isLoading.value ? 'Please wait...' : 'Send OTP'.tr,
                    onPress: controller.isLoading.value
                        ? () {}
                        : () async {
                      final email = controller.emailController.value.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        return;
                      }
                      final sent = await controller.sendEmailOtp(email);
                      if (sent) {
                        Get.to(() => EmailOtpScreen());
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
