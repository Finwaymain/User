import 'package:finway/controller/auth_otp_controller.dart';
import 'package:finway/page/auth_screens/mpin_login_screen.dart';
import 'package:finway/page/auth_screens/phone_otp_screen.dart';
import 'package:finway/themes/button_them.dart';
import 'package:finway/themes/constant_colors.dart';
import 'package:finway/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PhoneEntryScreen extends StatefulWidget {
  final String mode;

  const PhoneEntryScreen({super.key, this.mode = 'signup'});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  late final TextEditingController _phoneController;
  late final AuthOtpController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AuthOtpController>()
        ? Get.find<AuthOtpController>()
        : Get.put(AuthOtpController());

    String initialNumber = controller.phone.value.replaceFirst('+91', '').trim();
    if (initialNumber.isEmpty) {
      try {
        initialNumber = controller.phoneController.value.text.trim();
      } catch (_) {}
    }
    _phoneController = TextEditingController(text: initialNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final bool isDark = themeChange.getThem();

    final bgColor = isDark ? AppThemeData.surface50Dark : AppThemeData.surface50;
    final labelColor = isDark ? AppThemeData.grey50Dark : AppThemeData.grey50;
    final hintColor = isDark ? AppThemeData.grey400Dark : AppThemeData.grey400;
    final borderColor = isDark ? AppThemeData.grey200Dark : AppThemeData.grey200;
    final inputBg = isDark ? AppThemeData.grey100Dark : AppThemeData.primary50;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      Text(
                        'Enter mobile number'.tr,
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily: AppThemeData.bold,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We will check if you have an account or create a new one.'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: AppThemeData.regular,
                          color: hintColor,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Phone input container
                      Container(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(right: BorderSide(color: borderColor)),
                              ),
                              child: Row(
                                children: [
                                  const Text('🇮🇳', style: TextStyle(fontSize: 20)),
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
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
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
                      const SizedBox(height: 24),

                      Obx(() => ButtonThem.buildButton(
                            context,
                            txtColor: Colors.white,
                            title: controller.isLoading.value ? 'Checking details...' : 'Continue'.tr,
                            onPress: controller.isLoading.value
                                ? () {}
                                : () async {
                                    final number = _phoneController.text.trim();
                                    if (number.length != 10) {
                                      Get.snackbar('Error', 'Please enter a valid 10-digit mobile number.'.tr);
                                      return;
                                    }
                                    final fullPhone = '+91$number';
                                    controller.phone.value = fullPhone;
                                    try {
                                      controller.phoneController.value.text = number;
                                    } catch (_) {}

                                    // Call check user exists
                                    final exists = await controller.checkUserExists(fullPhone, userCat: 'customer');
                                    if (exists == null) return; // error handled by controller

                                    if (exists) {
                                      // Returning user: go directly to MPIN login screen
                                      Get.to(() => MpinLoginScreen(phone: fullPhone));
                                    } else {
                                      // New user: send phone OTP & navigate to Otp screen
                                      final sent = await controller.sendPhoneOtp(fullPhone, mode: 'signup');
                                      if (sent) {
                                        Get.to(() => const PhoneOtpScreen(mode: 'signup'));
                                      }
                                    }
                                  },
                          )),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
